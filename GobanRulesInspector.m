/*$Id: GobanRulesInspector.m,v 1.7 2001/10/15 17:23:42 phink Exp $*/

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

#import "GobanRulesInspector.h"
#import "GobanGameDocument.h"
#import "GobanPlayer.h"
#import "GobanGMPPlayer.h"
#import "GobanHumanPlayer.h"
#import "GobanPlayerDefaults.h"
#import <GoGame/GoGame.h>
#import <GoGame/GoSymbol.h>
#import <SenFoundation/SenFoundation.h>

#define CUSTOM_KOMI_COLUMN_INDEX 2

static float standardKomiValues[3] = {0.5, 5.5, 0.0};

@implementation GobanRulesInspector
- (id) init 
{
    [super init];
    [NSBundle loadNibNamed:@"GobanRulesInspector" owner:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultPlayersDidChange:) name:@"DefaultPlayersDidChangeNotification" object:nil];
    return self;
}


- (void) refreshKomi:(float) value
{
    int count = CUSTOM_KOMI_COLUMN_INDEX;
    int index = count;
    while (count--) {
        if (value == standardKomiValues[count]) {
            index = count;
            break;
        }
    }
    [standardKomiMatrix selectCellAtRow:0 column:index];
    if (index == CUSTOM_KOMI_COLUMN_INDEX) {
        [customKomiField setFloatValue:value];
    }
    else {
        [customKomiField setStringValue:@""];
    }
}


- (void) refreshHandicap:(int) value
{
    if (value == 0) {
        [handicapField setStringValue:NSLocalizedString(@"none", @"")];
    }
    else {
        [handicapField setIntValue:value];
    }
    [handicapStepper setIntValue:value];
}


- (void) refreshPlayButtons
{
    [playButton setEnabled:[inspectedDocument isStartOrResumeValid]];
}


- (void) fillPopup:(id) aPopup
{
    NSEnumerator *playerEnumerator = [[[GobanPlayerDefaults sharedInstance] players] reverseObjectEnumerator];
    id each;
    
    while (each = [playerEnumerator nextObject]) {
        [aPopup insertItemWithTitle:[each name] atIndex:0];
        [[aPopup itemAtIndex:0] setRepresentedObject:each];
    }
}


- (void) fillPlayerPopups
{
    [whitePopUp removeAllItems];
    [blackPopUp removeAllItems];
    if ([[inspectedDocument game] isStarted]) {
        [whitePopUp insertItemWithTitle:[[inspectedDocument game] whitePlayerName] atIndex:0];
        [blackPopUp insertItemWithTitle:[[inspectedDocument game] blackPlayerName] atIndex:0];
    }
    else {
        [self fillPopup:whitePopUp];
        [self fillPopup:blackPopUp];
    }
}


- (void) refreshOpponents
{
    [blackPopUp selectItemAtIndex:MIN([[GobanPlayerDefaults sharedInstance] defaultBlackPlayerIndex], [blackPopUp numberOfItems] - 1)];
    [whitePopUp selectItemAtIndex:MIN([[GobanPlayerDefaults sharedInstance] defaultWhitePlayerIndex], [whitePopUp numberOfItems] - 1)];
}


- (void) setEnabled:(BOOL) value
{
    [playButton setEnabled:value];
    [boardSizeSlider setEnabled:value];
    [standardKomiMatrix setEnabled:value];
    [customKomiField setEnabled:value];
    [handicapField setEnabled:value];
    [handicapStepper setEnabled:value];
    [rulesetPopUp setEnabled:NO];//value];
    [blackPopUp setEnabled:value];
    [whitePopUp setEnabled:value];
    [board7Button setEnabled:value];
    [board9Button setEnabled:value];
    [board13Button setEnabled:value];
    [board19Button setEnabled:value];
}


- (void) redisplay
{
    GoGame *game = [inspectedDocument game];
    [self setEnabled:![game isStarted]];
    [boardSizeSlider setIntValue:[game boardSize]];
    [GoGame setDefaultBoardSize:[game boardSize]];

    [self refreshKomi:[game komi]];
    [GoGame setDefaultKomi:[game komi]];

    [self refreshHandicap:[game handicap]];
    [GoGame setDefaultHandicap:[game handicap]];
    
    [self refreshPlayButtons];
    [self refreshOpponents];
}


- (IBAction) setBoardSize:(id) sender
{
    GoGame *game = [inspectedDocument game];
    int boardSize = [sender isKindOfClass:[NSButton class]] ? [[sender title] intValue] : [sender intValue];
    if (boardSize != [game boardSize]) {
        [game setBoardSize:boardSize];
    }
}


- (IBAction) setKomi:(id) sender
{
    GoGame *game = [inspectedDocument game];
    float komi = 0.0;
    if (sender == standardKomiMatrix) {
        komi = standardKomiValues[[sender selectedColumn]];
    }
    else {
        komi = [sender floatValue];
    }
    [customKomiField setEnabled:[standardKomiMatrix selectedColumn] == CUSTOM_KOMI_COLUMN_INDEX];
    if ([game komi] != komi) {
        [[inspectedDocument game] setKomi:komi];
    }
}


- (IBAction) setHandicap:(id) sender
{
    int value = [sender intValue];
    GoGame *game = [inspectedDocument game];
    if (value < 2) {
        value = 0;
    }
    if (([game boardSize] < 9) && (value > 4)) {
        value = 4;
    }
    else if (value > 9) {
        value = 9;
    }
    if ([game handicap] != value) {
        [game setHandicap:value];
    }
}


- (IBAction) setRuleset:(id) sender
{
}


- (IBAction) startOrResume:(id) sender
{
    [inspectedDocument startOrResume:sender];
}


- (void) setInspected:(GobanGameDocument *) aGobanDocument
{
    if (inspectedDocument != nil) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:[inspectedDocument game]];
    }
    if (inspectedDocument != aGobanDocument) {
        ASSIGN (inspectedDocument, aGobanDocument);
        [self fillPlayerPopups];
        if (inspectedDocument != nil) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gameDidChange:) name:nil object:[inspectedDocument game]];
            [self redisplay];
        }
        else {
            [self setEnabled:NO];
        }
    }
}


- (void) gameDidChange:(NSNotification *) aNotification
{
    [self redisplay];
}


- (IBAction) setOpponent:(id) sender
{
    [[GobanPlayerDefaults sharedInstance] setDefaultWhitePlayerIndex:[whitePopUp indexOfSelectedItem]];
    [[GobanPlayerDefaults sharedInstance] setDefaultBlackPlayerIndex:[blackPopUp indexOfSelectedItem]];
    [inspectedDocument setDefaultPlayers];
    [self redisplay];
}


- (void) defaultPlayersDidChange:(NSNotification *) aNotification
{
    [self fillPlayerPopups];
    [inspectedDocument setDefaultPlayers];
    [self redisplay];
}
@end
