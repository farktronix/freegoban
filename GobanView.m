/*$Id: GobanView.m,v 1.5 2001/10/02 16:16:23 phink Exp $*/

// This is Goban, a Go program for Mac OS X.  Contact goban@sente.ch, 
// or see http://www.sente.ch/software/goban for more information.    
//
// Copyright (c) 1997-2001, Sen:te (Sente SA).  All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License 
// as published by the Free Software Foundation - version 2.   
//                                                             
// This program is distributed in the hope that it will be     
// useful, but WITHOUT ANY WARRANTY; without even the implied  
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR     
// PURPOSE.  See the GNU General Public License in file COPYING
// for more details.                                           
//                                                             
// You should have received a copy of the GNU General Public   
// License along with this program; if not, write to the Free  
// Software Foundation, Inc., 59 Temple Place - Suite 330,     
// Boston, MA 02111, USA.                                      

#import "GobanView.h"
#import "GobanGoke.h"
#import "GobanCell.h"
#import <GoGame/GoPosition.h>
#import <GoGame/GoSymbol.h>
#import <GoGame/GoGeometry.h>
#import <GoGame/GoMove.h>
#import <GoGame/GoGame.h>
#import <GoGame/GoPoint.h>
#import "GobanMatrix.h"
#import <SenFoundation/SenFoundation.h>

#define DEFAULT_CELL_WIDTH 32.0
#define GOBAN_ELONGATION    1.1
#define HALF_PIXEL          0.5
#define VIEW_MARGIN         4.0
#define ORIGIN_X            (VIEW_MARGIN / 2)
#define ORIGIN_Y            (VIEW_MARGIN / 2)
#define GOBAN_EDGE_COUNT    4


#define IS_VERTICAL_COORDINATE(x) ((x == NSMinXEdge) || (x == NSMaxXEdge))

@interface NSView (GobanViewExtensions)
- (void) center;
@end


@implementation NSView (GobanViewExtensions)
- (void) center
{
    NSPoint origin = NSMakePoint (floor(([[self superview] frame].size.width - [self frame].size.width) / 2.0),
                                  floor(([[self superview] frame].size.height - [self frame].size.height) / 2.0));
    [self setFrameOrigin:origin];
}
@end


@implementation GobanView

- (NSSize) labelSize
{
    return NSMakeSize (25, 17);
}


- (NSSize) labelSpace
{
    return [self isShowingLabels] ? [self labelSize] : NSMakeSize (0, 0);
}


- (NSSize) defaultCellSize
{
    return NSMakeSize (DEFAULT_CELL_WIDTH, DEFAULT_CELL_WIDTH * GOBAN_ELONGATION);
}


- (void) dealloc
{
    RELEASE (labelViews);
    [super dealloc];
}


- (void) setupLabelViews
{
    int i;
    labelViews = [[NSMutableArray alloc] initWithCapacity:GOBAN_EDGE_COUNT];
    for (i = 0; i < GOBAN_EDGE_COUNT; i++) {
        NSMatrix *labelMatrix = [[[NSMatrix alloc] initWithFrame:NSMakeRect (0, 0, 14, 14)
            mode:NSListModeMatrix
            cellClass:[NSTextFieldCell class]
            numberOfRows:0
            numberOfColumns:0] autorelease];
        [labelMatrix setCellSize:[self labelSize]];
        [labelViews addObject:labelMatrix];
    }
}


- (NSSize) cellSize
{
    return cellSize;
}


- (int) stoneSize
{
    return cellSize.width + 1;
}


- (NSSize) relativePerturbationForCell:(GobanCell *) aCell
{
    return NSMakeSize ([aCell perturbation].x / [self defaultCellSize].width, [aCell perturbation].y / [self defaultCellSize].height);
}


- (BOOL) isUsingFullArea
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"IsUsingFullArea"];
}


- (int) maxBoardSize
{
    return [self isUsingFullArea] ? [game boardSize] : 19;
}

#define JAPANESE_STYLE 1

- (NSArray *) horizontalLabels
{
    int labelingStyle = [[NSUserDefaults standardUserDefaults] integerForKey:@"LabelingStyle"];
    if (labelingStyle == JAPANESE_STYLE) {
        return [[NSUserDefaults standardUserDefaults] objectForKey:@"ArabicLabels"];
    }
    else {
        return [[NSUserDefaults standardUserDefaults] objectForKey:@"RomanLabels"];
    }
}


- (NSArray *) verticalLabels
{
    int labelingStyle = [[NSUserDefaults standardUserDefaults] integerForKey:@"LabelingStyle"];
    if (labelingStyle == JAPANESE_STYLE) {
        return [[NSUserDefaults standardUserDefaults] objectForKey:@"ShortKanjiLabels"];
    }
    else {
        return [[NSUserDefaults standardUserDefaults] objectForKey:@"ArabicLabels"];
    }
}


- (void) renewLabelViews
{
    int k;
    int boardSize = [game boardSize];
    NSArray *verticalLabels = [self verticalLabels];
    NSArray *horizontalLabels = [self horizontalLabels];
    for (k = 0; k < GOBAN_EDGE_COUNT; k++) {
        NSMatrix *labelMatrix = [labelViews objectAtIndex:k];
        int i;
        [labelMatrix renewRows:IS_VERTICAL_COORDINATE(k) ? boardSize : 1 columns:IS_VERTICAL_COORDINATE(k) ? 1 : boardSize];

        for (i = 0; i < boardSize; i++) {
            if (IS_VERTICAL_COORDINATE(k)) {
                id cell = [labelMatrix cellAtRow:boardSize - i - 1 column:0];
                [cell setAlignment:NSRightTextAlignment];
                [cell setStringValue:[verticalLabels objectAtIndex:i]];
            }
            else {
                id cell = [labelMatrix cellAtRow:0 column:i];
                [cell setAlignment:NSCenterTextAlignment];
                [cell setStringValue:[horizontalLabels objectAtIndex:i]];
            }
        }
        [labelMatrix setAllowsEmptySelection:YES];
        [labelMatrix deselectAllCells];
    }
}


- (void) adjustLabelViews
{
    int n = [game boardSize];
    NSRect referenceFrame = [self frame];
    NSSize labelSize =  [self labelSize];
    NSSize labelViewSize = NSMakeSize ((n - 1) * cellSize.width + labelSize.width,
                                        (n - 1) * cellSize.height + labelSize.height);
    NSSize intercellSize = NSMakeSize ((labelViewSize.width - n * labelSize.width) / (n - 1),
                                       (labelViewSize.height - n * labelSize.height) / (n - 1));
                                                                              
    [[labelViews objectAtIndex:NSMinXEdge] setIntercellSpacing:intercellSize];
    [[labelViews objectAtIndex:NSMinXEdge] setFrame: NSMakeRect (
        NSMinX(referenceFrame) + cellSize.width / 2 - labelSize.width, 
        NSMinY(referenceFrame) + (NSHeight(referenceFrame) - labelViewSize.height) / 2, 
        labelSize.width, 
        labelViewSize.height)];
        
    [[labelViews objectAtIndex:NSMaxXEdge] setIntercellSpacing:intercellSize];
    [[labelViews objectAtIndex:NSMaxXEdge] setFrame: NSMakeRect (
        NSMaxX(referenceFrame) - cellSize.width / 2, 
        NSMinY(referenceFrame) + (NSHeight(referenceFrame) - labelViewSize.height) / 2, 
        labelSize.width, 
        labelViewSize.height)];
    
    [[labelViews objectAtIndex:NSMinYEdge] setIntercellSpacing:intercellSize];
    [[labelViews objectAtIndex:NSMinYEdge] setFrame: NSMakeRect (
        NSMinX(referenceFrame) + (NSWidth(referenceFrame) - labelViewSize.width) / 2, 
        NSMinY(referenceFrame) + cellSize.height / 2 - labelSize.height, 
        labelViewSize.width, 
        labelSize.height)];
        
    [[labelViews objectAtIndex:NSMaxYEdge] setIntercellSpacing:intercellSize];
    [[labelViews objectAtIndex:NSMaxYEdge] setFrame: NSMakeRect (
        NSMinX(referenceFrame) + (NSWidth(referenceFrame) - labelViewSize.width) / 2, 
        NSMaxY(referenceFrame) - cellSize.height / 2, 
        labelViewSize.width, 
        labelSize.height)];
}


- (void) adjustFrames
{
    NSSize matrixSize = NSMakeSize ([game boardSize] * cellSize.width, [game boardSize] * cellSize.height);
    NSSize gridSize = NSMakeSize (([game boardSize]) * cellSize.width + VIEW_MARGIN, ([game boardSize]) * cellSize.height + VIEW_MARGIN);

    [self setFrameSize:gridSize];
    [matrix setFrameSize:matrixSize];

    [self center];
    [matrix center];
    [self adjustLabelViews];
}


- (NSSize) cellSizeForViewSize:(NSSize) viewSize
{
    int maxBoardSize = [self maxBoardSize];
    float width = floor ((viewSize.width - VIEW_MARGIN - [self labelSpace].width) / maxBoardSize);
    float height = floor (width * GOBAN_ELONGATION);
    if (height * maxBoardSize > viewSize.height) {
        height = floor ((viewSize.height - VIEW_MARGIN - [self labelSpace].height) / maxBoardSize);
        width = floor (height / GOBAN_ELONGATION);
    }
    return NSMakeSize (width, height);
}


- (void) adjustCellSize
{
    cellSize = [self cellSizeForViewSize:[[[self window] contentView] frame].size];
}


- (void) setFrame:(NSRect) frameRect
{
    [super setFrame:frameRect];
    [self adjustCellSize];
    [self adjustFrames];
    [self update];
}


- (NSSize) windowWillResizeToSize:(NSSize) proposedSize
{
    int maxBoardSize = [self maxBoardSize];
    NSSize possibleCellSize = [self cellSizeForViewSize:proposedSize];
    return NSMakeSize (possibleCellSize.width * maxBoardSize, possibleCellSize.height * maxBoardSize);
}


- (void) awakeFromNib
{
    cellSize = [self defaultCellSize];
    [self setupLabelViews];
    if ([self isShowingLabels]) {
        [self showLabels];
    }
}


- (void) setGame:(GoGame *) aGame
{
    ASSIGN (game, aGame);
    if ([self isUsingFullArea]) {
        [self adjustCellSize];
    }
    [matrix setBoardSize:[game boardSize]];
    [self renewLabelViews];
    [self adjustFrames];
}


- (void)  highlightLastMove
{
    if (![game isOver]) {
        GoMove *lastMove = [game currentMove];
        if ((lastMove != nil) && ![lastMove isPass]) {
            GobanCell *cell = [matrix cellAtPoint:[lastMove point]];
            NSColor *color = ([lastMove color] == [GoSymbol black]) ? [NSColor whiteColor] : [NSColor blackColor];
            int stoneSize = [self stoneSize];
            NSSize side = NSMakeSize (floor(stoneSize / 2), floor(stoneSize / 2));
            NSPoint origin = NSMakePoint (
                ORIGIN_X /*+ HALF_PIXEL */ +1 + floor ((stoneSize - side.width) / 2 + ([[lastMove point] x] + [self relativePerturbationForCell:cell].width) * cellSize.width),
                ORIGIN_Y /* + HALF_PIXEL */ +1  + floor ((stoneSize - side.width) / 2 + ([[lastMove point] y] + [self relativePerturbationForCell:cell].height) * cellSize.height));
            NSRect highlighFrame = {origin, side};
            [color set];
            NSFrameRectWithWidth (highlighFrame, 0.75);
        }
    }
}


- (void) drawStones
{
    GoPosition *position = [game isOver] && [self isShowingTerritory] ? [game scorePosition] : [game currentPosition];

    NSEnumerator *pointEnumerator = [position pointEnumerator];
    id each;

    while (each = [pointEnumerator nextObject]) {
        GobanCell *cell = [matrix cellAtPoint:each];
        GoSymbol *stone = [position symbolAtPoint:each];
        if (stone != nil) {
            NSImage *image = [stone imageOfSize:[self stoneSize] style:[cell style]];
            NSSize perturbation = [stone isTerritory] ? NSMakeSize (0, 0) : [self relativePerturbationForCell:cell];
            [image compositeToPoint:NSMakePoint(ORIGIN_X + ([each x] + perturbation.width) * cellSize.width , 
                                                ORIGIN_Y + ([each y] + perturbation.height) * cellSize.height)
                          operation:NSCompositeSourceOver];

        }
    }
}


- (void) drawStars
{
    NSBezierPath *star = [NSBezierPath bezierPath];
    NSEnumerator *starPointEnumerator = [[game starPoints] objectEnumerator];
    id each;
    float radius = MAX (3.0, floor (cellSize.width / 10.0));
    NSPoint origin = NSMakePoint (ORIGIN_X + HALF_PIXEL + cellSize.width / 2  - radius, ORIGIN_Y + HALF_PIXEL + cellSize.height / 2 - radius);

    while (each = [starPointEnumerator nextObject]) {
        [star appendBezierPathWithOvalInRect:
            NSMakeRect (origin.x + [each x] * cellSize.width ,
                        origin.y + [each y] * cellSize.height,
                        2.0 * radius,
                        2.0 * radius)];
    }
    [[NSColor blackColor] set];
    [star fill];
}


- (void) drawGrid
{
    int count = [game boardSize];
    NSBezierPath *grid = [NSBezierPath bezierPath];
    float lineWidth = 1.0 + (floor (cellSize.width / 50.0));
    NSPoint origin = NSMakePoint (
        ORIGIN_X + HALF_PIXEL + floor (cellSize.width / 2), 
        ORIGIN_Y + HALF_PIXEL + floor (cellSize.height / 2));
    NSPoint maximum = NSMakePoint (
        origin.x + (count - 1) * cellSize.width, 
        origin.y + (count - 1) * cellSize.height);

    [grid setLineWidth:lineWidth];
    
    while (count--) {
        float x = origin.x + count * cellSize.width;
        float y = origin.y + count * cellSize.height;
        [grid moveToPoint:NSMakePoint (origin.x, y)];
        [grid lineToPoint:NSMakePoint (maximum.x, y)];

        [grid moveToPoint:NSMakePoint (x, origin.y)];
        [grid lineToPoint:NSMakePoint (x, maximum.y)];
    }
    
    [[NSColor blackColor] set];
    [grid stroke];
}


- (void) drawRect:(NSRect) aRect
{
    [[NSColor blackColor] set];
    [self drawGrid];
    [self drawStars];
    [self drawStones];
    [self highlightLastMove];     
}


- (BOOL) isShowingTerritory
{
    return isShowingTerritory;
}


- (void) showTerritory
{
    isShowingTerritory = YES;
}


- (void) hideTerritory
{
    isShowingTerritory = NO;
}


- (void) update
{
    [[self superview] setNeedsDisplay:YES];
}


- (GoPoint *) selectedPoint
{
    return [matrix selectedPoint];
}


- (BOOL) isShowingLabels
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"IsShowingLabels"];
}


- (void) showLabels
{
    NSEnumerator *coordinateViewEnumerator = [labelViews objectEnumerator];
    id eachView;
    
    while (eachView = [coordinateViewEnumerator nextObject]) {
        [[self superview] addSubview:eachView positioned:NSWindowBelow relativeTo:self];
    }
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"IsShowingLabels"];
    if ([self isUsingFullArea]) {
        [self adjustCellSize];
    }
    [self renewLabelViews];
    [self adjustFrames];
}


- (void) hideLabels
{
    NSEnumerator *coordinateViewEnumerator = [labelViews objectEnumerator];
    id eachView;
    
    while (eachView = [coordinateViewEnumerator nextObject]) {
        [eachView removeFromSuperview];
    }
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"IsShowingLabels"];
    if ([self isUsingFullArea]) {
        [self adjustCellSize];
    }
    [self renewLabelViews];
    [self adjustFrames];
}
@end
