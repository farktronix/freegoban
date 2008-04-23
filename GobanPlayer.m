/*$Id: GobanPlayer.m,v 1.3 2001/10/02 16:13:29 phink Exp $*/

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

#import "GobanPlayer.h"
#import "GobanPreferenceController.h"
#import <GoGame/GoSymbol.h>
#import <GoGame/GoMove.h>
#import <GoGame/GoGame.h>
#import <SenFoundation/SenFoundation.h>

@implementation GobanPlayer

- init
{
    [super init];
    name = @"Anonymous";
    rank = @"15k?";
    isPlaying = NO;
    return self;
}


- (void) dealloc
{
    RELEASE (name);
    RELEASE (rank);
    RELEASE (color);
    RELEASE (game);
    [super dealloc];
}


- (BOOL) isBuiltIn
{
    return NO;
}


+ player
{
    return [[[self alloc] init] autorelease];
}


- (GoSymbol *) color
{
    return color;
}


- (void) setColor:(GoSymbol *) aColor
{
    ASSIGN (color, aColor);
}


- (void) setGame:(GoGame *) aGame
{
    ASSIGN (game, aGame);
}


- (void) setReferee:(id) aReferee
{
    referee = aReferee;
}


- (id) referee
{
    return referee;
}


- (void) didPlayMove:(GoMove *) aMove
{
    [referee player:self didPlayMove:aMove];
}


- (void) opponentDidPlayMove:(GoMove *) aMove
{
}


- (void) didUndo
{
    [referee playerDidUndo:self];
}


- (void) opponentDidUndo
{
}

- (void) didResign
{
    [referee playerDidResign:self];
}


- (void) opponentDidResign
{
}


- (BOOL) isInteractive
{
    return NO;
}


- (BOOL) isPlaying
{
    return isPlaying;
}


- (void) playGame:(GoGame *) aGame withColor:(GoSymbol *) aColor
{
    [self setGame:aGame];
    [self setColor:aColor];
}


- (void) finishGame
{
}


- (NSSound *) soundForMove:(GoMove *) aMove
{
    return nil;
}


- (void) makeSoundForMove:(GoMove *) aMove
{
    NSSound *sound = [self soundForMove:aMove];
    if (sound != nil) {
        [sound play];
    }
}


- (void) signalAtari
{
}


- (NSString *) name
{
    return name;
}


- (void) setName:(NSString *) aName
{
    ASSIGN (name, aName);
}


- (NSString *) rank
{
    return rank;
}


- (void) setRank:(NSString *) aRank
{
    ASSIGN (rank, aRank);
}


- (NSString *) kindAsString
{
    return @"Player?";
}


- (id) copyWithZone:(NSZone *) zone
{
    GobanPlayer *other = NSCopyObject (self, 0, zone);
    other->name = [name copy];
    other->rank = [rank copy];
    return other;
}


- (NSArray *) savedValueKeys
{
    return [NSArray arrayWithObjects:@"name", @"rank", nil];
}
@end
