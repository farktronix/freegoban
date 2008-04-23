/*$Id: GoMove.m,v 1.6 2001/10/10 20:10:34 phink Exp $*/

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

#import "GoMove.h"
#import "GoGame.h"
#import "GoSymbol.h"
#import "GoGeometry.h"
#import "GoPoint.h"
#import <SenFoundation/SenFoundation.h>

@implementation GoMove

- (void) setColor:(GoSymbol *) aColor
{
    ASSIGN (color, aColor);
}


- (void) setPoint:(GoPoint *) aPoint
{
    ASSIGN (point, aPoint);
}


- initWithGame:(GoGame *) aGame color:(GoSymbol *) aColor atPoint:(GoPoint *) aPoint
{
    SGFTree *newNode = sgf_create_leaf();
    IntPoint sgfPoint = [aPoint sgfPointValue];
    sgf_set_property (newNode, 
                        (aColor == [GoSymbol black]) ? SGF_PROP_B : SGF_PROP_W, 
                        SGF_VALUE_TYPE_POINT, 
                        sgfPoint.x, sgfPoint.y);
    
    [self initWithGame:aGame node:newNode];
    senassert ([self isMove]);
    return self;
}


- initPassMoveWithGame:(GoGame *) aGame color:(GoSymbol *) aColor
{
    SGFTree *newNode = sgf_create_leaf();
    sgf_set_property (newNode, 
                        (aColor == [GoSymbol black]) ? SGF_PROP_B : SGF_PROP_W, 
                        SGF_VALUE_TYPE_NONE);

    [self initWithGame:aGame node:newNode];
    return self;
}


+ moveWithGame:(GoGame *) aGame color:(GoSymbol *) aColor atPoint:(GoPoint *) aPoint
{
    return [[[self alloc] initWithGame:aGame color:aColor atPoint:aPoint] autorelease];
}


+ passMoveWithGame:(GoGame *) aGame color:(GoSymbol *) aColor
{
    return [[[self alloc] initPassMoveWithGame:aGame color:aColor] autorelease];
}


- (SGFProperty *) movePropertyFromNode:(SGFTree *) aNode
{
    SGFProperty *property = sgf_get_property (aNode, SGF_PROP_B);
    if (property == NULL) {
        property = sgf_get_property (aNode, SGF_PROP_W);
    }
    return property;
}


- initWithGame:(GoGame *) aGame node:(SGFTree *) aNode
{
    SGFProperty *property = [self movePropertyFromNode:aNode];

    senassert (property != NULL);
    
    [super initWithGame:aGame node:aNode];

    isPass = (property->value.type == SGF_VALUE_TYPE_NONE);
    [self setPoint: (isPass) ? nil : [aGame pointWithSGFPoint:MakeIntPoint (property->value.value.point.x, property->value.value.point.y)]];
    [self setColor: ((property->id) == SGF_PROP_B) ? [GoSymbol black] : [GoSymbol white]];
    return self;
}


+ moveWithGame:(GoGame *) aGame node:(SGFTree *) aNode
{
    return [[[self alloc] initWithGame:aGame node:aNode] autorelease];
}


- (void) dealloc
{
    RELEASE (color);
    RELEASE (point);
    [super dealloc];
}


- (BOOL) isPass
{
    return isPass;
}


- (GoSymbol *) color
{
    return color;
}


- (GoPoint *) point
{
    return point;
}


- (NSString *) description
{
    if ([self isPass]) {
        return [NSString stringWithFormat:@"%@ passes", [color name]];
    }
    else {
        return [NSString stringWithFormat:@"%@ at %d %d", [color name], [point x], [point y]];
    }
}
@end
