/*$Id: GoPoint.h,v 1.4 2001/10/10 20:10:34 phink Exp $*/

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
#import "GoGeometry.h"

@interface GoPoint : NSObject
{
    IntPoint p;
    int boardSize;
}

+ (GoPoint *) x:(int) x y:(int) y boardSize:(int) aBoardSize;
+ (GoPoint *) pointWithIntPoint:(IntPoint) p boardSize:(int) aBoardSize;
+ (GoPoint *) pointWithSGFPoint:(IntPoint) p boardSize:(int) aBoardSize;

- (int) x;
- (int) y;
- (IntPoint) intPointValue;
- (IntPoint) sgfPointValue;

- (NSEnumerator *) neighborEnumerator;
@end
