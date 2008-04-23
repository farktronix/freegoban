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

#import "GoGameTree.h"

@implementation GoGameTree
- (id) initWithGame:(GoGame *) aGame contentsOfFile:(NSString *)aPath
{
    SGFTree *tree = NULL;
    FILE *sgffile = fopen([aPath cString], "r");
    
    if (sgffile != NULL) {
        tree = sgf_parse (sgffile);
        fclose(sgffile);
    }

    if (tree != NULL) {
        [self initWithGame:aGame node:tree->first_child];
        return self;
    }
    else {
        // raise?
    }
    return nil;
}


- initWithGame:(GoGame *) aGame node:(SGFTree *) aNode
{
    if (aNode == NULL) {
        aNode = sgf_create_leaf();
    }

    [super initWithGame:aGame node:aNode];
    game = aGame;
    return self;
}


- (GoGame *) game
{
    return game;
}


- (BOOL) writeToFile:(NSString *) path
{
    FILE *sgffile = fopen([path cString], "w");
    if (sgffile != NULL) {
        SGFTree *collection = node->parent;
        if (collection == NULL) {
            collection = sgf_create_leaf();
            sgf_add_subtree_first(node, collection);
        }
        sgf_dump_collection (collection, sgffile);
        fclose (sgffile);
        return YES;
    }
    return NO;
}

@end
