/*$Id: GobanPlayerDefaults.m,v 1.1 2001/10/02 16:13:29 phink Exp $*/

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

#import "GobanPlayerDefaults.h"
#import "GobanPlayer.h"
#import "GobanHumanPlayer.h"

@implementation GobanPlayerDefaults
+ (id) sharedInstance
{
    static id sharedInstance = nil;
    if (sharedInstance == nil) {
        sharedInstance = [[self alloc] init];
    }
    return sharedInstance;
}


- (NSUserDefaults *) defaults
{	
    return [NSUserDefaults standardUserDefaults];
}


- (void) cacheDefaultPlayers
{
    NSEnumerator *playerEnumerator = [[[self defaults] arrayForKey:@"Players"] objectEnumerator];
    id each;
    
    defaultPlayers = [[NSMutableArray alloc] init];
    while (each = [playerEnumerator nextObject]) {
        Class playerClass = NSClassFromString ([each objectForKey:@"class"]);
        id player = [playerClass player];
        [player takeValuesFromDictionary:[each objectForKey:@"object"]];
        [defaultPlayers addObject:player];
    }
}


- (NSArray *) players
{
    if (defaultPlayers == nil) {
        [self cacheDefaultPlayers];
    }
    return defaultPlayers;
}


- (NSDictionary *) dictionaryFromPlayer:(GobanPlayer *) aPlayer
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    NSEnumerator *keyEnumerator = [[aPlayer savedValueKeys] objectEnumerator];
    id each;
    while (each = [keyEnumerator nextObject]) {
        if ([aPlayer valueForKey:each] != nil) {
            [dictionary setObject:[aPlayer valueForKey:each] forKey:each];
        }
    }
    return [NSDictionary dictionaryWithObjectsAndKeys:
        NSStringFromClass([aPlayer class]), @"class", 
        dictionary, @"object",
        nil];
}


- (void) saveDefaultPlayers
{
    NSMutableArray *array = [NSMutableArray array];
    NSEnumerator *playerEnumerator = [defaultPlayers objectEnumerator];
    id each;
    while (each = [playerEnumerator nextObject]) {
        [array addObject:[self dictionaryFromPlayer:each]];
    }
    [[self defaults] setObject:array forKey:@"Players"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DefaultPlayersDidChangeNotification" object:self];
}


- (void) addPlayer:(GobanPlayer *) aPlayer
{
    if (defaultPlayers == nil) {
        [self cacheDefaultPlayers];
    }
    [defaultPlayers addObject:aPlayer];
    [self saveDefaultPlayers];
}


- (void) removePlayer:(GobanPlayer *) aPlayer
{
    if (defaultPlayers == nil) {
        [self cacheDefaultPlayers];
    }
    [defaultPlayers removeObject:aPlayer];
    [self saveDefaultPlayers];
}


- (int) defaultWhitePlayerIndex
{
    return [[[self defaults] objectForKey:@"WhitePlayer"] intValue];
}


- (void) setDefaultWhitePlayerIndex:(int) aValue
{
    [[self defaults] setObject:[[NSNumber numberWithInt:aValue] stringValue] forKey:@"WhitePlayer"];
}


- (int) defaultBlackPlayerIndex
{
    return [[[self defaults] objectForKey:@"BlackPlayer"] intValue];
}


- (void) setDefaultBlackPlayerIndex:(int) aValue
{
    [[self defaults] setObject:[[NSNumber numberWithInt:aValue] stringValue] forKey:@"BlackPlayer"];
}


- (GobanPlayer *) prototypeWhitePlayer
{
    return [[self players] objectAtIndex:MIN([self defaultWhitePlayerIndex], [[self players] count] - 1)];
}


- (GobanPlayer *) prototypeBlackPlayer
{
    return [[self players] objectAtIndex:MIN([self defaultBlackPlayerIndex], [[self players] count] - 1)];
}


- (GobanPlayer *) playerNamed:(NSString *) aName
{
    NSEnumerator *playerEnumerator = [[self players] objectEnumerator];
    id each;
    
    while (each = [playerEnumerator nextObject]) {
        if ([[each name] isEqualToString:aName]) {
            return each;
        }
    }
    return [GobanHumanPlayer playerWithName:aName];
}
@end
