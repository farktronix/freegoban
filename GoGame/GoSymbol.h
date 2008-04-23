/*$Id: GoSymbol.h,v 1.4 2001/10/02 16:12:18 phink Exp $*/

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

@interface GoSymbol : NSObject
{
}

- (NSString *) name;

+ (GoSymbol *) black;
+ (GoSymbol *) white;

+ (GoSymbol *) blackTerritory;
+ (GoSymbol *) whiteTerritory;
+ (GoSymbol *) neutralTerritory; // "Dame"

+ (GoSymbol *) blackPrisoner;
+ (GoSymbol *) whitePrisoner;

- (BOOL) isTerritory;
@end


@interface GoSymbol (GMPValue)
- (int) asGMPValue;
@end



@interface GoBlack : GoSymbol
@end

@interface GoWhite : GoSymbol
@end

@interface GoBlackTerritory : GoSymbol
@end

@interface GoWhiteTerritory : GoSymbol
@end

@interface GoNeutralTerritory : GoSymbol
@end

@interface GoBlackPrisoner : GoSymbol
@end

@interface GoWhitePrisoner : GoSymbol
@end
