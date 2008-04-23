/*$Id: GoPosition.h,v 1.5 2001/10/15 17:24:08 phink Exp $*/

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

#import <Foundation/Foundation.h>
#import "GoGeometry.h"
#import "GoSymbol.h"

// tmp
typedef GoSymbol * boardType [MAX_BOARD_SIZE][MAX_BOARD_SIZE];
//

@class GoSymbol;
@class GoGame;
@class GoMove;
@class GoPoint;

@interface GoPosition : NSObject
{
    GoGame *game;
    boardType board;
    int boardSize;
    IntPoint koPoint;
    BOOL isAtari;
    IntRectangle bounds;
    unsigned blackCapturedCount;
    unsigned whiteCapturedCount;
    unsigned blackPrisonerCount;
    unsigned whitePrisonerCount;
    unsigned blackTerritoryCount;
    unsigned whiteTerritoryCount;

    GoPosition *scorePosition;
}


- initForGame:(GoGame *) aGame;

- (NSException *) exceptionForMove:(GoMove *) aMove;
- (GoPosition *) positionAfterPlayingMove:(GoMove *) aMove;

- (void) placeColor:(GoSymbol *) aColor atPoint:(GoPoint *) aPoint;
- (GoPosition *) positionAfterPlacingColor:(GoSymbol *) aColor atPoint:(GoPoint *) aPoint;
- (GoSymbol *) symbolAtPoint:(GoPoint *) point;

- (BOOL) isAtari;

- (unsigned) blackCapturedCount;
- (unsigned) whiteCapturedCount;

- (unsigned) blackPrisonerCount;
- (unsigned) whitePrisonerCount;

- (unsigned) blackTerritoryCount;
- (unsigned) whiteTerritoryCount;

- (unsigned) boardSize;
- (NSEnumerator *) pointEnumerator;
@end

@interface GoPosition (Scoring)
- (GoPosition *) scoredPosition;
- (void) toggleIsAliveAtPoint:(GoPoint *) aPoint;
- (void) setDeadAtPoint:(GoPoint *) aPoint;

- (float) whiteScore;
- (float) blackScore;

@end

