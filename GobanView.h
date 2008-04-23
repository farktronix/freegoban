/*$Id: GobanView.h,v 1.3 2001/10/02 16:16:23 phink Exp $*/

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

#import <AppKit/AppKit.h>

@class GoGame;
@class GoPoint;
@class GobanMatrix;

@interface GobanView : NSView
{
    GoGame *game;
    IBOutlet GobanMatrix *matrix;
    BOOL isShowingTerritory;
    NSMutableArray *labelViews;
    NSSize cellSize;
}

- (void) setGame:(GoGame *) aGame;

- (GoPoint *) selectedPoint;
- (void) update;

- (BOOL) isShowingTerritory;
- (void) showTerritory;
- (void) hideTerritory;

- (BOOL) isShowingLabels;
- (void) showLabels;
- (void) hideLabels;

- (NSSize) windowWillResizeToSize:(NSSize) proposedSize;
@end
