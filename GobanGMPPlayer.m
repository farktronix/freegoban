/*$Id: GobanGMPPlayer.m,v 1.3 2001/10/02 16:13:28 phink Exp $*/

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

#import "GobanGMPPlayer.h"
#import <GoGame/GoGame.h>
#import <GoGame/GoPosition.h>
#import <GoGame/GoGeometry.h>
#import <GoGame/GoSymbol.h>
#import <GoGame/GoMove.h>
#import <GoGame/GoPoint.h>
#import <SenFoundation/SenFoundation.h>
#import <gmp.h>

// Warning: The GMP code (taken from gnugo) is a bit strange:
// - x and y are inverted, (used in contradiction with header definition)
// - y is flipped.

@implementation GobanGMPPlayer

- (void) setupTask
{
    NSPipe *stdoutPipe = [NSPipe pipe];
    NSPipe *stdinPipe = [NSPipe pipe];
    task = [[NSTask alloc] init];
    [task setLaunchPath:[self launchPath]];
    [task setArguments:[self launchArguments]];
    [task setStandardOutput:stdoutPipe];
    [task setStandardInput:stdinPipe];
}


- (void) setup
{
    const char *error;
    GmpResult message;
    [self setupTask];
    [task launch];
    gmpEngine = gmp_create ([[[task standardOutput] fileHandleForReading] fileDescriptor], [[[task standardInput] fileHandleForWriting] fileDescriptor]);
    SEN_DEBUG (@"gmp_create");

    //if (color != [GoSymbol black]) {
        do  {
            message = gmp_check(gmpEngine, 1, NULL, NULL, &error);
            SEN_DEBUG (([NSString stringWithFormat:@"++ received message %d", message]));
        } while ((message == gmp_nothing) || (message == gmp_reset));
    
        if (message == gmp_err)  {
            SEN_DEBUG (([NSString stringWithFormat:@"Goban-gmp: Error \"%s\" occurred.\n", error]));
        }
    //}

    gmp_startGame (gmpEngine, [game boardSize], [game handicap], [game komi], 0, [color asGMPValue]);
    SEN_DEBUG (@"gmp_startGame");

    do  {
        message = gmp_check(gmpEngine, 1, NULL, NULL, &error);
        SEN_DEBUG (([NSString stringWithFormat:@"Received message %d", message]));
    } while ((message == gmp_nothing) || (message == gmp_reset));        

    timer = [[NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(checkComputerPlay:) userInfo:nil repeats:YES] retain];
}


- (void) start
{
    [self setup];
    [timer fire];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    isPlaying = YES;
}



- (void) playGame:(GoGame *) aGame withColor:(GoSymbol *) aColor
{
    [super playGame:aGame withColor:aColor];
    [self start];
}


- (void) finishGame
{
    isPlaying = NO;
    if (task != nil) {
        SEN_DEBUG (@"Killing task");
        [timer invalidate];
        RELEASE (timer);
        gmp_destroy (gmpEngine);
        gmpEngine = NULL;
        [task terminate];
        RELEASE (task);
    }
}


- (void) dealloc
{
    [super dealloc];
}


- (GoMove *) nextMove
{
    const char *error;
    IntPoint point;
    GmpResult message = gmp_check (gmpEngine, 0, &point.x, &point.y, &error);
    SEN_DEBUG (([NSString stringWithFormat:@"Received message %d (%d, %d)", message, point.x, point.y]));

    if (message == gmp_nothing) {
        return nil;
    }
    else if (message == gmp_newGame) {
        SEN_DEBUG (@"New game received from gmp client");
        [NSException raise:NSGenericException format:@"New game received from gmp client"];
    }
    else if (message == gmp_err) {
        SEN_DEBUG (@"Error from gmp client");
        [NSException raise:NSGenericException format:@"Error from gmp client"];
    }
    else if (message == gmp_undo) {
        SEN_DEBUG (@"Undo received, not supported");
        [NSException raise:NSGenericException format:@"Undo received, not supported"];
    }
    else if (message == gmp_pass) {
        return [game passMoveForColor:color];
    }
    else if (message == gmp_move) {
        point.y = [game boardSize] - point.y - 1;
        return [game moveForColor:color atPoint:[game pointWithIntPoint:point]];
    }
    SEN_DEBUG (@"Error: gmp message unknown");
    [NSException raise:NSGenericException format:@"Error: gmp message unknown"];
    return nil;
}


- (void) checkComputerPlay:aTimer
{
    if ((task != nil) && [task isRunning]) {
        NS_DURING
            GoMove *move = [self nextMove];
            if ((move != nil) && !([game isOver] && [move isPass])) {
                [self didPlayMove:move];
            }
        NS_HANDLER
            if (![game isOver]) {
                [self didResign];
            }
        NS_ENDHANDLER;
    }
}


- (void) opponentDidPlayMove:(GoMove *) aMove
{
    senassert (gmpEngine != NULL);
    if ([aMove isPass]) {
        gmp_sendPass(gmpEngine);
    }
    else {
        gmp_sendMove (gmpEngine, [[aMove point] x], [game boardSize] - [[aMove point] y] - 1);
    }
}


- (void) opponentDidUndo
{
    senassert (gmpEngine != NULL);
    gmp_sendUndo (gmpEngine, 2);        
}


- (void) opponentDidResign
{
    senassert (gmpEngine != NULL);
    // ?
}

- (NSString *) kindAsString
{
    return @"Program (GMP)";
}

@end
