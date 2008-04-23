/*$Id: GobanScoreInspector.h,v 1.3 2001/10/02 16:14:44 phink Exp $*/

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

#import "GobanInspector.h"

@interface GobanScoreInspector : GobanInspector
{
    IBOutlet NSTextField *resultField;
    IBOutlet NSTextField *whiteScoreField;
    IBOutlet NSTextField *blackScoreField;
    IBOutlet NSTextField *whiteTerritoryCountField;
    IBOutlet NSTextField *blackTerritoryCountField;
    IBOutlet NSTextField *whiteCapturedCountField;
    IBOutlet NSTextField *blackCapturedCountField;
    IBOutlet NSTextField *whiteSurroundedCountField;
    IBOutlet NSTextField *blackSurroundedCountField;
    IBOutlet NSTextField *whiteKomi;
    IBOutlet NSButton *showTerritoryButton;
}


- (IBAction) showTerritory:(id) sender;

@end
