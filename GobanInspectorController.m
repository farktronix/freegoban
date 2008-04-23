/*$Id: GobanInspectorController.m,v 1.4 2001/10/15 17:22:26 phink Exp $*/

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

#import "GobanInspectorController.h"
#import "GobanGamedocument.h"
#import "GobanRulesInspector.h"
#import "GobanMoveInspector.h"
#import "GobanScoreInspector.h"
#import <GoGame/GoGame.h>
#import "SenInterfaceValidation.h"
#import <SenFoundation/SenFoundation.h>

@interface NSDrawer (IsOpen)
- (BOOL) isOpen;
@end

@implementation NSDrawer (IsOpen)
- (BOOL) isOpen
{
    return (([self state] == NSDrawerOpeningState) || ([self state] == NSDrawerOpenState));
}
@end


@implementation GobanInspectorController

- (void) setInspected:(id) aDocument
{
    [allPanels makeObjectsPerformSelector:@selector(setInspected:) withObject:aDocument];
}


- (void) awakeFromNib
{
    NSString *listPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"Inspectors" ofType:@"plist"];
    NSDictionary *listDictionary = [NSDictionary dictionaryWithContentsOfFile:listPath];
    NSEnumerator *panelEnumerator = [[listDictionary objectForKey:@"InspectorPanels"] objectEnumerator];
    id each;
    int index = 0;
    
    while (each = [panelEnumerator nextObject]) {
        NSTabViewItem *item = [[[NSTabViewItem alloc] initWithIdentifier:[each objectForKey:@"identifier"]] autorelease];
        GobanInspector *panel = [[[NSClassFromString([each objectForKey:@"class"]) alloc] init] autorelease];
        [allPanels addObject:panel];
        [item setView:[panel view]];
        [tabView insertTabViewItem:item atIndex:index++];
    }
    [self setInspected:document];
    [tabView selectTabViewItemAtIndex:0]; 
}


- (id) init 
{
    [super init];
    allPanels = [[NSMutableArray alloc] init];
    return self;
}


- (void) dealloc
{
    RELEASE (allPanels);
    [super dealloc];
}


- (BOOL) validateShowInfo:(id <SenValidatedUserInterfaceItem>) anItem
{
    [anItem setTitle:[drawer isOpen] ? NSLocalizedString (@"Hide Info", @"") : NSLocalizedString (@"Show Info", @"")];
    return YES;
}


- (id) contextualIdentifier
{
    if (![[document game] isStarted]) {
        return @"Rules";
    }
    else if ([[document game] isOver]) {
        return @"Score";
    }
    else {
        return @"Moves";
    }
}


- (void) showInfo:(id) identifier shouldOpenDrawer:(BOOL) shouldOpenDrawer
{
    if (shouldOpenDrawer && ![drawer isOpen]) {
        [drawer open];
    }
    if ([drawer isOpen]) {
        identifier = (identifier != nil) ? identifier : [self contextualIdentifier];
        [tabView selectTabViewItemWithIdentifier:identifier];
        [popUp selectItemAtIndex:[tabView indexOfTabViewItem:[tabView selectedTabViewItem]]];
    }
}



- (void) toggleInfo
{
    [drawer toggle:self];
    [self showInfo:nil shouldOpenDrawer:NO];
}


- (NSSize) drawerSize
{
    return NSMakeSize (280, 383);
}


- (void) resizeForParentSize:(NSSize) parentSize
{
    float windowHeight = parentSize.height;
    float drawerHeight = [self drawerSize].height;
    float emptyHeight = windowHeight - drawerHeight;
        
    [drawer setContentSize:[self drawerSize]];
    [drawer setLeadingOffset:emptyHeight / 3.0];
    [drawer setTrailingOffset:emptyHeight * (2.0 / 3.0)];
}


- (void) resize
{
    NSWindow *parent = [drawer parentWindow];
    [self resizeForParentSize:[NSWindow contentRectForFrameRect:[parent frame] styleMask:[parent styleMask]].size];
}


- (BOOL) drawerShouldOpen:(NSDrawer *)sender
{
    [self resize];
    return YES;
}
@end
