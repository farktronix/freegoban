/*$Id: GoGame.h,v 1.8 2001/10/15 17:24:07 phink Exp $*/

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

@class GoRuleSet;
@class GoPosition;
@class GoSymbol;
@class GoGameNode;
@class GoMove;
@class GoGameTree;
@class GoPoint;

extern NSString *GoGameRulesDidChange;
extern NSString *GoGamePositionDidChange;
extern NSString *GoGameScoreDidChange;

@interface GoGame : NSObject
{
    @private
    float komi;
    int handicap;
    int boardSize;
    GoRuleSet *ruleSet;
    NSMutableArray *positions;
    int placedHandicapCount;
    BOOL isSetupRegistered;
    BOOL isStarted;
    BOOL isOver;
    BOOL isResigned;
    BOOL isScoring;
    
    GoGameTree *gameTree;
    GoMove *currentMove;
    NSMutableArray *currentLineOfPlay;
}

+ (float) defaultKomi;
+ (void) setDefaultKomi:(float) aValue;

+ (int) defaultHandicap;
+ (void) setDefaultHandicap:(int) aValue;

+ (int) defaultBoardSize;
+ (void) setDefaultBoardSize:(int) aValue;

+ (NSString *) defaultRuleSet;

- (void) setApplicationProperty:(NSString *) aName;

- (NSString *) blackPlayerName;
- (void) setBlackPlayerName:(NSString *) aName;

- (NSString *) whitePlayerName;
- (void) setWhitePlayerName:(NSString *) aName;

- initWithContentsOfFile:(NSString *) filename;
- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile;

- (float) komi;
- (void) setKomi:(float) value;

- (int) handicap;
- (void) setHandicap:(int) value;

- (int) boardSize;
- (void) setBoardSize:(int) value;

- (NSArray *) starPoints;

//- (GoPoint *) x:(int) x y:(int) y;
- (GoPoint *) pointWithIntPoint:(IntPoint) p;
- (GoPoint *) pointWithSGFPoint:(IntPoint) p;

- (GoRuleSet *) ruleSet;

- (GoPosition *) currentPosition;

- (void) playMove:(GoMove *) aMove;
- (void) undoPreviousMove;

- (void) gotoNextMove;
- (void) gotoPreviousMove;
- (void) gotoStart;
- (void) gotoEnd;
- (void) gotoMoveAtIndex:(unsigned) anIndex;

- (GoMove *) currentMove;
- (GoSymbol *) nextColor;

- (NSException *) exceptionForMove:(GoMove *) aMove;
   
- (BOOL) isStarted;
- (BOOL) isOver;
- (BOOL) isReady;
- (BOOL) isResigned;
- (BOOL) isScoring;
- (void) setScoring:(BOOL) flag;
- (BOOL) isAtLastMove;
- (BOOL) isAtari;

- (void) resumePlay;
- (void) resign;
- (void) finish;

- (void) placeHandicapStoneAtPoint:(GoPoint *) aPoint;
- (void) toggleIsAliveAtPoint:(GoPoint *) aPoint;
- (void) setDeadAtPoint:(GoPoint *) aPoint;

- (GoPosition *) scorePosition;

- (NSArray *) currentLineOfPlay;

- (void) scoreChanged;
- (NSString *) scoreString;

- (void) rulesChanged;
@end


@interface GoGame (MoveFactory)
- moveForColor:(GoSymbol *) aColor atPoint:(GoPoint *) aPoint;
- moveForColor:(GoSymbol *) aColor x:(int)x y:(int) y;
- passMoveForColor:(GoSymbol *) aColor;
@end

