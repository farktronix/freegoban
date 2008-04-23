/*$Id: GobanRulesInspector.h,v 1.4 2001/10/04 16:13:10 phink Exp $*/

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
#import "GobanInspector.h"

@interface GobanRulesInspector : GobanInspector
{
    IBOutlet NSSlider *boardSizeSlider;
    IBOutlet NSMatrix *standardKomiMatrix;
    IBOutlet NSTextField *customKomiField;
    IBOutlet NSTextField *handicapField;
    IBOutlet NSStepper *handicapStepper;
    IBOutlet NSPopUpButton *rulesetPopUp;
    IBOutlet NSButton *playButton;
    IBOutlet NSPopUpButton *blackPopUp;
    IBOutlet NSPopUpButton *whitePopUp;
    IBOutlet NSButton *board7Button;
    IBOutlet NSButton *board9Button;
    IBOutlet NSButton *board13Button;
    IBOutlet NSButton *board19Button;
}

- (IBAction) setBoardSize:(id) sender;
- (IBAction) setKomi:(id) sender;
- (IBAction) setHandicap:(id) sender;
- (IBAction) setRuleset:(id) sender;
- (IBAction) setOpponent:(id) sender;

- (IBAction) startOrResume:(id) sender;
@end
