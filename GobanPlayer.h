/*$Id: GobanPlayer.h,v 1.3 2001/10/02 16:13:29 phink Exp $*/

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

#import <AppKit/AppKit.h>

@class GoGame;
@class GoSymbol;
@class GoMove;

@class GobanPlayer;

@interface NSObject (GobanReferee)
- (void) player:(GobanPlayer *) aPlayer didPlayMove:(GoMove *) aMove;
- (void) playerDidUndo:(GobanPlayer *) aPlayer;
- (void) playerDidResign:(GobanPlayer *) aPlayer;
@end


@interface GobanPlayer : NSObject
{
    NSString *name;
    NSString *rank;
    id referee;
    GoSymbol *color;
    GoGame *game;
    BOOL isPlaying;
}


+ player;

- (GoSymbol *) color;

- (void) setReferee:(id) aReferee;
- (id) referee;

- (void) didPlayMove:(GoMove *) aMove;
- (void) opponentDidPlayMove:(GoMove *) aMove;

- (void) didUndo;
- (void) opponentDidUndo;

- (void) didResign;
- (void) opponentDidResign;

- (BOOL) isInteractive;
- (BOOL) isPlaying;
- (BOOL) isBuiltIn;

- (void) playGame:(GoGame *) aGame withColor:(GoSymbol *) aColor;
- (void) finishGame;

- (NSSound *) soundForMove:(GoMove *) aMove;
- (void) makeSoundForMove:(GoMove *) aMove;

- (void) signalAtari;

- (NSString *) name;
- (void) setName:(NSString *) aName;

- (NSString *) rank;
- (void) setRank:(NSString *) aRank;

- (NSString *) kindAsString;

- (id) copyWithZone:(NSZone *) zone;
- (NSArray *) savedValueKeys;
@end
