/*$Id: GobanPlayersPreferences.m,v 1.2 2001/10/04 16:15:09 phink Exp $*/

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

#import "GobanPlayersPreferences.h"
#import "GobanPlayerDefaults.h"
#import "GobanPlayer.h"
#import "GobanHumanPlayer.h"
#import "GobanGTPPlayer.h"
#import "GobanGMPPlayer.h"
#import "GobanGnuGoPlayer.h"
#import "GobanPlayerEditor.h"
#import <SenFoundation/SenFoundation.h>

@interface GobanPlayer (Preferences)
- (NSString *) playerEditorClassName;
@end


@implementation GobanPlayer (Preferences)
- (NSString *) playerEditorClassName
{
    return nil;
}
@end


@implementation GobanProgramPlayer (Preferences)
- (NSString *) playerEditorClassName
{
    return @"GobanProgramPlayerEditor";
}
@end


@implementation GobanGnuGoPlayer (Preferences)
- (NSString *) playerEditorClassName
{
    return @"GobanGnuGoPlayerEditor";
}
@end


@implementation GobanPlayersPreferences

- (void) refresh
{
    [playerTableView reloadData];
    if ([playerTableView selectedRow] < 0) {
        [playerTableView selectRow:0 byExtendingSelection:NO];
    }
}


- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
    NSArray *players = [[GobanPlayerDefaults sharedInstance] players];
    id player = [players objectAtIndex:rowIndex];
    return [player valueForKey:[aTableColumn identifier]];
}


- (void) tableView:(NSTableView *) aTableView setObjectValue:(id) anObject forTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
    NSArray *players = [[GobanPlayerDefaults sharedInstance] players];
    id player = [players objectAtIndex:rowIndex];
    [player takeValue:anObject forKey:[aTableColumn identifier]];
    [self apply:nil];
}


- (int) numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [[[GobanPlayerDefaults sharedInstance] players] count];
}


- (IBAction) apply:(id) sender
{
    [detailEditor apply:sender];
    [[GobanPlayerDefaults sharedInstance] saveDefaultPlayers];
}


- (void) swapDetailView
{
    NSString *editorClassName = [selectedPlayer playerEditorClassName];
    if (detailEditor != nil) {
        [detailEditor apply:nil];
        [[detailEditor view] removeFromSuperview];
    }
    if (!isNilOrEmpty(editorClassName)) {
        id editor = [NSClassFromString(editorClassName) sharedInstance];
        if ((editor != nil) && [editor view]) {
            ASSIGN (detailEditor, editor);
            [detailEditor setPlayer:selectedPlayer];
            [detailViewContainer addSubview:[detailEditor view]];
        }
    }
}


- (void) selectPlayer:(GobanPlayer *) aPlayer
{
    ASSIGN (selectedPlayer, aPlayer);
    [deletePlayerButton setEnabled:![selectedPlayer isBuiltIn]];
    [self swapDetailView];
}


- (void) tableViewSelectionDidChange:(NSNotification *) aNotification
{
    if ([playerTableView selectedRow] >= 0) {
        [self selectPlayer:[[[GobanPlayerDefaults sharedInstance] players] objectAtIndex:[playerTableView selectedRow]]];
    }
}


- (IBAction) addPlayer:sender;
{
    GobanPlayer *newPlayer = nil;
    switch ([sender indexOfSelectedItem]) {
        case 1:
            newPlayer = [GobanHumanPlayer player];
            break;
        case 2:
            newPlayer = [GobanGTPPlayer player];
            break;
        case 3:
            newPlayer = [GobanGMPPlayer player];
            break;
        default:
            newPlayer = nil;
            break;
    }
    if (newPlayer != nil) {
        [[GobanPlayerDefaults sharedInstance] addPlayer:newPlayer];
        [self refresh];
        [playerTableView selectRow:[playerTableView numberOfRows] - 1 byExtendingSelection:NO];
    }
}


- (IBAction) removePlayer:sender
{
    if ((selectedPlayer != nil) && ![selectedPlayer isBuiltIn]) {
        [[GobanPlayerDefaults sharedInstance] removePlayer:selectedPlayer];
        [self refresh];
        [playerTableView selectRow:[playerTableView numberOfRows] - 1 byExtendingSelection:NO];
    }
}
@end
