/*$Id: GobanGoke.h,v 1.3 2001/10/02 16:20:14 phink Exp $*/

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

#import <AppKit/AppKit.h>
#import <GoGame/GoSymbol.h>

#define STYLE_COUNT 12

@interface GoSymbol (Goke)
- (NSImage *) imageOfSize:(int) aSize;
- (NSImage *) imageOfSize:(int) aSize style:(int) aStyle;
@end


@interface GobanGoke : NSObject 
{
    NSMutableDictionary *cache;
}

+ (id) sharedInstance;
- (NSImage *) stoneOfSize:(int) aSize style:(int) aStyle;
@end
