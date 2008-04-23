/*$Id: GobanMatrix.m,v 1.3 2001/10/02 16:21:03 phink Exp $*/

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

#import "GobanMatrix.h"
#import "GobanCell.h"
#import "GoGame/GoPoint.h"
#import "GoGame/GoGeometry.h"
#import <SenFoundation/SenFoundation.h>

@implementation GobanMatrix
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent;
{
    return YES;
}


- (GoPoint *) selectedPoint
{
    if (([self selectedColumn] < 0) || ([self selectedRow] < 0)) {
        return nil;
    }
    return [GoPoint x:[self selectedColumn] y:[self numberOfRows] - [self selectedRow] - 1 boardSize:[self numberOfRows]];
}


- (id) cellAtPoint:(GoPoint *) aPoint
{
    return [self cellAtRow:[self numberOfRows] - [aPoint y] - 1 column:[aPoint x]];
}


- (void) setBoardSize:(int) aBoardSize
{
    int i, j;

    [self renewRows:aBoardSize columns:aBoardSize];
    for (i = 0; i < aBoardSize; i++) {
        for (j = 0; j < aBoardSize; j++) {
            id cell = [self cellAtRow:i column:j];
            [cell setTitle:@""];
            [cell setImagePosition:NSImageOnly];
        }
    }
}


- (void) awakeFromNib
{
    NSButtonCell *original = [self prototype];
    GobanCell *cellPrototype = [[[GobanCell alloc] initTextCell:@""] autorelease];
    
    [cellPrototype setImagePosition:NSNoImage];
    [cellPrototype setHighlightsBy:[original highlightsBy]];
    [cellPrototype setShowsStateBy:[original showsStateBy]];
    [cellPrototype setButtonType:NSMomentaryPushInButton];
    [cellPrototype setTransparent:YES];
    [cellPrototype setBordered:NO];
    [cellPrototype setBezelStyle:[original bezelStyle]];
    
    while ([self numberOfRows] > 0) {
        [self removeRow:0];
    }
    [self setPrototype:cellPrototype];
    [self setCellClass:[cellPrototype class]];
}
@end
