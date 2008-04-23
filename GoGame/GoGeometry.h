/*$Id: GoGeometry.h,v 1.2 2001/09/17 09:47:41 phink Exp $*/

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

enum {SenIllegalCoordinate = 0x7fffffff};

#define MIN_BOARD_SIZE 3
#define MAX_BOARD_SIZE 19


typedef struct _IntPoint
{
    int x;
    int y;
} IntPoint;

typedef struct _IntRectangle
{
    int minX;
    int maxX;
    int minY;
    int maxY;
} IntRectangle;


static inline IntPoint MakeIntPoint (int x, int y)
{
    IntPoint p;
    p.x = x;
    p.y = y;
    return p;
}


static inline IntRectangle MakeIntRectangle (int minX, int maxX, int minY, int maxY)
{
    IntRectangle r;
    r.minX = minX;
    r.maxX = maxX;
    r.minY = minY;
    r.maxY = maxY;
    return r;
}


static inline BOOL IsValidIntPoint (IntPoint p)
{
    return (p.x != SenIllegalCoordinate) && (p.y != SenIllegalCoordinate);
}


static inline BOOL EqualIntPoints (IntPoint a, IntPoint b)
{
    return (a.x == b.x) && (a.y == b.y);
}


static inline BOOL IntPointInRectangle (IntPoint p, IntRectangle r)
{
    return (p.x >= r.minX) && (p.x <= r.maxX) && (p.y >= r.minY) && (p.y <= r.maxY);
}


IntPoint IntPointFromString(NSString *aString);
NSString *NSStringFromIntPoint(IntPoint aPoint);

@interface NSValue (GoGeometryExtensions)

+ (NSValue *) valueWithIntPoint:(IntPoint)point;
+ (NSValue *) valueWithIntRectangle:(IntRectangle)rect;

- (IntPoint) intPointValue;
- (IntRectangle) intRectangleValue;

@end

