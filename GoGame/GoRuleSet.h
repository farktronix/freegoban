/*$Id: GoRuleSet.h,v 1.4 2001/10/15 17:24:08 phink Exp $*/

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

@class GoPosition;
@class GoGame;

extern NSString *IllegalMoveException;

@interface GoRuleSet : NSObject
{
}

+ rulesNamed:(NSString *) aName;

- (BOOL) isSuicideAllowed;
- (BOOL) isSuperKoAllowed;
- (BOOL) isPassingAllowed;
- (BOOL) isHandicapFixed;

- (NSString *) name;

- (NSException *) illegalSuicideException;
- (NSException *) illegalKoMoveException;
- (NSException *) illegalOccupiedPointException;
- (NSException *) illegalPassMove;

- (NSException *) gameOverException;
- (NSException *) gameNotReadyException;
- (NSException *) badTurnException;

- (NSArray *) fixedHandicapPoints:(unsigned) count forBoardSize:(int) aBoardSize;

@end
