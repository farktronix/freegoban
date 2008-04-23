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

#import "GobanGnuGoPlayer.h"
#import <GoGame/GoGame.h>
#import <GoGame/GoPosition.h>
#import <GoGame/GoSymbol.h>
#import <GoGame/GoMove.h>
#import <GoGame/GoPoint.h>
#import <SenFoundation/SenFoundation.h>

#define SCORING_TIMEOUT 30.0

@implementation GobanGnuGoPlayer

- (NSString *) launchPath
{
    return [[NSBundle mainBundle] pathForResource:@"gnugo" ofType:nil];
}


- (BOOL) isBuiltIn
{
    return YES;
}


- (void) setLevel:(int) aLevel
{
    level = aLevel;
}


- (int) level
{
    return level;
}


- (id) copyWithZone:(NSZone *) zone
{
    GobanGnuGoPlayer *other = [super copyWithZone:zone];
    other->level = level;
    return other;
}


- (void) setupGameParameters
{
    [super setupGameParameters];
    [self sendCommand:[NSString stringWithFormat:@"level %d", level]];
}


#if 0
// Is it better than genmove_black/_white? Should be given a seed to introduce randomness in generated moves.
- (void) playMoveFromString:(NSString *) aString
{
    GoMove *move = nil;
    if ([[aString uppercaseString] isEqualToString:@"PASS"]) {
        move = [game passMoveForColor:color];
    }
    else {
        int col = [[aString uppercaseString] characterAtIndex:0];
        int row = [[aString substringFromIndex:1] intValue] - 1;        
        col = (col < 'I') ? col - 'A' : col - 'A' - 1;
        move = [game moveForColor:color x:col y:row];
        //SEN_DEBUG (([NSString stringWithFormat:@"%@", [move description]]));
    }
    [self sendCommand:[move gtpRepresentation]];
    [self didPlayMove:move];
}


- (void) generateMove
{
    if (![game isOver]) {
        [self sendCommand: (color == [GoSymbol black]) ? @"gg_genmove black" : @"gg_genmove white" 
            inBackground:YES 
            responseAction:@selector(playMoveFromString:)];
    }
}
#endif


- (BOOL) isScoring
{
    return isScoring && (task != nil) && [task isRunning];
}


- (void) cancelIfStillScoring:(id) object
{
    if ([self isScoring]) {
        [task terminate];
        RELEASE (task);
        [game setScoring:NO];
        isScoring = NO;
    }
}


- (void) score
{
    [self launchTask];
    isScoring = YES;
    [self setupGameParameters];
    [self replayGame];
    [self performSelector:@selector(cancelIfStillScoring:) withObject:self afterDelay:SCORING_TIMEOUT];
    [game setScoring:YES];
    [self sendCommand:@"final_status_list dead 2" inBackground:YES responseAction:@selector(scoreGameFromString:)];
}


- (void) scoreGameFromString:(NSString *) aString
{
    if (!isNilOrEmpty (aString)) {
        NSEnumerator *chainEnumerator = [[aString componentsSeparatedByString:@"\n"] objectEnumerator];
        id eachChain;
        while (eachChain = [chainEnumerator nextObject]) {
            NSString *stoneString = [[eachChain componentsSeparatedByString:@" "] lastObject];
            int col = [[stoneString uppercaseString] characterAtIndex:0];
            int row = [[stoneString substringFromIndex:1] intValue] - 1;        
            col = (col < 'I') ? col - 'A' : col - 'A' - 1;
            [game setDeadAtPoint:[GoPoint x:col y:row boardSize:[game boardSize]]];
        }
        [self cancelIfStillScoring:nil];
    }
}


- (void) scoreGame:(GoGame *) aGame
{
    ASSIGN (game, aGame);
    [self score];
}


- (NSString *) kindAsString
{
    return @"Program (Built-in)";
}


- (NSArray *) savedValueKeys
{
    NSMutableArray *array = [NSMutableArray arrayWithArray:[super savedValueKeys]];
    [array addObject:@"level"];
    [array removeObject:@"launchPath"];
    return array;
}
@end
