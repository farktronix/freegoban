/*$Id: GobanPreferenceController.m,v 1.4 2001/10/04 16:12:48 phink Exp $*/

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

#import "GobanPreferenceController.h"
#import "GobanPreferences.h"
#import "GobanPlayer.h"
#import "GobanPlayerDefaults.h"
#import <SenFoundation/SenFoundation.h>


@implementation GobanPreferenceController
+ sharedInstance
{
    static id sharedInstance = nil;
    if (sharedInstance == nil) {
        sharedInstance = [[self alloc] init];
    }
    return sharedInstance;
}


- (void) refresh
{
    NSEnumerator *panelEnumerator = [allPanels objectEnumerator];
    id each;
    while (each = [panelEnumerator nextObject]) {
        [each refresh];
    }
}


- (id) init
{
    [super initWithWindowNibName:@"GobanPreferenceController"];
    allPanels = [[NSMutableArray alloc] init];
    return self;
}


- (void) awakeFromNib
{
    NSString *listPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"Preferences" ofType:@"plist"];
    NSDictionary *listDictionary = [NSDictionary dictionaryWithContentsOfFile:listPath];
    NSEnumerator *panelEnumerator = [[listDictionary objectForKey:@"PreferencePanels"] objectEnumerator];
    id each;
    int index = 0;
    
    while (each = [panelEnumerator nextObject]) {
        NSTabViewItem *item = [[[NSTabViewItem alloc] initWithIdentifier:[each objectForKey:@"identifier"]] autorelease];
        GobanPreferences *panel = [NSClassFromString([each objectForKey:@"class"]) preferences];
        [allPanels addObject:panel];
        [item setView:[panel view]];
        [tabView insertTabViewItem:item atIndex:index++];
    }
    [tabView selectTabViewItemAtIndex:0]; 
    [self setWindowFrameAutosaveName:@"GobanPreferences"];
}


- (void) windowDidLoad
{
    [super windowDidLoad];
    [self refresh];
}


- (IBAction) showWindow:(id)sender
{
    [self refresh];
    [super showWindow:sender];
}


- (void) close
{
    [allPanels makeObjectsPerformSelector:@selector(close)];
    [super close];
}
@end
