/*$Id: GoRuleSet.m,v 1.4 2001/10/15 17:24:08 phink Exp $*/

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

#import "GoRuleSet.h"
#import "GoGeometry.h"
#import "GoPoint.h"
#import <SenFoundation/SenFoundation.h>

@implementation GoRuleSet

NSString *IllegalMoveException = @"GoIllegalMoveException";

+ rulesNamed:(NSString *) aName
{
    static GoRuleSet *ruleSet = nil;
    if (ruleSet == nil) {
        ruleSet = [[self alloc] init];
    }
    return ruleSet;
}


- (BOOL) isSuicideAllowed
{
    return NO;
}


- (BOOL) isSuperKoAllowed
{
    return YES;
}


- (BOOL) isPassingAllowed
{
    return YES;
}


- (BOOL) isHandicapFixed
{
    return YES;
}


- (NSString *) name
{
    return @"Japanese";
}


- (NSException *) illegalSuicideException
{
    return [NSException exceptionWithName:IllegalMoveException reason:@"Suicide" userInfo:nil];
}


- (NSException *) illegalKoMoveException
{
    return [NSException exceptionWithName:IllegalMoveException reason:@"Ko: you must play elsewhere before you can play here." userInfo:nil];
}


- (NSException *) illegalOccupiedPointException
{
    return [NSException exceptionWithName:IllegalMoveException reason:@"You cannot play on occupied points." userInfo:nil];
}

- (NSException *) illegalPassMove
{
    return nil;
}


- (NSException *) gameOverException
{
    return [NSException exceptionWithName:IllegalMoveException reason:@"Game is over. Are you disputing the score?" userInfo:nil];
}


- (NSException *) gameNotReadyException
{
    return [NSException exceptionWithName:IllegalMoveException reason:@"Game is not ready" userInfo:nil];    
}


- (NSException *) badTurnException
{
    return [NSException exceptionWithName:IllegalMoveException reason:@"Not your turn to play" userInfo:nil];
}



- (NSArray *) fixedHandicapPoints:(unsigned) count forBoardSize:(int) aBoardSize
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *handicapPointsBySize = [[defaults dictionaryForKey:@"Go.JapaneseRuleSet.HandicapPoints"] objectForInt:aBoardSize];
    NSString *handicapKey = [[NSNumber numberWithInt:count] stringValue];
    NSEnumerator *handicapPointDescriptionEnumerator = [[handicapPointsBySize objectForKey:handicapKey] objectEnumerator];
    id each;
    
    NSMutableArray *handicapPoints = [NSMutableArray array];
    while (each = [handicapPointDescriptionEnumerator nextObject]) {
        [handicapPoints addObject:[GoPoint pointWithIntPoint:IntPointFromString(each) boardSize:aBoardSize]];
    }
    return handicapPoints;
}

@end
