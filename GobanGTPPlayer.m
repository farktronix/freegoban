/*$Id: GobanGTPPlayer.m,v 1.2 2001/10/04 16:12:18 phink Exp $*/

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

#import "GobanGTPPlayer.h"
#import <GoGame/GoGame.h>
#import <GoGame/GoPosition.h>
#import <GoGame/GoGeometry.h>
#import <GoGame/GoSymbol.h>
#import <GoGame/GoMove.h>
#import <GoGame/GoPoint.h>
#import <SenFoundation/SenFoundation.h>

@interface GoSymbol (GTP)
- (NSString *) gtpRepresentation;
@end

@implementation GoSymbol (GTP)
- (NSString *) gtpRepresentation
{
    return @"";
}
@end

@implementation GoBlack (GTP)
- (NSString *) gtpRepresentation
{
    return @"black";
}
@end

@implementation GoWhite (GTP)
- (NSString *) gtpRepresentation
{
    return @"white";
}
@end


@interface GoPoint (GTP)
- (NSString *) gtpRepresentation;
@end


@implementation GoPoint (GTP)
- (NSString *) gtpRepresentation
{
    char c = 'A' + p.x;
    if (c >= 'I') {
        c++;
    }
    return [NSString stringWithFormat:@"%c%d", c, p.y + 1];
}
@end


@implementation GoMove (GTP)
- (NSString *) gtpRepresentation
{
    return [self isPass] ? 
        [NSString stringWithFormat:@"%@ pass", [color gtpRepresentation]] : 
        [NSString stringWithFormat:@"%@ %@", [color gtpRepresentation], [point gtpRepresentation]];
}
@end


@implementation GobanGTPPlayer

- (void) launchTask
{
    NSPipe *stdoutPipe = [NSPipe pipe];
    NSPipe *stdinPipe = [NSPipe pipe];
    task = [[NSTask alloc] init];
    [task setLaunchPath:[self launchPath]];
    [task setArguments:[self launchArguments]];
    [task setStandardOutput:stdoutPipe];
    [task setStandardInput:stdinPipe];
    commandIdentifier = 0;
    [task launch];
    [[NSNotificationCenter defaultCenter] 
        addObserver:self 
        selector:@selector(handleReadCompletion:) 
        name:NSFileHandleReadCompletionNotification 
        object:[stdoutPipe fileHandleForReading]];
}


- (void) terminateTask
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (task != nil) {
        [task terminate];
        RELEASE (task);
    }
}


- (NSFileHandle *) fileHandleForReading
{
    return [[task standardOutput] fileHandleForReading];
}


- (NSFileHandle *) fileHandleForWriting
{
    return [[task standardInput] fileHandleForWriting];
}


- (NSData *) dataWithCommand:(NSString *) command
{
    return [command dataUsingEncoding:NSASCIIStringEncoding];
}


- (NSString *) responseWithData:(NSData *) data
{
    return [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
}


- (void) validateResponseData:(NSData *) responseData
{
    NSMutableString *responseString = [NSMutableString stringWithString:[self responseWithData:responseData]];
    int responseLength;
    
    while (![responseString hasSuffix:@"\n\n"]) {
        [responseString appendString:[self responseWithData:[[self fileHandleForReading] availableData]]];
    }
    
    if (![responseString hasPrefix:[NSString stringWithFormat:@"=%d", commandIdentifier]]) {
        [NSException raise:NSGenericException format:@"Error: (GTP) %@", responseString];
    }

    responseLength = [responseString length];
    [responseString deleteCharactersInRange:NSMakeRange (responseLength - 2, 2)];
    [responseString deleteCharactersInRange:NSMakeRange (0, [responseString rangeOfString:@" "].location + 1)];

    commandIdentifier++;
    if (responseAction != (SEL) 0) {
        [self performSelector:responseAction withObject:responseString];
    }
}


- (void) handleReadCompletion:(NSNotification *) aNotification
{
    NSData *responseData = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    if (!isNilOrEmpty(responseData)) {
        [self validateResponseData:responseData];
    }
}


- (void) sendCommand:(NSString *) command inBackground:(BOOL) inBackground responseAction:(SEL) aSelector
{
    NSString *identifiedCommand = [NSString stringWithFormat:@"%d %@\n", commandIdentifier, command];
    
    //SEN_DEBUG (identifiedCommand);
    [[self fileHandleForWriting] writeData:[self dataWithCommand:identifiedCommand]];
    responseAction = aSelector;
    if (!inBackground) {
        [self validateResponseData:[[self fileHandleForReading] availableData]];
    }
    else {
        [[self fileHandleForReading] readInBackgroundAndNotify];
    }
}


- (void) sendCommand:(NSString *) command
{
    return [self sendCommand:command inBackground:NO responseAction:(SEL) 0];
}


- (void) replayGame
{
    NSEnumerator *moveEnumerator = [[game currentLineOfPlay] objectEnumerator];
    id each;
    while (each = [moveEnumerator nextObject]) {
        [self sendCommand:[each gtpRepresentation]];
    }
}


- (void) setupGameParameters
{
    [self sendCommand:[NSString stringWithFormat:@"boardsize %d", [game boardSize]]];
    [self sendCommand:[NSString stringWithFormat:@"fixed_handicap %d", [game handicap]]];
    [self sendCommand:[NSString stringWithFormat:@"komi %.1f", [game komi]]];
}


- (void) start
{
    isPlaying = YES;
    [self launchTask];
    [self setupGameParameters];
    if ([game isStarted]) {
        [self replayGame];
    }
    if ([game nextColor] == [self color]) {
        [self generateMove];
    }
}


- (void) playGame:(GoGame *) aGame withColor:(GoSymbol *) aColor
{
    [super playGame:aGame withColor:aColor];
    [self start];
}


- (void) finishGame
{
    isPlaying = NO;
    [self terminateTask];
}


- (void) dealloc
{
    [super dealloc];
}


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
    }
    [self didPlayMove:move];
}


- (void) generateMove
{
    if (![game isOver]) {
        [self sendCommand: ([self color] == [GoSymbol black]) ? @"genmove_black" : @"genmove_white" 
            inBackground:YES 
            responseAction:@selector(playMoveFromString:)];
    }
}


- (void) opponentDidPlayMove:(GoMove *) aMove
{
    [self sendCommand:[aMove gtpRepresentation]];
    [self generateMove];
}


- (void) opponentDidUndo
{
    [self sendCommand:@"undo"];
    [self sendCommand:@"undo"];
}


- (void) opponentDidResign
{
    [self sendCommand:@"quit"];
}


- (NSString *) kindAsString
{
    return @"Program (GTP)";
}
@end
