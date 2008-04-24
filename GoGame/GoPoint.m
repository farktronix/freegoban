/*$Id: GoPoint.m,v 1.4 2001/10/10 20:10:34 phink Exp $*/

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

#import "GoPoint.h"
#import <SenFoundation/SenFoundation.h>

@interface GoPoint (Private)
- initWithIntPoint:(IntPoint) anIntPoint boardSize:(int) aBoardSize;
@end


@interface NSMutableArray (GoPoint)
- (void) addObjectIfNotNil:(id) anObject;
@end


@implementation GoPoint

static NSMutableDictionary *pointCaches = nil;

+ (NSMutableDictionary *) pointCaches
{
    if (pointCaches == nil) {
        pointCaches = [[NSMutableDictionary dictionary] retain];
    }
    return pointCaches;
}


+ (const GoPoint **) cacheForBoardSize:(int) aBoardSize
{
    NSNumber *key = [NSNumber numberWithInt:aBoardSize];
    NSMutableData *cacheData = [[self pointCaches] objectForKey:key];

    if (cacheData == nil) {
        GoPoint **cacheBuffer;
        int i, j;
        int south = aBoardSize + 1;
        int origin = south + 1;

        int cacheSize = (aBoardSize * aBoardSize + 3 * (aBoardSize + 1));

        cacheData = [NSMutableData dataWithLength:cacheSize * sizeof (GoPoint *)];
        cacheBuffer = (GoPoint **) [cacheData mutableBytes];
        for (i = 0; i < aBoardSize; i++) {
            for (j = 0;  j < aBoardSize; j++) {
                GoPoint *goPoint = [[self alloc] initWithIntPoint:MakeIntPoint(i, j) boardSize:aBoardSize];
                cacheBuffer [south * j + i + origin] = goPoint;
            }
        }
        [[self pointCaches] setObject:cacheData forKey:key];
    }
    return (const GoPoint **)[cacheData bytes];
}


- initWithIntPoint:(IntPoint) anIntPoint boardSize:(int) aBoardSize
{
    [super init];
    p = anIntPoint;
    boardSize = aBoardSize;
    return self;
}


+ (GoPoint *) x:(int) x y:(int) y boardSize:(int) aBoardSize;
{
    GoPoint **cacheForBoardSize = [self cacheForBoardSize:aBoardSize];
    int south = aBoardSize + 1;
    int origin = south + 1;
    return cacheForBoardSize [south * (y) + (x) + origin];
}


+ (GoPoint *) pointWithIntPoint:(IntPoint) anIntPoint boardSize:(int) aBoardSize
{
    GoPoint **cacheForBoardSize = [self cacheForBoardSize:aBoardSize];
    int south = aBoardSize + 1;
    int origin = south + 1;
    return cacheForBoardSize [south * (anIntPoint.y) + (anIntPoint.x) + origin];
}


+ (GoPoint *) pointWithSGFPoint:(IntPoint) aSGFPoint boardSize:(int) aBoardSize
{
    return [self pointWithIntPoint:MakeIntPoint (aSGFPoint.x, aBoardSize - 1 - aSGFPoint.y) boardSize:aBoardSize];
}


- (int) x
{
    return p.x;
}


- (int) y
{
    return p.y;
}


- (IntPoint) intPointValue
{
    return p;
}


- (IntPoint) sgfPointValue
{
    return MakeIntPoint (p.x, boardSize - 1 - p.y);
}


- (NSEnumerator *) neighborEnumerator
{
    NSMutableArray *neighbors = [NSMutableArray arrayWithCapacity:4];
    GoPoint **cacheForBoardSize = [[self class] cacheForBoardSize:boardSize];
    int south = boardSize + 1;
    int origin = south + 1;

    [neighbors addObjectIfNotNil:cacheForBoardSize [south * (p.y - 1) + (p.x) + origin]];
    [neighbors addObjectIfNotNil:cacheForBoardSize [south * (p.y + 1) + (p.x) + origin]];
    [neighbors addObjectIfNotNil:cacheForBoardSize [south * (p.y) + (p.x - 1) + origin]];
    [neighbors addObjectIfNotNil:cacheForBoardSize [south * (p.y) + (p.x + 1) + origin]];
    return [neighbors objectEnumerator];
}


- (id) autorelease
{
    return self;
}


- (void) release
{
}


- (unsigned) retainCount
{
    return 1;
}


- (id) retain
{
    return self;
}


- (void) dealloc
{
    [super dealloc];
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"%@ {%d, %d}", [super description], p.x, p.y];
}
@end



@implementation NSMutableArray (GoPoint)
- (void) addObjectIfNotNil:(id) anObject
{
    if (anObject != nil) {
        [self addObject:anObject];
    }
}
@end
