/*$Id: GobanProgressItem.m,v 1.2 2001/10/04 16:14:14 phink Exp $*/

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

#import "GobanProgressItem.h"
#import "GobanToolbar.h"
#import "GobanGameDocument.h"
#import <GoGame/GoGame.h>
#import <GoGame/GoPosition.h>
#import <SenFoundation/SenFoundation.h>

@implementation GobanProgressItem
- (GobanGameDocument *) document
{
    return [[[self toolbar] delegate] document];
}


- (void) startAnimationWithLabel:(NSString *) aLabel
{
    NSProgressIndicator *indicator = [self view];
    [indicator setIndeterminate:YES];
    [indicator startAnimation:self];
    [self setLabel:aLabel];
}


- (void) stopAnimationWithLabel:(NSString *) aLabel
{
    NSProgressIndicator *indicator = [self view];
    [indicator stopAnimation:self];
    [indicator setIndeterminate:NO];
    [self setLabel:aLabel];
}


- (void) validate
{
    GobanGameDocument *document = [self document];
    if ([document isProgramActive]) {
        [self startAnimationWithLabel:[document statusString]];
    }
    else {
        [self stopAnimationWithLabel:[document statusString]];
    }
}
@end
