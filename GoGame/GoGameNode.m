/*$Id: GoGameNode.m,v 1.4 2001/11/09 22:25:31 phink Exp $*/

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

#import "GoGameNode.h"
#import "GoGame.h"
#import "GoMove.h"
#import "GoGeometry.h"
#import "GoPoint.h"
#import <SenFoundation/SenFoundation.h>

#define CHILD(x) (x->first_child)
#define SIBLING(x) (x->next_sibling)

@interface NSString (SGFExtensions)
- (SGFPropertyID) propertyID;
@end

@implementation NSString (SGFExtensions)
- (SGFPropertyID) propertyID
{
    return sgf_property_id_with_name([self cStringUsingEncoding:NSUTF8StringEncoding]);
}
@end



@implementation GoGameNode

+ (void) initialize
{
    sgf_set_compatibility_mode (SGF_COMPAT_ACCEPT_FF3 | SGF_COMPAT_ACCEPT_UNKNOWN);
}


- initWithGame:(GoGame *) aGame
{
    [self initWithGame:aGame node:NULL];
    return self;
}


- initWithGame:(GoGame *) aGame node:(SGFTree *) aNode
{
    [super init];
    node = aNode;
    return self;
}


- (void) dealloc
{
    RELEASE (child);
    RELEASE (sibling);
    //free (node);
    [super dealloc];
}


- (void) setParent:(GoGameNode *) aParent
{
    parent = aParent;
}


- (Class) classForNode:(SGFTree *) aNode
{
    if (sgf_get_property(aNode, SGF_PROP_B) || sgf_get_property(aNode, SGF_PROP_W)) {
        return [GoMove class];
    }
    return [GoGameNode class];
}


- (void) cacheChild
{
    child = [[[self classForNode:CHILD(node)] alloc] initWithGame:[self game] node:CHILD(node)];
    [child setParent:self];
}


- (void) cacheSibling
{
    sibling = [[[self classForNode:SIBLING(node)] alloc] initWithGame:[self game] node:SIBLING(node)];
    [sibling setParent:parent];
}


- (id) child
{
    if ((child == nil) && (CHILD(node) != NULL)) {
        [self cacheChild];
    }
    return child;
}


- (id) parent
{
    return parent;
}


- (id) sibling
{
    if ((sibling == nil) && (SIBLING(node) != NULL)) {
        [self cacheSibling];
    }
    return sibling;
}


- (void) addFirstChild:(GoGameNode *) aChild
{
    sgf_add_subtree_first(aChild->node, node);
    ASSIGN (child, aChild);
    [aChild setParent:self];
}


- (void) removeChildren
{
    // Quick hack, needs to be fixed.
    if ([self child] != nil) {
        [child setParent:nil];
        sgf_delete_subtree (CHILD(node));
        CHILD(node) = NULL;
        ASSIGN (child, nil);
    }
}


- (BOOL) isRoot
{
    return [self parent] == nil;
}


- (BOOL) isLeaf
{
    return [self child] == nil;
}


- (GoGame *) game
{
    return [parent game];
}


- (void) removeValueForKey:(NSString *) aKey
{
    SGFPropertyID propertyID = [aKey propertyID];
    SGFProperty *property = sgf_get_property (node, propertyID);
    if (property != NULL) {
        sgf_delete_property (node, propertyID);
    }
}


- (NSString *) stringValueForKey:(NSString *) aKey
{
    SGFProperty *property = sgf_get_property (node, [aKey propertyID]);
    if (property != NULL) {
        return [NSString stringWithCString:property->value.value.text];
    }
    return nil;
}


- (void) setStringValue:(NSString *) aString forKey:(NSString *) aKey
{
    [self removeValueForKey:aKey];
    sgf_set_property(node, [aKey propertyID], SGF_VALUE_TYPE_TEXT, [aString cStringUsingEncoding:NSUTF8StringEncoding]);
}


- (NSCalendarDate *) dateValueForKey:(NSString *) aKey
{
    return nil;
}


- (void) setDateValue:(NSCalendarDate *) aDate forKey:(NSString *) aKey
{
    [self setStringValue:[aDate descriptionWithCalendarFormat:@"%Y-%m-%d"] forKey:aKey];
}


- (int) intValueForKey:(NSString *) aKey
{
    SGFProperty *property = sgf_get_property (node, [aKey propertyID]);
    if (property != NULL) {
        return property->value.value.int_val;
    }

    return 0; // should raise
}


- (void) setIntValue:(int) aValue forKey:(NSString *) aKey
{
    [self removeValueForKey:aKey];
    sgf_set_property(node, [aKey propertyID], SGF_VALUE_TYPE_INT, aValue);
}


- (float) floatValueForKey:(NSString *) aKey
{
    SGFProperty *property = sgf_get_property (node, [aKey propertyID]);
    if (property != NULL) {
        return property->value.value.real_val;
    }

    return 0.0; // should raise
}


- (void) setFloatValue:(float) aValue forKey:(NSString *) aKey
{
    [self removeValueForKey:aKey];
    sgf_set_property (node, [aKey propertyID], SGF_VALUE_TYPE_REAL, aValue);
}


- (NSArray *) pointValuesForKey:(NSString *) aKey
{
    NSMutableArray *points = [NSMutableArray array];
    int boardSize = [[self game] boardSize]; 
    SGFProperty *property = sgf_get_property (node, [aKey propertyID]);
    if (property != NULL) {
        struct sgf_value_list *list = property->value.value.list;
        while (list != NULL) {
            [points addObject:[GoPoint pointWithSGFPoint:MakeIntPoint (list->value.value.point.x, list->value.value.point.y) 
                    boardSize:boardSize]];
            list = list->next;
        }
    }
    return points;
}


- (void) addPointValue:(GoPoint *) aPoint forKey:(NSString *) aKey
{
    IntPoint sgfPoint = [aPoint sgfPointValue];
    sgf_add_to_list_create (node, [aKey propertyID], SGF_VALUE_TYPE_POINT, sgfPoint.x, sgfPoint.y);
}



- (NSString *) comments
{
    return [self stringValueForKey:@"C"];
}


- (void) setComments:(NSString *) aComment
{
    [self setStringValue:aComment forKey:@"C"];
}


- (BOOL) isMove
{
    return (sgf_get_property(node, SGF_PROP_B) || sgf_get_property(node, SGF_PROP_W));
}


- (GoGameNode *) previousMove
{
    GoGameNode *currentNode = [self parent];
    while ((currentNode != nil) && ![currentNode isMove]) {
        currentNode = [currentNode parent];
    }
    return currentNode;
}


- (GoGameNode *) nextMove
{
    GoGameNode *currentNode = [self child];
    while ((currentNode != nil) && ![currentNode isMove]) {
        currentNode = [currentNode child];
    }
    return currentNode;
}


- (BOOL) isFirstMove
{
    return [self previousMove] == nil;
}


- (BOOL) isLastMove
{
    return [self nextMove] == nil;
}


- (SGFTree *) node
{
    return node;
}


- (NSString *) description
{
    return [NSString stringWithFormat:@"%@\n  %@", [self class], [self child]];
}
@end
