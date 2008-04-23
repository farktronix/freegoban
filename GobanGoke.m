/*$Id: GobanGoke.m,v 1.3 2001/09/17 09:47:37 phink Exp $*/

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

#import "GobanGoke.h"
#import <SenFoundation/SenFoundation.h>

#define MIN_SIZE 20
#define MAX_SIZE 130
#define HALF_PIXEL          0.5


@interface GobanWhiteGoke : GobanGoke
@end


@interface GobanBlackGoke : GobanGoke
@end


@interface GoSymbol (GokePrivate)
- (id) goke;
@end


@implementation GoSymbol (Goke)
- (id) goke
{
    return nil;
}


- (NSImage *) imageOfSize:(int) aSize;
{
    return [self imageOfSize:aSize style:-1];
}


- (NSImage *) imageOfSize:(int) aSize style:(int) aStyle
{
    int size = MIN (MAX_SIZE, MAX (aSize, MIN_SIZE));
    return [[self goke] stoneOfSize:size style:aStyle];
}
@end


@implementation GoBlack (Goke)
- (id) goke
{
    return [GobanBlackGoke sharedInstance];
}
@end


@implementation GoWhite (Goke)
- (id) goke
{
    return [GobanWhiteGoke sharedInstance];
}
@end


@interface GoSymbol (Overlay)
- (NSImage *) prisonerImageWithSource:(NSImage *) anImage andColor:(NSColor *) aColor;
- (NSImage *) territoryImageOfSize:(int) aSize andColor:(NSColor *) aColor;
@end


@implementation GoSymbol (Overlay)
- (NSImage *) prisonerImageWithSource:(NSImage *) anImage andColor:(NSColor *) aColor
{
    NSBezierPath *disc = [NSBezierPath bezierPath];
    NSImage *image = [anImage copy];
    float width = [image size].width;
    float radius = width / 8;
    float offset = width / 4;
    NSRect square = NSMakeRect (offset + 0.5, offset + 0.5, 2 * offset - 1, 2 * offset - 1);
    [image lockFocus];
    [aColor set];
    NSFrameRectWithWidth (square, 0.75);
    
    [disc appendBezierPathWithOvalInRect:
        NSMakeRect (
                width / 2 - radius ,
                width / 2 - radius ,
                2.0 * radius,
                2.0 * radius)];
    [disc fill];

    [image unlockFocus];
    return [image autorelease];
}


- (NSImage *) territoryImageOfSize:(int) aSize andColor:(NSColor *) aColor
{
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize (aSize, aSize)];
    NSBezierPath *disc = [NSBezierPath bezierPath];
    float width = [image size].width;
    float diameter = width / 4;
    NSPoint origin = NSMakePoint (HALF_PIXEL + floor((width - diameter) / 2), 1.0 + HALF_PIXEL + floor((width - diameter) / 2));

    [image lockFocus];
    [aColor set];
    [disc appendBezierPathWithOvalInRect:NSMakeRect (origin.x , origin.y , diameter, diameter)];
    [disc fill];
    [image unlockFocus];

    return [image autorelease];
}
@end


@implementation GoWhitePrisoner (Image)
- (NSImage *) imageOfSize:(int) aSize style:(int) aStyle
{
    return [self prisonerImageWithSource:[[[GoSymbol white] goke] stoneOfSize:aSize style:aStyle] andColor:[NSColor blackColor]];
}
@end


@implementation GoBlackPrisoner (Image)
- (NSImage *) imageOfSize:(int) aSize style:(int) aStyle
{
    return [self prisonerImageWithSource:[[[GoSymbol black] goke] stoneOfSize:aSize style:aStyle] andColor:[NSColor whiteColor]];
}
@end


@implementation GoWhiteTerritory (Image)
- (NSImage *) imageOfSize:(int) aSize style:(int) aStyle
{
    static NSMutableDictionary *goWhiteTerritoryCache = nil;
    NSImage *image = nil;
    
    if (goWhiteTerritoryCache == nil) {
        goWhiteTerritoryCache = [[NSMutableDictionary alloc] init];
    }
    image = [goWhiteTerritoryCache objectForKey:[NSNumber numberWithInt:aSize]];
    if (image == nil) {
        image = [self territoryImageOfSize:aSize andColor:[NSColor whiteColor]];
        [goWhiteTerritoryCache setObject:image forKey:[NSNumber numberWithInt:aSize]];
    }
    return image;
}
@end


@implementation GoBlackTerritory (Image)
- (NSImage *) imageOfSize:(int) aSize style:(int) aStyle
{
    static NSMutableDictionary *goBlackTerritoryCache = nil;
    NSImage *image = nil;
    
    if (goBlackTerritoryCache == nil) {
        goBlackTerritoryCache = [[NSMutableDictionary alloc] init];
    }
    image = [goBlackTerritoryCache objectForKey:[NSNumber numberWithInt:aSize]];
    if (image == nil) {
        image = [self territoryImageOfSize:aSize andColor:[NSColor blackColor]];
        [goBlackTerritoryCache setObject:image forKey:[NSNumber numberWithInt:aSize]];
    }
    return image;
}
@end


@implementation GoNeutralTerritory (Image)
- (NSImage *) imageOfSize:(int) aSize style:(int) aStyle
{
    static NSMutableDictionary *goNeutralTerritoryCache = nil;
    NSImage *image = nil;
    
    if (goNeutralTerritoryCache == nil) {
        goNeutralTerritoryCache = [[NSMutableDictionary alloc] init];
    }
    
    image = [goNeutralTerritoryCache objectForKey:[NSNumber numberWithInt:aSize]];
    
    if (image == nil) {
        float width = aSize;
        float offset = width / 4;
        NSRect square = NSMakeRect (offset + 0.5 , offset + 0.5, 2 * offset - 1, 2 * offset - 1);
        image = [[[NSImage alloc] initWithSize:NSMakeSize (aSize, aSize)] autorelease];
        [image lockFocus];
        [[NSColor blackColor] set];
        NSFrameRectWithWidth (square, 0.75);
        [image unlockFocus];
        [goNeutralTerritoryCache setObject:image forKey:[NSNumber numberWithInt:aSize]];
    }
    return image;
}
@end


@implementation GobanGoke
- (id) init
{
    [super init];
    cache = [[NSMutableDictionary alloc] init];
    return self;
}


- (void) dealloc
{
    RELEASE (cache);
    [super dealloc];
}


- (NSImage *) imageForKey:(id) aKey atIndex:(int) anIndex
{
    return nil;
}


- (NSImage *) stoneOfSize:(int) aSize style:(int) aStyle
{
    NSNumber *key = [NSNumber numberWithInt:aSize];
    if (aSize <= 48) {
        NSImage *image = [self imageForKey:key atIndex:aStyle];
        return image;
    }
    else {
        NSImage *image = [[[self imageForKey:[NSNumber numberWithInt:130] atIndex:aStyle] copy] autorelease];
        [image setScalesWhenResized:YES];
        [image setSize:NSMakeSize (aSize, aSize)];
        return image;
    }
}


+ (id) sharedInstance
{
    return nil;
}
@end


@implementation GobanWhiteGoke
+ (id) sharedInstance
{
    static id whiteGoke = nil;
    if (whiteGoke == nil) {
        whiteGoke = [[self alloc] init];
    }
    return whiteGoke;
}


- (NSImage *) imageForKey:(id) aKey atIndex:(int) anIndex
{
    NSMutableArray *stoneArray = [cache objectForKey:aKey];
    if (stoneArray == nil) {
        int i;
        stoneArray = [NSMutableArray arrayWithCapacity:STYLE_COUNT];
        for (i = 0; i < STYLE_COUNT; i++) {
            NSString *stoneName = [NSString stringWithFormat:@"WhiteStone%@-%d", aKey, i];	
            NSString *stonePath = [[NSBundle bundleForClass:[self class]] pathForResource:stoneName ofType:@"png" inDirectory:@"WhiteStones"];
            NSImage *image = [[NSImage alloc] initWithContentsOfFile:stonePath];
            if (image != nil) {
                [stoneArray addObject:image];
                RELEASE (image);
            }
        }
        if (!isNilOrEmpty (stoneArray)) {
            [cache setObject:stoneArray forKey:aKey];
        }
    }
    if (stoneArray != nil) {
        return [stoneArray objectAtIndex:anIndex];
    }
    return nil;
}
@end


@implementation GobanBlackGoke
+ (id) sharedInstance
{
    static id blackGoke = nil;
    if (blackGoke == nil) {
        blackGoke = [[self alloc] init];
    }
    return blackGoke;
}


- (NSImage *) imageForKey:(id) aKey atIndex:(int) anIndex
{
    NSImage *image = [cache objectForKey:aKey];
    if (image == nil) {
        NSString *stoneName = [NSString stringWithFormat:@"BlackStone%@", aKey];	
        NSString *stonePath = [[NSBundle bundleForClass:[self class]] pathForResource:stoneName ofType:@"png" inDirectory:@"BlackStones"];
        image = [[[NSImage alloc] initWithContentsOfFile:stonePath] autorelease];
        if (image != nil) {
            [cache setObject:image forKey:aKey];
        }
    }
    return image;
}
@end
