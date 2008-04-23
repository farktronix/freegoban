/*$Id: GobanScoreInspector.m,v 1.5 2001/10/04 16:13:54 phink Exp $*/

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

#import "GobanScoreInspector.h"
#import "GobanGameDocument.h"
#import <GoGame/GoGame.h>
#import <GoGame/GoSymbol.h>
#import <GoGame/GoMove.h>
#import <GoGame/GoPosition.h>
#import <SenFoundation/SenFoundation.h>

@implementation GobanScoreInspector
- (void) setEmpty
{
    [resultField setStringValue:@""];
    [whiteScoreField setStringValue:@""];
    [blackScoreField setStringValue:@""];
    [whiteTerritoryCountField setStringValue:@""];
    [blackTerritoryCountField setStringValue:@""];
    [whiteCapturedCountField setStringValue:@""];
    [blackCapturedCountField setStringValue:@""];
    [whiteSurroundedCountField setStringValue:@""];
    [blackSurroundedCountField setStringValue:@""];
    [whiteKomi setStringValue:@""];
    [showTerritoryButton setEnabled:NO];
}


- (void) refreshTerritoryButton
{
    GoGame *game = [inspectedDocument game];
    [showTerritoryButton setEnabled:[game isOver] && ![game isResigned]];
    [showTerritoryButton setTitle:NSLocalizedString(([inspectedDocument isShowingTerritory]) ? @"Hide Territories" : @"Show Territories", @"")];
}


- (void) redisplay
{
    GoGame *game = [inspectedDocument game];

    [whiteKomi setFloatValue:[game komi]];
    [self refreshTerritoryButton];
    [resultField setStringValue:[inspectedDocument statusString]];

    if ([game isStarted]) {
        GoPosition *position = [game currentPosition];
        [whiteCapturedCountField setIntValue:[position blackCapturedCount]];
        [blackCapturedCountField setIntValue:[position whiteCapturedCount]];
    }
    else {
        [whiteCapturedCountField setStringValue:@"..."];
        [blackCapturedCountField setStringValue:@"..."];
    }
    if ([game isOver] && ![game isResigned]) {
        GoPosition *position = [game scorePosition];
        float whiteScore = [position whiteScore];
        float blackScore = [position blackScore];
        [whiteScoreField setFloatValue:whiteScore];
        [blackScoreField setIntValue:blackScore];
        [whiteTerritoryCountField setIntValue:[position whiteTerritoryCount]];
        [blackTerritoryCountField setIntValue:[position blackTerritoryCount]];
        [whiteSurroundedCountField setIntValue:[position blackPrisonerCount]];
        [blackSurroundedCountField setIntValue:[position whitePrisonerCount]];
    }
    else {
        [whiteScoreField setStringValue:@"..."];
        [blackScoreField setStringValue:@"..."];
        [whiteTerritoryCountField setStringValue:@"..."];
        [blackTerritoryCountField setStringValue:@"..."];
        [whiteSurroundedCountField setStringValue:@"..."];
        [blackSurroundedCountField setStringValue:@"..."];
    }
}


- (void) setInspected:(GobanGameDocument *) aGobanDocument
{
    if (inspectedDocument != aGobanDocument) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        ASSIGN (inspectedDocument, aGobanDocument);
        if (inspectedDocument != nil) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gameDidChange:) name:nil object:[inspectedDocument game]];
            [self redisplay];
        }
        else {
            [self setEmpty];
        }
    }
}


- (void) gameDidChange:(NSNotification *) aNotification
{
    [self redisplay];
}


- (IBAction) showTerritory:(id) sender
{
    [inspectedDocument showTerritory:sender];
    [self refreshTerritoryButton];
}
@end
