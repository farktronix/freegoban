/*$Id: GobanCell.m,v 1.2 2001/09/17 09:47:36 phink Exp $*/

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

#import "GobanCell.h"
#import "GobanGoke.h"

static __inline__ int randomIntLessThan(int a)
{
    return (int) ((a - 1) * ((float)random() / (float) LONG_MAX));
}


static __inline__ float randomFloatBetween(float a, float b)
{
    return a + (b - a) * ((float)random() / (float) LONG_MAX);
}


@implementation GobanCell
- initTextCell:(NSString *) aString
{
    [super initTextCell:aString];
    isInitialized = NO;
    return self;
}


- initImageCell:(NSImage *) anImage
{
    [super initImageCell:anImage];
    isInitialized = NO;
    return self;
}


- (void) place
{
    style = randomIntLessThan(STYLE_COUNT);
    perturbation = NSMakePoint (randomFloatBetween(-1.0, 1.0), randomFloatBetween(-1.0, 1.0));
    isInitialized = YES;
}


- (int) style
{
    if (!isInitialized) {
        [self place];
    }
    return style;
}


- (NSPoint) perturbation
{
    if (!isInitialized) {
        [self place];
    }
    return perturbation;
}
@end
