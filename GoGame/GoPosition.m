/*$Id: GoPosition.m,v 1.6 2001/10/15 17:24:08 phink Exp $*/

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

#import "GoPosition.h"
#import "GoSymbol.h"
#import "GoGame.h"
#import "GoMove.h"
#import "GoPoint.h"
#import "GoRuleSet.h"
#import "GoPositionPointEnumerator.h"
#import <SenFoundation/SenFoundation.h>

static GoSymbol *black = nil;
static GoSymbol *white = nil;
static GoSymbol *dame = nil;
static GoSymbol *whiteTerritory = nil;
static GoSymbol *blackTerritory = nil;
static GoSymbol *blackPrisoner = nil;
static GoSymbol *whitePrisoner = nil;

static IntPoint IllegalPoint = (IntPoint) {SenIllegalCoordinate, SenIllegalCoordinate};

#define OTHER_COLOR(color)   ((color == black) ? (white) : (black))
#define AT(b,p)              (b[p.x][p.y])


typedef BOOL boolBoardType [MAX_BOARD_SIZE][MAX_BOARD_SIZE];

@interface GoPosition (Private)
@end


@implementation GoPosition

+ (void) initialize
{
    white = [[GoSymbol white] retain];
    black = [[GoSymbol black] retain];
    whiteTerritory = [[GoSymbol whiteTerritory] retain];
    blackTerritory = [[GoSymbol blackTerritory] retain];
    blackPrisoner = [[GoSymbol blackPrisoner] retain];
    whitePrisoner = [[GoSymbol whitePrisoner] retain];
    dame = [[GoSymbol neutralTerritory] retain];
}


- initForGame:(GoGame *) aGame;
{
    [super init];
    game = [aGame retain];
    koPoint = IllegalPoint;
    isAtari = NO;
    boardSize = [game boardSize];
    bounds = MakeIntRectangle (0, boardSize, 0, boardSize);
    return self;
}


- (void) dealloc
{
    RELEASE (game);
    RELEASE (scorePosition);
    [super dealloc];
}


- (BOOL) isKoPoint:(IntPoint) p
{
    return EqualIntPoints (p, koPoint);
}


- (BOOL) isAtari
{
    return isAtari;
}


- (IntPoint) koPoint
{
    return koPoint;
}


- copyWithZone:(NSZone *) zone
{
    GoPosition *duplicate = [[[self class] alloc] initForGame:game];
    bcopy(self->board, duplicate->board, sizeof (self->board));
    duplicate->blackCapturedCount = self->blackCapturedCount;
    duplicate->whiteCapturedCount = self->whiteCapturedCount;
    duplicate->blackPrisonerCount = self->blackPrisonerCount;
    duplicate->whitePrisonerCount = self->whitePrisonerCount;
    duplicate->blackTerritoryCount = self->blackTerritoryCount;
    duplicate->whiteTerritoryCount = self->whiteTerritoryCount;
    duplicate->koPoint = self->koPoint;
    return duplicate;
}


- (NSArray *) libertiesForColor:(GoSymbol *) color atPoint:(IntPoint) point maxCount:(int) maxCount isCaptureRemoved:(BOOL) isCaptureRemoved
{

    boolBoardType visitedBoard;
    NSMutableArray *toBeVisitedQueue = [NSMutableArray arrayWithObject:[game pointWithIntPoint:point]];
    NSMutableArray *liberties = [NSMutableArray array];
    int libertyCount = 0;

    bzero (visitedBoard, sizeof(visitedBoard));
    AT(visitedBoard, point) = YES;
    
    while (![toBeVisitedQueue isEmpty]) {
        GoPoint *currentPoint = [toBeVisitedQueue objectAtIndex:0];
        NSEnumerator *neighborEnumerator = [currentPoint neighborEnumerator];
        id each;

        [toBeVisitedQueue removeObjectAtIndex:0];

        while (each = [neighborEnumerator nextObject]) {
            IntPoint neighbor = [each intPointValue];
            if (!AT(visitedBoard, neighbor)) {
                if (AT (board, neighbor) == nil) {
                    AT(visitedBoard, neighbor) = YES;
                    [liberties addObject:each];
                    ++libertyCount;
                    if (libertyCount == maxCount) {
                        return liberties;
                    }
                }
                else if (AT (board, neighbor) == color) {
                    AT(visitedBoard, neighbor) = YES;
                    [toBeVisitedQueue addObject:each];
                }
            }
        }
    }

    if (isCaptureRemoved && (libertyCount == 0)) {
        int i, j;
        for (i = 0; i < boardSize; i++) {
            for (j = 0; j < boardSize; j++) {
                if (visitedBoard[i][j]) {
                    if (board[i][j] == black) {
                        blackCapturedCount++;
                    }
                    else {
                        whiteCapturedCount++;
                    }
                    board[i][j] = nil;
                }
            }
        }
    }
    return liberties;
}


- (BOOL) isStone:(GoSymbol *) color livingAtPoint:(IntPoint) point
{
    return ![[self libertiesForColor:color atPoint:point maxCount:1 isCaptureRemoved:NO] isEmpty];
}


- (void) updatePossibleKoByMove:(GoMove *) aMove
{
    NSEnumerator *neighborEnumerator = [[aMove point] neighborEnumerator];
    id each;
    int friendCount = 0;
    int libertyCount = 0;
    IntPoint liberty;

    while (each = [neighborEnumerator nextObject]) {
        IntPoint neighbor = [each intPointValue];
        if (AT(board, neighbor) == [aMove color]) {
            friendCount++;
        }
        else if (AT(board, neighbor) == nil) {
            libertyCount++;
            liberty = neighbor;
        }
    }
    if (libertyCount == 1 && friendCount == 0) {
        koPoint = liberty;
    }
}


- (void) checkForAtariByMove:(GoMove *) aMove
{
    NSEnumerator *neighborEnumerator = [[aMove point] neighborEnumerator];
    id each;

    isAtari = NO;
    while (each = [neighborEnumerator nextObject]) {
        IntPoint neighbor = [each intPointValue];
        if (AT(board, neighbor) == OTHER_COLOR([aMove color])) {
            if ([[self libertiesForColor:OTHER_COLOR([aMove color]) atPoint:neighbor maxCount:2 isCaptureRemoved:NO] count] == 1) {
                isAtari = YES;
                return;
            }
        }
    }
}


- (void) removeCapturesByMove:(GoMove *) aMove
{
    GoSymbol *color = [aMove color];
    GoSymbol *otherColor = OTHER_COLOR (color);

    NSEnumerator *neighborEnumerator = [[aMove point] neighborEnumerator];
    id each;

    int newlyCaptured = -((otherColor == white) ? whiteCapturedCount : blackCapturedCount);

    while (each = [neighborEnumerator nextObject]) {
        IntPoint neighbor = [each intPointValue];
        if (AT(board, neighbor) == otherColor) {
            (void) [self libertiesForColor:otherColor atPoint:neighbor maxCount:-1 isCaptureRemoved:YES];
        }
    }

    newlyCaptured += ((otherColor == white) ? whiteCapturedCount : blackCapturedCount);

    if (newlyCaptured == 1) {
        [self updatePossibleKoByMove:aMove];
    }

    if ([[game ruleSet] isSuicideAllowed]) {
        (void) [self libertiesForColor:color atPoint:[[aMove point] intPointValue] maxCount:-1 isCaptureRemoved:YES];
    }
}


- (void) placeColor:(GoSymbol *) aColor atPoint:(GoPoint *) aPoint
{
    IntPoint p = [aPoint intPointValue];
    board[p.x][p.y] = aColor;
}


- (GoPosition *) positionAfterPlacingColor:(GoSymbol *) aColor atPoint:(GoPoint *) aPoint
{
    GoPosition *resultingPosition = [self copy];
    IntPoint p = [aPoint intPointValue];
    resultingPosition->board[p.x][p.y] = aColor;
    resultingPosition->koPoint = IllegalPoint;
    return [resultingPosition autorelease];
}


- (GoPosition *) positionAfterPlayingMove:(GoMove *) aMove
{
    GoPosition *resultingPosition = [self copy];
    IntPoint p = [[aMove point] intPointValue];
    resultingPosition->board[p.x][p.y] = [aMove color];
    resultingPosition->koPoint = IllegalPoint;
    [resultingPosition checkForAtariByMove:aMove];
    [resultingPosition removeCapturesByMove:aMove];
    return [resultingPosition autorelease];
}


- (NSException *) exceptionForMove:(GoMove *) aMove
{
    GoRuleSet *ruleSet = [game ruleSet];
    IntPoint p = [[aMove point] intPointValue];

    if ([aMove isPass]) {
        return [ruleSet isPassingAllowed] ? nil : [ruleSet illegalPassMove];
    }
    
    senassert (IntPointInRectangle (p, bounds));
    if (board[p.x][p.y] != nil) {
        return [ruleSet illegalOccupiedPointException];
    }

    if ([self isKoPoint:p]) {
        GoSymbol *moveColor = [aMove color];
        GoSymbol *koColor = (p.x > 0) ? board[p.x - 1][p.y] : board[p.x + 1][p.y];
        if (koColor != moveColor) {
            return [ruleSet illegalKoMoveException];
        }
    }

    if (![ruleSet isSuicideAllowed]) {
        GoPosition *simulated = [self positionAfterPlayingMove:aMove];
        if (![simulated isStone:[aMove color] livingAtPoint:p]) {
            return [ruleSet illegalSuicideException];
        }
    }
    return nil;

}


- (BOOL) isLegalMove:(GoMove *) aMove;
{
    return [self exceptionForMove:aMove] == nil;
}


- (GoSymbol *) symbolAtPoint:(GoPoint *) point
{
    IntPoint iPoint = [point intPointValue];
    return board[iPoint.x][iPoint.y];
}


- (unsigned) blackCapturedCount
{
    return blackCapturedCount;
}


- (unsigned) whiteCapturedCount
{
    return whiteCapturedCount;
}

- (unsigned) blackPrisonerCount
{
    return blackPrisonerCount;
}


- (unsigned) whitePrisonerCount
{
    return whitePrisonerCount;
}

- (unsigned) blackTerritoryCount
{
    return blackTerritoryCount;
}


- (unsigned) whiteTerritoryCount
{
    return whiteTerritoryCount;
}


- (unsigned) boardSize
{
    return boardSize;
}

- (NSEnumerator *) pointEnumerator
{
    return [GoPositionPointEnumerator enumeratorWithPosition:self];
}


- (void) toggleIsAliveAtPoint:(GoPoint *) aPoint
{
    IntPoint p = [aPoint intPointValue];
    int i, j;

    if (scorePosition->board[p.x][p.y] != nil) {
        GoSymbol *fromSymbol = scorePosition->board[p.x][p.y];
        GoSymbol *toSymbol;
        boolBoardType visitedBoard;
        NSMutableArray *toBeVisitedQueue = [NSMutableArray arrayWithObject:[game pointWithIntPoint:p]];

        if (fromSymbol == black) {
            toSymbol = blackPrisoner;
        }
        else if (fromSymbol == blackPrisoner) {
            toSymbol = black;
        }
        else if (fromSymbol == white) {
            toSymbol = whitePrisoner;
        }
        else {
            toSymbol = white;
        }

        bzero (visitedBoard, sizeof(visitedBoard));
        visitedBoard [p.x][p.y] = YES;

        while (![toBeVisitedQueue isEmpty]) {
            GoPoint *currentPoint = [toBeVisitedQueue objectAtIndex:0];
            NSEnumerator *neighborEnumerator = [currentPoint neighborEnumerator];
            id each;

            [toBeVisitedQueue removeObjectAtIndex:0];

            while (each = [neighborEnumerator nextObject]) {
                IntPoint neighbor = [each intPointValue];
                if (!AT(visitedBoard, neighbor)) {
                    if (AT (scorePosition->board, neighbor) == fromSymbol) {
                        AT(visitedBoard, neighbor) = YES;
                        [toBeVisitedQueue addObject:each];
                    }
                }
            }
        }

        for (i = 0; i < boardSize; i++) {
            for (j = 0; j < boardSize; j++) {
                if (visitedBoard[i][j]) {
                    scorePosition->board[i][j] = toSymbol;
                }
            }
        }
    }
}


- (void) setDeadAtPoint:(GoPoint *) aPoint
{
    IntPoint p = [aPoint intPointValue];
    GoSymbol *fromSymbol = scorePosition->board[p.x][p.y];
    if ((fromSymbol == black) || (fromSymbol == white)) {
        [self toggleIsAliveAtPoint:aPoint];
    }
}


- (GoPosition *) scorePosition
{
    if (scorePosition == nil) {
        scorePosition = [self copy];
    }
    return scorePosition;
}


- (GoPosition *) scoredPosition
{
    GoPosition *scoredPosition = [[[self scorePosition] copy] autorelease];
    int i, j;

    for (i = 0; i < boardSize; i++) {
        for (j = 0; j < boardSize; j++) {
            if (scoredPosition->board[i][j] == nil)  {
                IntPoint point = MakeIntPoint (i, j);
                boolBoardType visitedBoard;
                NSMutableArray *toBeVisitedQueue = [NSMutableArray arrayWithObject:[game pointWithIntPoint:point]];
                BOOL hasWhiteBorder = NO;
                BOOL hasBlackBorder = NO;

                int k, l;
                bzero (visitedBoard, sizeof(visitedBoard));
                visitedBoard [point.x][point.y] = YES;

                while (![toBeVisitedQueue isEmpty]) {
                    GoPoint *currentPoint = [toBeVisitedQueue objectAtIndex:0];
                    NSEnumerator *neighborEnumerator = [currentPoint neighborEnumerator];
                    id each;

                    [toBeVisitedQueue removeObjectAtIndex:0];

                    while (each = [neighborEnumerator nextObject]) {
                        IntPoint neighbor = [each intPointValue];
                        GoSymbol *scoreSymbol = AT (scoredPosition->board, neighbor);
                        if (!AT(visitedBoard, neighbor)) {
                            AT(visitedBoard, neighbor) = YES;
                            if (scoreSymbol == black) {
                                hasBlackBorder = YES;
                            }
                            else if (scoreSymbol == white) {
                                hasWhiteBorder = YES;
                            }
                            else {
                                [toBeVisitedQueue addObject:each];
                            }
                        }
                    }
                }

                for (k = 0; k < boardSize; k++) {
                    for (l = 0; l < boardSize; l++) {
                        if (visitedBoard[k][l]) {
                            if (scoredPosition->board[k][l] == whitePrisoner) {
                                scoredPosition->blackTerritoryCount++;
                                scoredPosition->whitePrisonerCount++;
                            }
                            else if (scoredPosition->board[k][l] == blackPrisoner) {
                                scoredPosition->whiteTerritoryCount++;
                                scoredPosition->blackPrisonerCount++;
                            }
                            else {
                                if (scoredPosition->board[k][l] == nil) {
                                    if (hasBlackBorder && !hasWhiteBorder) {
                                        scoredPosition->blackTerritoryCount++;
                                        scoredPosition->board[k][l] = blackTerritory;
                                    }
                                    else if (hasWhiteBorder && !hasBlackBorder) {
                                        scoredPosition->whiteTerritoryCount++;
                                        scoredPosition->board[k][l] = whiteTerritory;
                                    }
                                    else {
                                        scoredPosition->board[k][l] = dame;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return scoredPosition;
}


- (float) whiteScore
{
    return [game komi] + whiteTerritoryCount + blackPrisonerCount + blackCapturedCount;
}


- (float) blackScore
{
    return blackTerritoryCount + whitePrisonerCount + whiteCapturedCount;
}
@end
