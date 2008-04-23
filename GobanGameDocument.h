/*$Id: GobanGameDocument.h,v 1.5 2001/10/04 16:15:09 phink Exp $*/

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
@class GobanView;
@class GobanPlayer;
@class GobanGnuGoPlayer;
@class GobanInspectorController;

@interface GobanGameDocument : NSDocument
{
    GoGame *game;
    GobanPlayer *whitePlayer;
    GobanPlayer *blackPlayer;
    GobanGnuGoPlayer *scorer;
    IBOutlet GobanView *grid;
    IBOutlet GobanInspectorController *inspector;
}

- (IBAction) playStone:(id) sender;

- (IBAction) startOrResume:(id) sender;
- (BOOL) isStartOrResumeValid;

- (IBAction) pass:(id) sender;
- (IBAction) resign:(id) sender;

- (IBAction) undoMove:(id) sender;

- (IBAction) showNextMove:(id) sender;
- (IBAction) showPreviousMove:(id) sender;
- (IBAction) showGameStart:(id) sender;
- (IBAction) showGameEnd:(id) sender;

- (IBAction) showInfo:(id) sender;
- (IBAction) showTerritory:(id) sender;
- (IBAction) showLabels:(id) sender;

- (IBAction) reset:(id) sender;

- (BOOL) isShowingTerritory;

- (GoGame *) game;
- (void) redisplay;

- (void) setDefaultPlayers;

- (NSString *) statusString;
- (BOOL) isProgramActive;

@end
