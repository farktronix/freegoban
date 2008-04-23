/*$Id: GoGeometry.m,v 1.2 2001/10/02 16:12:17 phink Exp $*/

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

#import "GoGeometry.h"
#import <SenFoundation/SenFoundation.h>

IntPoint IntPointFromString(NSString *aString)
{
    const char *cString = [aString cString];
    assert ([aString length] == 2);
    return MakeIntPoint (toupper(cString[1]) - 'A', toupper(cString[0]) - 'A');
}


NSString *NSStringFromIntPoint(IntPoint aPoint)
{
    return [NSString stringWithFormat:@"%c%c", 'a'+ aPoint.y, 'a' + aPoint.x];
}


@implementation NSValue (GoGeometryExtensions)
+ (NSValue *) valueWithIntPoint:(IntPoint) point
{
    return [self value:&point withObjCType:@encode(IntPoint)];
}


+ (NSValue *) valueWithIntRectangle:(IntRectangle) rect
{
    return [self value:&rect withObjCType:@encode(IntRectangle)];    
}

- (IntPoint) intPointValue
{
    IntPoint p;
    [self getValue:&p];
    return p;
}


- (IntRectangle) intRectangleValue
{
    IntRectangle r;
    [self getValue:&r];
    return r;
}
@end
