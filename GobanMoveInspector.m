/*$Id: GobanMoveInspector.m,v 1.5 2001/10/04 16:13:54 phink Exp $*/

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

#import "GobanMoveInspector.h"
#import "GobanGameDocument.h"
#import <GoGame/GoGame.h>
#import <GoGame/GoSymbol.h>
#import <GoGame/GoMove.h>
#import <GoGame/GoPoint.h>
#import <SenFoundation/SenFoundation.h>

@interface GoGameNode (HumanRepresentation)
- (NSString *) humanRepresentation;
@end

#define JAPANESE_STYLE 1


@implementation GoMove (HumanRepresentation)
- (NSArray *) xLabels
{
    int labelingStyle = [[NSUserDefaults standardUserDefaults] integerForKey:@"LabelingStyle"];
    if (labelingStyle == JAPANESE_STYLE) {
        return [[NSUserDefaults standardUserDefaults] objectForKey:@"ArabicLabels"];
    }
    else {
        return [[NSUserDefaults standardUserDefaults] objectForKey:@"RomanLabels"];
    }
}


- (NSArray *) yLabels
{
    int labelingStyle = [[NSUserDefaults standardUserDefaults] integerForKey:@"LabelingStyle"];
    if (labelingStyle == JAPANESE_STYLE) {
        return [[NSUserDefaults standardUserDefaults] objectForKey:@"KanjiLabels"];
    }
    else {
        return [[NSUserDefaults standardUserDefaults] objectForKey:@"ArabicLabels"];
    }
}


- (NSString *) humanRepresentation
{
    if ([self isPass]) {
        return NSLocalizedString(@"pass", @"");
    }
    else {
        int labelingStyle = [[NSUserDefaults standardUserDefaults] integerForKey:@"LabelingStyle"];
        if (labelingStyle == JAPANESE_STYLE) {
            return [NSString stringWithFormat:@"%@%@", 
                [[[NSUserDefaults standardUserDefaults] objectForKey:@"KanjiLabels"] objectAtIndex:[[self point] y]], 
                [[[NSUserDefaults standardUserDefaults] objectForKey:@"ArabicLabels"] objectAtIndex:[[self point] x]]];
        }
        else {
            return [NSString stringWithFormat:@"%@%@", 
                [[[NSUserDefaults standardUserDefaults] objectForKey:@"RomanLabels"] objectAtIndex:[[self point] x]], 
                [[[NSUserDefaults standardUserDefaults] objectForKey:@"ArabicLabels"] objectAtIndex:[[self point] y]]];
        }
    }
}
@end


@implementation GobanMoveInspector
- (void) setEmpty
{
}


- (void) redisplay
{
    GoGame *game = [inspectedDocument game];
    NSString *comments = [[game currentMove] comments];
    int index = [[game currentLineOfPlay] indexOfObject:[game currentMove]];
    [outlineView reloadData];
    if (index != NSNotFound) {
        [outlineView selectRow:index byExtendingSelection:NO];
        [outlineView scrollRowToVisible:index];
    }
    if (!isNilOrEmpty (comments)) {
        [commentView setString:comments];
    }
    else {
        [commentView setString:@""];
    }
}


- (void) setInspected:(GobanGameDocument *) aGobanDocument
{
    if (inspectedDocument != aGobanDocument) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        ASSIGN (inspectedDocument, aGobanDocument);
        if (inspectedDocument != nil) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gameDidChange:) name:nil object:[inspectedDocument game]];
            [self redisplay];
        }
        else {
            [self setEmpty];
        }
    }
}


// textDidChange never called
- (BOOL) textView:(NSTextView *) aTextView shouldChangeTextInRange:(NSRange) affectedCharRange replacementString:(NSString *) replacementString
{
    [[[inspectedDocument game] currentMove] setComments:[aTextView string]];
    return YES;
}


- (void) gameDidChange:(NSNotification *) aNotification
{
    [self redisplay];
}


- (BOOL) outlineView:(NSOutlineView *) anOutlineView isItemExpandable:(id) anItem
{
    return NO;
}


- (int) outlineView:(NSOutlineView *) anOutlineView numberOfChildrenOfItem:(id) anItem
{
    return (anItem == nil) ? [[[inspectedDocument game] currentLineOfPlay] count] : 0;
}


- (id) outlineView:(NSOutlineView *) anOutlineView child:(int)index ofItem:(id) anItem
{
    return (anItem == nil) ? [[[inspectedDocument game] currentLineOfPlay] objectAtIndex:index] : nil;
}


- (id) outlineView:(NSOutlineView *) anOutlineView objectValueForTableColumn:(NSTableColumn *) tableColumn byItem:(id) anItem
{
    if ([[tableColumn identifier] isEqualToString:@"Number"]) {
        return [NSString stringWithFormat:@"%d", 1 + [anOutlineView rowForItem:anItem]];
    }
    else if ([[tableColumn identifier] isEqualToString:@"Description"]) {
        return [anItem humanRepresentation];
    }
    return nil;
}


- (void) outlineView:(NSOutlineView *) anOutlineView willDisplayCell:(id) cell forTableColumn:(NSTableColumn *) tableColumn item:(id) anItem
{
    GoMove *move = (GoMove *) anItem;
    if ([move color] == [GoSymbol black]) {
        [cell setBackgroundColor:[NSColor colorWithCalibratedWhite:0.9 alpha:1.0]];
        [cell setDrawsBackground:YES];
    }
    else {
        [cell setBackgroundColor:[NSColor whiteColor]];
    }
}


- (IBAction) selectMove:(id) sender
{
    int selectedRow = [sender selectedRow];
    if (selectedRow >= 0) {
        GoGame *game = [inspectedDocument game];
        [game gotoMoveAtIndex:selectedRow];
    }
}


#ifdef NEVER_CALLED
- (void) outlineViewSelectionDidChange:(NSNotification *)notification
//- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    int selectedRow = [outlineView selectedRow];
    SEN_TRACE;
    if (selectedRow >= 0) {
        GoGame *game = [inspectedDocument game];
        [game gotoMoveAtIndex:selectedRow];
    }
}
#endif
@end
