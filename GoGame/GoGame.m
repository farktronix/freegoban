/*$Id: GoGame.m,v 1.8 2001/10/15 17:24:07 phink Exp $*/

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

#import "GoGame.h"
#import "GoRuleSet.h"
#import "GoPosition.h"
#import "GoSymbol.h"
#import "GoMove.h"
#import "GoPoint.h"
#import "GoGameNode.h"
#import "GoMove.h"
#import "GoGameTree.h"
#import <SenFoundation/SenFoundation.h>

NSString *GoGameRulesDidChange = @"GoGameRulesDidChange";
NSString *GoGamePositionDidChange = @"GoGamePositionDidChange";
NSString *GoGameScoreDidChange = @"GoGameScoreDidChange";

@interface GoGame (Private)
- (void) _gotoNextMove;
- (void) _gotoPreviousMove;
- (void) setRuleSet:(GoRuleSet *) value;
- (void) placeColor:(GoSymbol *) aColor atPoint:(GoPoint *) aPoint;
@end


@implementation GoGame
+ (void) initialize
{
    NSString *path = [[NSBundle bundleForClass:self] pathForResource:@"GoGameDefaults" ofType:@"plist"];
    NSDictionary *defaultDictionary = [NSDictionary dictionaryWithContentsOfFile:path];
    if (defaultDictionary != nil) {
        [[NSUserDefaults standardUserDefaults] registerDefaults:defaultDictionary];
    }
}


+ (float) defaultKomi
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults floatForKey:@"Go.Komi"];
}


+ (void) setDefaultKomi:(float) aValue
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setFloat:aValue forKey:@"Go.Komi"];    
}


+ (int) defaultHandicap
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults integerForKey:@"Go.Handicap"];
}


+ (void) setDefaultHandicap:(int) aValue
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:aValue forKey:@"Go.Handicap"];        
}


+ (int) defaultBoardSize
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults integerForKey:@"Go.BoardSize"];
}


+ (void) setDefaultBoardSize:(int) aValue
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:aValue forKey:@"Go.BoardSize"];    
}


+ (NSString *) defaultRuleSet
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:@"Go.RuleSet"];
}


- (NSArray *) starPoints
{
    NSMutableArray *starPoints = [NSMutableArray arrayWithCapacity:9];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSEnumerator *pointEnumerator = [[[defaults dictionaryForKey:@"Go.StarPoints"] objectForInt:boardSize] objectEnumerator];
    id each;
    while (each = [pointEnumerator nextObject]) {
        [starPoints addObject:[GoPoint pointWithIntPoint:IntPointFromString(each) boardSize:boardSize]];
    }
    return starPoints;
}


- (NSString *) scoreString
{
    if (isResigned) {
        return ([self nextColor] == [GoSymbol black]) ? @"W+R" : @"B+R";
    }
    else {
        GoPosition *position = [self scorePosition];
        float whiteScore = [position whiteScore];
        float blackScore = [position blackScore];
    
        if (whiteScore > blackScore) {
            return [NSString stringWithFormat:@"W+%.1f", whiteScore - blackScore];
        }
        else if (whiteScore < blackScore) {
            return [NSString stringWithFormat:@"B+%.1f", blackScore - whiteScore];
        }
        else {
            return @"0";
        }
    }
    return @"?";
}


- (void) scoreChanged
{
    [gameTree setStringValue:[self scoreString] forKey:@"RE"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"GoGameScoreDidChange" object:self];
}


- (void) positionChanged
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"GoGamePositionDidChange" object:self];
}


- (void) rulesChanged
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"GoGameRulesDidChange" object:self];
}


- (void) _placeHandicapStoneAtPoint:(GoPoint *) aPoint
{
    placedHandicapCount++;
    [[self currentPosition] placeColor:[GoSymbol black] atPoint:aPoint];
}


- (void) placeHandicapStoneAtPoint:(GoPoint *) aPoint
{
    [self _placeHandicapStoneAtPoint:aPoint];
    [self rulesChanged];
}


- (NSArray *) fixedHandicapStones
{
    NSArray *handicapStones = [gameTree pointValuesForKey:@"AB"];
    if ([handicapStones count] != [self handicap]) {
        handicapStones = [[self ruleSet] fixedHandicapPoints:handicap forBoardSize:boardSize];
    }
    return handicapStones;
}


- (void) placeFixedHandicapStones
{    
    NSEnumerator *handicapEnumerator = [[self fixedHandicapStones] objectEnumerator];
    id each;
    placedHandicapCount = 0;
    while (each = [handicapEnumerator nextObject]) {
        [self _placeHandicapStoneAtPoint:each];
    }
}


- (BOOL) hasFixedHandicapStones
{
    return ([[self ruleSet] isHandicapFixed] && ([self handicap] >= 2));
}


- (void) setupInitialPosition
{
    GoPosition *initialPosition = [[[GoPosition alloc] initForGame:self] autorelease];
    [positions removeAllObjects];
    [positions addObject:initialPosition];
    placedHandicapCount = 0;
    if ([self hasFixedHandicapStones]) {
        [self placeFixedHandicapStones];
    }
}


- (void) loadGame
{
    while (![self isAtLastMove]) {
        [self _gotoNextMove];
        [currentLineOfPlay addObject:currentMove];
    }
    [self positionChanged];
}


- initWithKomi:(float) aKomi handicap:(int) aHandicap boardSize:(int)aBoardSize ruleSet:aRuleSet
{
    [super init];
    isOver = NO;
    isResigned = NO;
    positions = [[NSMutableArray alloc] init];
    currentLineOfPlay = [[NSMutableArray alloc] init];
    komi = aKomi;
    handicap = aHandicap;
    boardSize = MAX (MIN_BOARD_SIZE, aBoardSize);
    ASSIGN (ruleSet, aRuleSet);
    [self setupInitialPosition];
    return self;
}


- init
{
    gameTree = [[GoGameTree alloc] initWithGame:self];
    [gameTree setStringValue:@"4" forKey:@"FF"];
    [self initWithKomi:[[self class] defaultKomi]
               handicap:[[self class] defaultHandicap]
              boardSize:[[self class] defaultBoardSize]
                  ruleSet:[GoRuleSet rulesNamed:[[self class] defaultRuleSet]]];
    isStarted = NO;
    isSetupRegistered = NO;
    return self;
}


- initWithContentsOfFile:(NSString *) filename
{
    NSString *rules = nil;
    float komiProperty = 0.0;
    int handicapProperty = 0;
    int boardSizeProperty = MAX_BOARD_SIZE;

    gameTree = [[GoGameTree alloc] initWithGame:self contentsOfFile:filename];

    komiProperty = [gameTree floatValueForKey:@"KM"];
    handicapProperty = [gameTree intValueForKey:@"HA"];
    boardSizeProperty = [gameTree intValueForKey:@"SZ"];
    if (boardSizeProperty == 0) {
        boardSizeProperty = 19;
    }
    
    rules = [gameTree stringValueForKey:@"RU"];
    [self initWithKomi:komiProperty
              handicap:handicapProperty
             boardSize:boardSizeProperty
               ruleSet:[GoRuleSet rulesNamed:(rules != nil) ? rules : @""]];
    isStarted = YES;
    isSetupRegistered = YES;
    [self loadGame];
    return self;
}


- (void) dealloc
{
    RELEASE (positions);
    RELEASE (currentLineOfPlay);
    RELEASE (gameTree);
    [super dealloc];
}


- (void) timestamp
{
    [gameTree setDateValue:[NSCalendarDate date] forKey:@"DT"];
}


- (void) setGameTypeProperty
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [gameTree setIntValue:[defaults integerForKey:@"SGF.GameType"] forKey:@"GM"];
}


- (void) setUserProperty
{
    [gameTree setStringValue:NSFullUserName() forKey:@"US"];
}


- (void) setApplicationProperty:(NSString *) aName
{
    [gameTree setStringValue:aName forKey:@"AP"];
}


- (NSString *) blackPlayerName
{
    NSString *name = [gameTree stringValueForKey:@"PB"];
    return !isNilOrEmpty(name) ? name : @"Black";
}


- (void) setBlackPlayerName:(NSString *) aName
{
    [gameTree setStringValue:aName forKey:@"PB"];
}


- (NSString *) whitePlayerName
{
    NSString *name = [gameTree stringValueForKey:@"PW"];
    return !isNilOrEmpty(name) ? name : @"White";
}


- (void) setWhitePlayerName:(NSString *) aName
{
    [gameTree setStringValue:aName forKey:@"PW"];
}


- (void) setRulesProperties
{
    if (!isSetupRegistered) {
        isSetupRegistered = YES;
        [gameTree setIntValue:boardSize forKey:@"SZ"];
        [gameTree setFloatValue:komi forKey:@"KM"];
        [gameTree setIntValue:handicap forKey:@"HA"];
        [gameTree setStringValue:[ruleSet name] forKey:@"RU"];
        
        if ([self hasFixedHandicapStones]) {
            NSArray *handicapStones = [[self ruleSet] fixedHandicapPoints:handicap forBoardSize:boardSize];
            NSEnumerator *handicapEnumerator = [handicapStones objectEnumerator];
            id each;
            while (each = [handicapEnumerator nextObject]) {
                [gameTree addPointValue:each forKey:@"AB"];
            }
        }
    }
}


- (BOOL) writeToFile:(NSString *) path atomically:(BOOL) useAuxiliaryFile
{
    [self setRulesProperties];
    [self timestamp];
    [self setGameTypeProperty];
    [self setUserProperty];
    return [gameTree writeToFile:path];
}


- (float) komi
{
    return komi;
}


- (void) setKomi:(float) value
{
    komi = value;
    if (komi > 0.5) {
        handicap = 0;
        [self setupInitialPosition];
    }
    [self rulesChanged];
}


- (int) handicap
{
    return handicap;
}


- (void) setHandicap:(int) value
{
    handicap = value;
    if (handicap >= 2) {
        komi = 0.5;
    }
    [self setupInitialPosition];
    [self rulesChanged];
}


- (int) boardSize
{
    return boardSize;
}


- (void) setBoardSize:(int) value
{
    boardSize = MAX (MIN_BOARD_SIZE, value);
    [self setupInitialPosition];
    [self rulesChanged];
}



- (GoPoint *) pointWithIntPoint:(IntPoint) p
{
    if ((p.x < 0) || (p.y < 0) || (p.x >= boardSize) || (p.y >= boardSize)) {
        return nil;
    } 
    return [GoPoint pointWithIntPoint:p boardSize:boardSize];
}


- (GoPoint *) pointWithSGFPoint:(IntPoint) p
{
    if ((p.x < 0) || (p.y < 0) || (p.x >= boardSize) || (p.y >= boardSize)) {
        return nil;
    } 
    return [GoPoint pointWithSGFPoint:p boardSize:boardSize];
}


- (GoRuleSet *) ruleSet
{
    return ruleSet;
}


- (void) setRuleSet:(GoRuleSet *) value
{
    ASSIGN (ruleSet, value);
    [self rulesChanged];
}


- (GoPosition *) currentPosition
{
    return [positions lastObject];
}


- (GoGameNode *) currentNode
{
    return (currentMove != nil) ? (id)currentMove : (id)gameTree;
}


- (void) placeColor:(GoSymbol *) aColor atPoint:(GoPoint *) aPoint
{
    [[self currentPosition] placeColor:aColor atPoint:aPoint];
}


- (void) unplayMove:(GoMove *) aMove
{
    if (![aMove isPass]) {
        [positions removeLastObject];
    }    
}


- (void) replayMove:(GoMove *) aMove
{
    if (aMove != nil) {
        if (![aMove isPass]) {
            GoPosition *newPosition = [[self currentPosition] positionAfterPlayingMove:aMove];
            [positions addObject:newPosition];
        }
    }
}


- (void) unregisterMove:(GoMove *) aMove
{
    GoGameNode *parent = [aMove parent];
    ASSIGN (currentMove, [parent isMove] ? parent : nil);
    [[self currentNode] removeChildren];
    [currentLineOfPlay removeObject:aMove];
}


- (void) registerMove:(GoMove *) aMove
{
    if ([self isOver] && [aMove isPass] && [currentMove isPass]) {
        [self unregisterMove:currentMove];
    }
    else {
        [[self currentNode] addFirstChild:aMove];
        ASSIGN (currentMove, aMove);
        [currentLineOfPlay addObject:aMove];
    }
}


- (void) start
{
    isStarted = YES;
}


- (void) resign
{
    isResigned = YES;
    [self finish];
    [self scoreChanged];
}


- (void) playMove:(GoMove *) aMove
{
    //senassert ([self exceptionForMove:aMove] == nil);
    if (![self isStarted]) {
        [self start];
    }
    if (![aMove isPass]) {
        GoPosition *newPosition = [[self currentPosition] positionAfterPlayingMove:aMove];
        [positions addObject:newPosition];
        isOver = NO;
        isResigned = NO;
    }
    else if ([currentMove isPass]) {
        [self finish];
    }
    [self registerMove:aMove];
    [self positionChanged];
}


- (BOOL) isAtLastMove
{
    return [[self currentNode] isLastMove];
}


- (BOOL) isBeforeFirstMove
{
    return currentMove == nil;
}


- (void) _gotoNextMove
{
    if (![self isAtLastMove]) {
        ASSIGN (currentMove, [[self currentNode] nextMove]);
        [self replayMove:currentMove];
    }
}


- (void) gotoNextMove
{
    [self _gotoNextMove];
    [self positionChanged];
}


- (void) _gotoPreviousMove
{
    if (![self isBeforeFirstMove]) {
        [self unplayMove:currentMove];
        ASSIGN (currentMove, [[self currentNode] previousMove]);
    }
}


- (void) gotoPreviousMove
{
    [self _gotoPreviousMove];
    [self positionChanged];
}


- (void) undoPreviousMove
{
    if (![self isBeforeFirstMove]) {
        [self unplayMove:currentMove];
        [self unregisterMove:currentMove];
        [self positionChanged];
    }
}


- (void) gotoStart
{
    while (![self isBeforeFirstMove]) {
        [self _gotoPreviousMove];
    }
    [self positionChanged];
}


- (void) gotoEnd
{
    while (![self isAtLastMove]) {
        [self _gotoNextMove];
    }
    [self positionChanged];
}


- (void) _goFromIndex:(unsigned) fromIndex toIndex:(unsigned) toIndex
{
    if (fromIndex > toIndex) {
        while (fromIndex > toIndex) {
            [self _gotoPreviousMove];
            fromIndex--;
        }
    }
    else {
        while (fromIndex < toIndex) {
            [self _gotoNextMove];
            fromIndex++;
        }
    }
}


- (void) gotoMoveAtIndex:(unsigned) anIndex
{
    int moveCount = [currentLineOfPlay count];
    int currentPosition = [currentLineOfPlay indexOfObject:currentMove];
    if (currentPosition != NSNotFound) {
        senassert ((moveCount > 0) && (anIndex >= 0) && (anIndex < moveCount));
        if (currentPosition != anIndex) {
            [self _goFromIndex:currentPosition toIndex:anIndex];
        }
        [self positionChanged];
    }
}


- (GoMove *) currentMove
{
    return currentMove;
}


- (GoSymbol *) nextColor
{
    if (((![self isBeforeFirstMove]) && ([currentMove color] == [GoSymbol black])) ||
        ([self isBeforeFirstMove] && (handicap > 0))) {
        return [GoSymbol white];
    }
    return [GoSymbol black];
}


- (NSException *) exceptionForMove:(GoMove *) aMove
{
    if (![self isReady]) {
        return [[self ruleSet] gameNotReadyException];
    }
    else if ([self isOver]) {
        return [[self ruleSet] gameOverException];
    }
    return [[self currentPosition] exceptionForMove:aMove];
}


- (BOOL) isReady
{
    return (placedHandicapCount == handicap);
}


- (BOOL) isStarted
{
    return isStarted;
}


- (BOOL) isOver
{
    return isOver;
}


- (void) resumePlay
{
    isOver = NO;
}


- (BOOL) isResigned
{
    return isResigned;
}


- (BOOL) isAtari
{
    return [[self currentPosition] isAtari];
}


- (void) finish
{
    isOver = YES;
    // record result;
}


- (void) toggleIsAliveAtPoint:(GoPoint *) aPoint
{
    senassert (isOver)
    [[self currentPosition] toggleIsAliveAtPoint:aPoint];
    [self scoreChanged];
}


- (void) setDeadAtPoint:(GoPoint *) aPoint
{
    senassert (isOver)
    [[self currentPosition] setDeadAtPoint:aPoint];
    [self scoreChanged];
}


- (GoPosition *) scorePosition
{
    return [[self currentPosition] scoredPosition];   
}


- (BOOL) isScoring
{
    return isScoring;
}


- (void) setScoring:(BOOL) flag
{
    isScoring = flag;
    [self scoreChanged];
}



- (NSArray *) currentLineOfPlay
{
    return currentLineOfPlay;
}
@end


@implementation GoGame (MoveFactory)
- moveForColor:(GoSymbol *) aColor atPoint:(GoPoint *) aPoint
{
    return [GoMove moveWithGame:self color:aColor atPoint:aPoint];
}


- moveForColor:(GoSymbol *) aColor x:(int)x y:(int) y
{
    return [self moveForColor:aColor atPoint:[self pointWithIntPoint:MakeIntPoint (x, y)]];
}


- passMoveForColor:(GoSymbol *) aColor
{
    return [GoMove passMoveWithGame:self color:aColor];
}
@end
