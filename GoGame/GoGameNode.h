/*$Id: GoGameNode.h,v 1.2 2001/10/10 20:10:33 phink Exp $*/

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

#import <Foundation/Foundation.h>
#import "sgf.h"

@class GoGame;
@class GoPoint;

@interface GoGameNode : NSObject 
{
    SGFTree *node;
    GoGameNode *child;
    GoGameNode *parent;
    GoGameNode *sibling;
}

- initWithGame:(GoGame *) aGame;
- initWithGame:(GoGame *) aGame node:(SGFTree *) aNode;

- (id) child;
- (id) parent;
- (id) sibling;

- (void) addFirstChild:(GoGameNode *) aChild;
- (void) removeChildren;

- (BOOL) isRoot;
- (BOOL) isLeaf;

- (GoGame *) game;

- (NSString *) comments;
- (void) setComments:(NSString *) aComment;

- (int) intValueForKey:(NSString *) aKey;
- (void) setIntValue:(int) aValue forKey:(NSString *) aKey;

- (float) floatValueForKey:(NSString *) aKey;
- (void) setFloatValue:(float) aValue forKey:(NSString *) aKey;

- (NSString *) stringValueForKey:(NSString *) aKey;
- (void) setStringValue:(NSString *) aString forKey:(NSString *) aKey;

- (NSCalendarDate *) dateValueForKey:(NSString *) aKey;
- (void) setDateValue:(NSCalendarDate *) aDate forKey:(NSString *) aKey;

- (NSArray *) pointValuesForKey:(NSString *) aKey;
- (void) addPointValue:(GoPoint *) aPoint forKey:(NSString *) aKey;

- (void) removeValueForKey:(NSString *) aKey;

- (BOOL) isMove;
- (SGFTree *) node;

- (GoGameNode *) previousMove;
- (GoGameNode *) nextMove;
- (BOOL) isFirstMove;
- (BOOL) isLastMove;

@end
