/*$Id: GobanGameDocument.m,v 1.7 2001/10/05 17:44:39 phink Exp $*/

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

#import "GobanGameDocument.h"
#import "GobanPlayerDefaults.h"
#import "GobanHumanPlayer.h"
#import "GobanGnuGoPlayer.h"
#import "GobanView.h"
#import "GobanInspectorController.h"
#import "SenInterfaceValidation.h"
#import <GoGame/GoGame.h>
#import <GoGame/GoPosition.h>
#import <GoGame/GoSymbol.h>
#import <GoGame/GoGeometry.h>
#import <GoGame/GoMove.h>
#import <SenFoundation/SenFoundation.h>

@interface GobanGameDocument (Private)
- (void) setBlackPlayer:(GobanPlayer *) aPlayer;
- (void) setWhitePlayer:(GobanPlayer *) aPlayer;
- (void) setGame:(GoGame *) aGame;
- (void) finishGame;
@end


@implementation GobanGameDocument

static BOOL isNewDocumentNeeded = YES;

- (void) setDefaultPlayers
{
    [self setWhitePlayer:[[[[GobanPlayerDefaults sharedInstance] prototypeWhitePlayer] copy] autorelease]];
    [self setBlackPlayer:[[[[GobanPlayerDefaults sharedInstance] prototypeBlackPlayer] copy] autorelease]];
}


- (id)init
{
    [super init];
    if (isNewDocumentNeeded) {
        [self setGame:[[[GoGame alloc] init] autorelease]];
    }
    [self setDefaultPlayers];
    return self;
}


- (id) window
{
    return [grid window];
}


- (void) close
{
    [self finishGame];
    [super close];
}


- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];   
    RELEASE (game);
    RELEASE (whitePlayer);
    RELEASE (blackPlayer);
    RELEASE (scorer);
    [super dealloc];
}


- (id) initWithContentsOfFile:(NSString *)fileName ofType:(NSString *)fileType
{
    isNewDocumentNeeded = NO;
    [super initWithContentsOfFile:fileName ofType:fileType];
    isNewDocumentNeeded = YES;
    return self;
}


- (id)initWithContentsOfURL:(NSURL *)anURL ofType:(NSString *)docType
{
    isNewDocumentNeeded = NO;
    [super initWithContentsOfURL:anURL ofType:docType];
    isNewDocumentNeeded = YES;
    return self;
}


- (NSString *) windowNibName
{
    return @"GobanGameDocument";
}


- (GoGame *) game
{
    return game;
}


- (NSString *) applicationProperty
{
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    return [NSString stringWithFormat:@"%@:%@", 
        [infoDictionary objectForKey:@"CFBundleName"], 
        [infoDictionary objectForKey:@"CFBundleVersion"]];
}


- (void) setGame:(GoGame *) aGame
{
    if (game != nil) {
        [[NSNotificationCenter defaultCenter]  removeObserver:self];   
    }
    ASSIGN (game, aGame);
    [game setApplicationProperty:[self applicationProperty]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gameDidChange:) name:@"GoGamePositionDidChange" object:game];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gameDidChange:) name:@"GoGameScoreDidChange" object:game];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gameRulesDidChange:) name:@"GoGameRulesDidChange" object:game];
}


- (void) scoreGame
{
    scorer = [[GobanGnuGoPlayer alloc] init];
    [scorer setLaunchPath:@""];
    [scorer setLaunchArgumentString:@"--mode gtp --quiet -M 32.0"];
    [scorer setLevel:10];
    [scorer scoreGame:game];
}


- (void) gameDidChange:(NSNotification *) aNotification
{
    if ([game isOver] && ![game isResigned] && (scorer == nil)) {
        [self scoreGame];
    }
    [self redisplay];
}


- (void) gameRulesDidChange:(NSNotification *) aNotification
{
    senassert (![game isStarted]);
    [grid setGame:game];
    [grid update];
}


- (void) redisplay
{
    [grid update];
    [[self window] update];
}


- (void) windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    [aController setWindowFrameAutosaveName:@"Goban"];
    [grid setGame:game];
    [self redisplay];
}


- (BOOL) readFromFile:(NSString *)fileName ofType:(NSString *) docType
{
    [self setGame:[[[GoGame alloc] initWithContentsOfFile:fileName] autorelease]];
    [self setWhitePlayer:[[[GobanPlayerDefaults sharedInstance] playerNamed:[game whitePlayerName]] copy]];
    [self setBlackPlayer:[[[GobanPlayerDefaults sharedInstance] playerNamed:[game blackPlayerName]] copy]];

    [self startOrResume:nil];
    return YES;
}


- (BOOL) writeToFile:(NSString *)fileName ofType:(NSString *)type
{
    return [game writeToFile:fileName atomically:NO];
}


- (void) setWhitePlayer:(GobanPlayer *) aPlayer
{
    ASSIGN (whitePlayer, aPlayer);
    [whitePlayer setReferee:self];
    [game setWhitePlayerName:[whitePlayer name]]; 
}


- (void) setBlackPlayer:(GobanPlayer *) aPlayer
{
    ASSIGN (blackPlayer, aPlayer);
    [blackPlayer setReferee:self];
    [game setBlackPlayerName:[blackPlayer name]]; 
}


- (GobanPlayer *) opponentTo:(GobanPlayer *) aPlayer
{
    return (aPlayer == blackPlayer) ? whitePlayer : blackPlayer;
}


- (GobanPlayer *) nextPlayer
{
    return ([game nextColor] == [GoSymbol black]) ? blackPlayer : whitePlayer;
}


- (void) showGameOver
{
    if (![game isResigned]) {
        [grid showTerritory];
    }
    [inspector showInfo:@"Score" shouldOpenDrawer:YES];
}


- (BOOL) isProgramThinking
{
    return [game isStarted] && ![game isOver] && ![[self nextPlayer] isInteractive];
}


- (BOOL) isProgramScoring
{
    return [game isScoring];
}


- (NSString *) nextPlayerName
{
    return [[self nextPlayer] name];
}


- (void) exceptionSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
}


- (void)updateChangeCount:(NSDocumentChangeType)change
{
    if ((change > 0) && ([[NSUserDefaults standardUserDefaults] boolForKey:@"IsAskingToSaveEditedGames"])) {
        [super updateChangeCount:change];
    }
}


- (void) playerDidResign:(GobanPlayer *) aPlayer
{
    //[self updateChangeCount:1];
    [[self opponentTo:aPlayer] opponentDidResign];
    [game resign];
    if ([game isOver]) {
        [self showGameOver];
        [self finishGame];
    }
}


- (void) playerDidUndo:(GobanPlayer *) aPlayer
{
    [game undoPreviousMove];
    [game undoPreviousMove];
    [[self opponentTo:aPlayer] opponentDidUndo];
}


- (void) player:(GobanPlayer *) aPlayer didPlayMove:(GoMove *) aMove
{
    NSException *exception = [game exceptionForMove:aMove];
    if (exception != nil) {
            NSBeginAlertSheet (
                NSLocalizedString(@"Illegal Move", @""), 
                nil, 
                nil, 
                nil, 
                [self window],
                self, 
                @selector(exceptionSheetDidEnd:returnCode:contextInfo:), 
                (SEL) 0, 
                NULL, 
                [exception reason]
            );
    }
    else {
        [self updateChangeCount:1];
        [game playMove:aMove];
        [aPlayer makeSoundForMove:aMove];
        if ([game isAtari]) {
            [aPlayer signalAtari];
        }
        [[self opponentTo:aPlayer] opponentDidPlayMove:aMove];
        if ([game isOver]) {
            [self showGameOver];
            [self finishGame];
        }
    }
}


- (void) startSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSOKButton) {
        [self startOrResume:self];
    }
}


- (IBAction) playStone:(id) sender
{
    GoPoint *playedPoint = [grid selectedPoint];
    if (playedPoint != nil) {
        if (![game isReady]) {
            [game placeHandicapStoneAtPoint:playedPoint];
        }
        else if (![game isAtLastMove]) {
            [game gotoNextMove];
        }
        else if (![game isOver]) {
            GobanPlayer *player = [self nextPlayer];
            if ([player isInteractive]) {
                if (![game isStarted]) {
                    [self startOrResume:nil];
                }
                [self player:player didPlayMove:[game moveForColor:[player color] atPoint:playedPoint]];
            }
            else if (![game isStarted]) {
                NSBeginAlertSheet (
                    NSLocalizedString (@"First Move", @""), 
                    NSLocalizedString(@"Make First Move", @""), 
                    NSLocalizedString(@"Cancel", @""), 
                    nil, 
                    [self window],
                    self, 
                    @selector(startSheetDidEnd:returnCode:contextInfo:), 
                    (SEL) 0, 
                    NULL, 
                    NSLocalizedString(@"Not your turn to make first move", @"")
                );
            }
        }
        else if ([grid isShowingTerritory]) {
            [game toggleIsAliveAtPoint:playedPoint];
        }
    }
}


- (BOOL) validatePass:(id <SenValidatedUserInterfaceItem>) anItem
{
    return [game isStarted]  && ![game isOver] && [[self nextPlayer] isInteractive];
}


- (IBAction) pass:(id) sender
{
    GobanPlayer *player = [self nextPlayer];
    GoMove *move = [game passMoveForColor:[player color]];
    [self player:player didPlayMove:move];
}


- (BOOL) isResignationValid
{
    return [game isStarted]  && ![game isOver] && [[self nextPlayer] isInteractive];
}


- (BOOL) validateResign:(id <SenValidatedUserInterfaceItem>) anItem
{
    return [self isResignationValid];
}


- (void) resignSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSOKButton) {
        GobanPlayer *player = [self nextPlayer];
        [self playerDidResign:player];
    }
}


- (IBAction) resign:(id) sender
{
    NSBeginCriticalAlertSheet (
        NSLocalizedString (@"Resign", @""), 
        NSLocalizedString(@"Resign", @""), 
        NSLocalizedString(@"Cancel", @""), 
        nil, 
        [self window],
        self, 
        @selector(resignSheetDidEnd:returnCode:contextInfo:), 
        (SEL) 0, 
        NULL, 
        NSLocalizedString(@"Do you really want to resign this game?", @"")
    );
}


- (IBAction) undoMove:(id) sender
{
    [self playerDidUndo:[self nextPlayer]];
}


- (IBAction) showPreviousMove:(id) sender
{
    [game gotoPreviousMove];
}


- (IBAction) showNextMove:(id) sender
{
    [game gotoNextMove];
}


- (IBAction) showGameStart:(id) sender
{
    [game gotoStart];
}


- (IBAction) showGameEnd:(id) sender
{
    [game gotoEnd];
}


- (IBAction) startOrResume:(id) sender
{
    [whitePlayer playGame:game withColor:[GoSymbol white]];
    [blackPlayer playGame:game withColor:[GoSymbol black]];
}


- (void) finishGame
{
    [whitePlayer finishGame];
    [blackPlayer finishGame];
    RELEASE (whitePlayer);
    RELEASE (blackPlayer);
}


- (IBAction) showInfo:(id) sender
{
    [inspector toggleInfo];
}


- (BOOL) validateShowInfo:(id <SenValidatedUserInterfaceItem>) anItem
{
    return [inspector validateShowInfo:(id <SenValidatedUserInterfaceItem>) anItem];
}


- (BOOL) isShowingTerritory
{
    return [grid isShowingTerritory];
}


- (IBAction) showTerritory:(id) sender
{
    if ([grid isShowingTerritory]) {
        [grid hideTerritory];
    }
    else {
        [grid showTerritory];
    }
    [self redisplay];
}


- (IBAction) showLabels:(id) sender
{
    if ([grid isShowingLabels]) {
        [grid hideLabels];
    }
    else {
        [grid showLabels];
    }
    [self redisplay];
}


- (GobanPlayer *) whitePlayer
{
    return whitePlayer;
}


- (GobanPlayer *) blackPlayer
{
    return blackPlayer;
}


- (BOOL) validateUndoMove:(id <SenValidatedUserInterfaceItem>) anItem
{
    return [game isStarted] && ![game isOver] && [[self nextPlayer] isInteractive];
}


- (BOOL) isStartOrResumeValid
{
    return (![game isStarted]) && (![[self nextPlayer] isInteractive]) && (![[self nextPlayer] isPlaying]);
}


- (BOOL) validateStartOrResume: (id <SenValidatedUserInterfaceItem>) anItem
{
    return [self isStartOrResumeValid];
}


- (BOOL) validateShowTerritory: (id <SenValidatedUserInterfaceItem>) anItem
{
    [anItem setTitle:NSLocalizedString (([grid isShowingTerritory]) ? @"Hide Territories" : @"Show Territories", @"")];
    return [game isOver] && ![game isResigned];
}


- (BOOL) validateShowLabels: (id <SenValidatedUserInterfaceItem>) anItem
{
    [anItem setTitle:NSLocalizedString (([grid isShowingLabels]) ? @"Hide Labels" : @"Show Labels", @"")];
    return YES;
}


- (BOOL) validateUserInterfaceItem: (id <SenValidatedUserInterfaceItem>) anItem
{
    SEL action = [anItem action];
    if (action != 0) {
        NSString *actionSelectorString = NSStringFromSelector(action);
        NSString *validationSelectorString = [NSString stringWithFormat:@"validate%@%@", 
                [[actionSelectorString substringToIndex:1] capitalizedString], 
                [actionSelectorString substringFromIndex:1]];
        SEL validationSelector = NSSelectorFromString(validationSelectorString);
        if ([self respondsToSelector:validationSelector]) {
            return ([self performSelector:validationSelector withObject:anItem] != nil);
        }
    }
    return [super validateUserInterfaceItem:anItem];
}


- (void) reset
{
    [inspector setInspected:nil];
    [self finishGame];
    RELEASE (scorer);
    [self setGame:[[[GoGame alloc] init] autorelease]];
    [self setDefaultPlayers];
    [game rulesChanged];
    [inspector setInspected:self];
    [inspector showInfo:@"Rules" shouldOpenDrawer:NO];
    [grid setGame:game];
}


- (void) resetSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSOKButton) {
        [self reset];
    }
}


- (IBAction) reset:(id) sender
{
    if ([self isResignationValid]) {
        NSBeginCriticalAlertSheet (
            NSLocalizedString (@"Resign", @""), 
            NSLocalizedString(@"Resign", @""), 
            NSLocalizedString(@"Cancel", @""), 
            nil, 
            [self window],
            self, 
            @selector(resetSheetDidEnd:returnCode:contextInfo:), 
            (SEL) 0, 
            NULL, 
            NSLocalizedString(@"Do you really want to resign this game?", @"")
        );
    }
    else {
        [self reset];
    }
}


- (void) windowDidResize:(NSNotification *)notification
{
    if ([notification object] == [self window]) {
        [inspector resize];
    }
}


- (BOOL) windowShouldZoom:(NSWindow *)sender toFrame:(NSRect)newFrame
{
    return YES;
}


- (NSRect)windowWillUseStandardFrame:(NSWindow *)sender defaultFrame:(NSRect)defaultFrame
{
    return NSMakeRect (defaultFrame.origin.x, defaultFrame.origin.y, defaultFrame.size.height / 1.1, defaultFrame.size.height);
}


- (NSSize) windowWillResize:(NSWindow *)sender toSize:(NSSize)proposedFrameSize
{
    return proposedFrameSize;
    /*
    NSRect proposedRect = NSMakeRect (0, 0, proposedFrameSize.width, proposedFrameSize.height);
    NSRect contentRect = [NSWindow contentRectForFrameRect:proposedRect styleMask:[sender styleMask]];
    NSSize adjustedContentSize = [grid windowWillResizeToSize:contentRect.size];
    NSRect adjustedContentRect = NSMakeRect (0, 0, adjustedContentSize.width, adjustedContentSize.height);
    return [NSWindow frameRectForContentRect:adjustedContentRect styleMask:[sender styleMask]].size;
    */
}


- (BOOL) isProgramActive
{
    return [self isProgramScoring] || [self isProgramThinking];
}


- (NSString *) statusString
{
    if ([game isOver]) {
        if ([game isScoring]) {
            return NSLocalizedString(@"Scoring in progress", @"");
        }
        else if ([game isResigned]) {
            return NSLocalizedString([game scoreString], @"");
        }
        else {
            GoPosition *position = [game scorePosition];
            float whiteScore = [position whiteScore];
            float blackScore = [position blackScore];
            if (whiteScore > blackScore) {
                return [NSString stringWithFormat:NSLocalizedString(@"White wins by %.1f", @""), whiteScore - blackScore];
            }
            else if (blackScore > whiteScore) {
                return [NSString stringWithFormat:NSLocalizedString(@"Black wins by %.1f", @""), blackScore - whiteScore];
            }
            else {
                return NSLocalizedString(@"Tie game", @"");
            }
        }
    }
    else if ([self isProgramThinking]) {
        return [NSString stringWithFormat:NSLocalizedString(@"%@ thinking", @""), [self nextPlayerName]];
    }
    else {
        return [NSString stringWithFormat:NSLocalizedString(@"%@'s turn", @""), [self nextPlayerName]];
    }
}

@end
