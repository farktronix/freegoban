/*$Id: GoSymbol.m,v 1.4 2001/10/02 16:12:18 phink Exp $*/

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

#import "GoSymbol.h"
#import <SenFoundation/SenFoundation.h>

@implementation GoSymbol
+ (GoSymbol *) symbolOfClass:(Class) aClass
{
    static NSMutableDictionary *symbolDictionary = nil;
    GoSymbol *symbol = nil;
    if (symbolDictionary == nil) {
        symbolDictionary = [[NSMutableDictionary alloc] init];
    }
    symbol = [symbolDictionary objectForKey:NSStringFromClass(aClass)];
    if (symbol == nil) {
        symbol = [[aClass alloc] init];
        [symbolDictionary setObject:symbol forKey:NSStringFromClass(aClass)];
    }
    return symbol;
}



+ (GoSymbol *) black
{
    return [self symbolOfClass:[GoBlack class]];
}


+ (GoSymbol *) white
{
    return [self symbolOfClass:[GoWhite class]];
}

+ (GoSymbol *) whiteTerritory
{
    return [self symbolOfClass:[GoWhiteTerritory class]];
}

+ (GoSymbol *) blackTerritory
{
    return [self symbolOfClass:[GoBlackTerritory class]];
}

+ (GoSymbol *) neutralTerritory
{
    return [self symbolOfClass:[GoNeutralTerritory class]];
}

+ (GoSymbol *) blackPrisoner
{
    return [self symbolOfClass:[GoBlackPrisoner class]];
}

+ (GoSymbol *) whitePrisoner
{
    return [self symbolOfClass:[GoWhitePrisoner class]];
}


- (NSString *) name
{
    return nil;
}

- (BOOL) isTerritory
{
    return NO;
}

@end


@implementation GoBlack : GoSymbol
- (NSString *) name
{
    return @"BlackStone";
}
@end


@implementation GoWhite : GoSymbol
- (NSString *) name
{
    return @"WhiteStone";
}
@end


@implementation GoBlackTerritory : GoSymbol
- (NSString *) name
{
    return @"BlackTerritory";
}

- (BOOL) isTerritory
{
    return YES;
}
@end


@implementation GoWhiteTerritory : GoSymbol
- (NSString *) name
{
    return @"WhiteTerritory";
}

- (BOOL) isTerritory
{
    return YES;
}
@end


@implementation GoNeutralTerritory : GoSymbol
- (NSString *) name
{
    return @"NeutralTerritory";
}

- (BOOL) isTerritory
{
    return YES;
}
@end


@implementation GoBlackPrisoner : GoSymbol
- (NSString *) name
{
    return @"BlackPrisoner";
}
@end


@implementation GoWhitePrisoner : GoSymbol
- (NSString *) name
{
    return @"WhitePrisoner";
}
@end


@implementation GoSymbol (GMPValue)
- (int) asGMPValue
{
    return -1;
}
@end


@implementation GoBlack (GMPValue)
- (int) asGMPValue
{
    return 1;
}
@end


@implementation GoWhite (GMPValue)
- (int) asGMPValue
{
    return 0;
}
@end


