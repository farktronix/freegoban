/*$Id: GobanToolbar.m,v 1.4 2001/10/04 16:14:14 phink Exp $*/

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

#import "GobanToolbar.h"
#import "GobanProgressItem.h"

@implementation GobanToolbar

- (void) addStandardItemNamed:(NSString *) aName
{
    [items setObject:[[[NSToolbarItem alloc] initWithItemIdentifier:aName] autorelease] forKey:aName];
}


- (void) addDefaultItems
{
    NSDictionary *defaultToolbar = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"Toolbar"];
    
    if (defaultToolbar != nil) {
        NSEnumerator *keyEnumerator = [defaultToolbar keyEnumerator];
        NSString *each;
        
        while (each = [keyEnumerator nextObject]) {
            NSToolbarItem *item = [[[NSToolbarItem alloc] initWithItemIdentifier:each] autorelease];
            NSImage *image = [NSImage imageNamed:each];
            [item setPaletteLabel:each];
            [item setLabel:each];
            if (image != nil) {
                [item setImage:image];
            }
            [item setTarget:document];
            [item setAction:NSSelectorFromString ([defaultToolbar objectForKey:each])];
            [items setObject:item forKey:each];
        }
        {
            GobanProgressItem *item = [[[GobanProgressItem alloc] initWithItemIdentifier:@"Status"] autorelease];
            [item setPaletteLabel:@"Status"];
            [item setLabel:@"Status"];
            [item setView:progressView];
            [item setMinSize:[progressView frame].size];
            [item setMaxSize:[progressView frame].size];
            [items setObject:item forKey:@"Status"];
        }
    }
}


- (void) awakeFromNib 
{
    items = [[NSMutableDictionary alloc] init];
    
    [self addDefaultItems];
    [self addStandardItemNamed:NSToolbarSeparatorItemIdentifier];
    [self addStandardItemNamed:NSToolbarSpaceItemIdentifier];
    [self addStandardItemNamed:NSToolbarFlexibleSpaceItemIdentifier];
    
    toolbar = [[NSToolbar alloc] initWithIdentifier:@"GobanGameDocumentToolbar"];
    [toolbar setDelegate:self];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
    
    [window setToolbar:toolbar];
}


- (void) dealloc 
{
    [toolbar release];
    [items release];
    [super dealloc];
}


- (NSToolbarItem *) toolbar:(NSToolbar *) toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    return [items objectForKey:itemIdentifier];
}


- (NSArray *) toolbarDefaultItemIdentifiers:(NSToolbar*) toolbar 
{
    return [NSArray arrayWithObjects:
        @"Play", @"Pass", @"Undo", @"Resign", 
        NSToolbarSeparatorItemIdentifier, 
        @"Info", NSToolbarFlexibleSpaceItemIdentifier, 
        @"Status", 
        nil]; 
}


- (NSArray *) toolbarAllowedItemIdentifiers:(NSToolbar*) toolbar 
{
    return [items allKeys];
}


- (int) count 
{
    return [items count];
}


- (GobanGameDocument *) document
{
    return document;
}
@end
