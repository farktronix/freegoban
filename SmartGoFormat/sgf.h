/*              Copyright (C) Antti Huima & Mika Kojo 1998, 1999

  $Id: sgf.h,v 1.2 2001/10/02 16:09:05 phink Exp $

  THIS FILE IS PART OF THE GO MACHINE PROJECT AND IS DISTRIBUTED UNDER CERTAIN
  CONDITIONS. PLEASE READ THE ACCOMPANYING LICENSE. BY COMPILING, DISTRIBUTING
  OR OTHERWISE USING THIS SOURCE CODE YOU IMPLICITLY ACCEPT THE LICENSING
  TERMS. ALL RIGHTS ARE RESERVED BY THE AUTHORS.

  */

/*
  sgf.h

  Author: Antti Huima <huima@ssh.fi>

  Copyright (C) 1999 Antti Huima.

  */

#ifndef SGF_H_INCLUDED
#define SGF_H_INCLUDED

#ifdef __cplusplus
extern "C" {
#endif

#include <stdio.h>
#include <stdarg.h>

/* Compatibility flags; OR some of these together to get a
   compatibility mode. */

#define SGF_COMPAT_NONE			0x0000
#define SGF_COMPAT_FF3_IDS		0x0001 /* Understand LC char IDs */
#define SGF_COMPAT_ACCEPT_UNKNOWN	0x0002 /* Do not barf on unknown ID */
#define SGF_COMPAT_DISCARD_UNKNOWN	0x0004 /* Kill props w/ unknown IDs */
#define SGF_COMPAT_ACCEPT_FF3		0x0008 /* Allow FF[3] */
#define SGF_COMPAT_ACCEPT_FF2		0x0010 /* Allow FF[2] */
#define SGF_COMPAT_ACCEPT_FF1		0x0020 /* Allow FF[1] */

/* These are the legal SGF property identifiers. */
typedef enum
{
  SGF_PROP_UNKNOWN,

  SGF_PROP_AB, SGF_PROP_AE, SGF_PROP_AN, SGF_PROP_AP, SGF_PROP_AR,
  SGF_PROP_AW, SGF_PROP_B, SGF_PROP_BL, SGF_PROP_BM, SGF_PROP_BR,
  SGF_PROP_BT, SGF_PROP_C, SGF_PROP_CA, SGF_PROP_CP, SGF_PROP_CR,
  SGF_PROP_DD, SGF_PROP_DM, SGF_PROP_DO, SGF_PROP_DT, SGF_PROP_EV,
  SGF_PROP_FF, SGF_PROP_FG, SGF_PROP_GB, SGF_PROP_GC, SGF_PROP_GM,
  SGF_PROP_GN, SGF_PROP_GW, SGF_PROP_HA, SGF_PROP_HO, SGF_PROP_IT,
  SGF_PROP_KM, SGF_PROP_KO, SGF_PROP_LB, SGF_PROP_LN, SGF_PROP_MA,
  SGF_PROP_MN, SGF_PROP_N, SGF_PROP_OB, SGF_PROP_ON, SGF_PROP_OT,
  SGF_PROP_OW, SGF_PROP_PB, SGF_PROP_PC, SGF_PROP_PL, SGF_PROP_PM,
  SGF_PROP_PW, SGF_PROP_RE, SGF_PROP_RO, SGF_PROP_RU, SGF_PROP_SL,
  SGF_PROP_SO, SGF_PROP_SQ, SGF_PROP_ST, SGF_PROP_SZ, SGF_PROP_TB,
  SGF_PROP_TE, SGF_PROP_TM, SGF_PROP_TR, SGF_PROP_TW, SGF_PROP_UC,
  SGF_PROP_US, SGF_PROP_V, SGF_PROP_VW, SGF_PROP_W, SGF_PROP_WL,
  SGF_PROP_WR, SGF_PROP_WT,

  SGF_NUM_PROPERTIES
} SGFPropertyID;

/* Colors. */
typedef enum
{
  SGF_COLOR_BLACK,
  SGF_COLOR_WHITE
} SGFColor;

/* Different property value types. */
typedef enum
{
  SGF_VALUE_TYPE_INT,
  SGF_VALUE_TYPE_REAL,
  SGF_VALUE_TYPE_TEXT,
  SGF_VALUE_TYPE_COLOR,
  SGF_VALUE_TYPE_POINT,
  SGF_VALUE_TYPE_LIST,
  SGF_VALUE_TYPE_NONE,
  SGF_VALUE_TYPE_COMPOSED
} SGFValueType;

/* The point and move data structure. */
typedef struct {
  int x, y;
} SGFPoint;

struct sgf_composed_value;
struct sgf_value_list;

/* An SGF tree is represented using these data structures.  Every node
   is of type SGFTree. Parent node is pointed to by `parent', the
   first child node (i.e. the principal variation) by `first_child',
   and the next variation from the *parent* node by `next_sibling'.

   SGFTree.properties is a linked list of SGFProperty objects, linked
   using the SGFProperty.next field. Every property has an id and a
   value. The value is of type SGFPropertyValue.  Simple values are
   contained directly in the union SGFPropertyValue.value.  Composed
   values are always composed of two simple property values.  The two
   values are contained in SGFPropertyvalue.value.composed->v1 and
   SGFPropertyvalue.value.composed->v2. List values are contained in
   the linked list SGFPropertyvalue.value.list, linked using the
   SGFValueList.next field. The individual values that are of the type
   SGFPropertyvalue are then contained in SGFValueList.value.

   The following figure hopefully illustrates the data structures:


    +-------+next_sibling +-------+     ....... denotes the
    |SGFTree------------->|SGFTree|             actual tree      
    +----|--+            .+-------+
     : ^ |parent       .'
     : | |           .'   
     : |first_child.'     
     : | |       .'       +-----------------+ next +-----------+
     : | V     .'         |SGFProperty      ------>|SGFProperty|
    +--|----+.'           |+----------------+      +-----------+
    |SGFTree------------->||SGFPropertyValue|
    +--|----+properties   || Simple values  |    
     : |                  || here           |
     : | parent           ++|------|--------+
     : V                    |      |    
    +-------+               |      |value.list
    |SGFTree| value.composed|      |          
    +-------+               |      |   +-----------------+
                            |      |   |SGFValueList     ---+
                            V      +-->|+----------------+  |next
             +-----------------+       ||SGFPropertyValue|  |    
             |SGFComposedValue |       ++----------------+  |    
             |+----------------+                            |
             ||SGFPropertyValue|                            V
             |+----------------+                +---------------+
             ||SGFPropertyValue|                |SGFValueList   |
             ++----------------+                +---------------+
   */					  	  
					  	  
typedef struct sgf_property_value {	  	  
  SGFValueType type;			  	  
  union {				  	  
    double real_val;			  	  
    char *text;				  	  
    int int_val;			  	  
    SGFColor color_val;			  	  
    SGFPoint point;			  	  
    struct sgf_value_list *list;	  	  
    struct sgf_composed_value *composed;  	  
  } value;				  	  
} SGFPropertyValue;			  	  
					  
typedef struct sgf_value_list {		  
  struct sgf_value_list *next;		  
  SGFPropertyValue value;		  
} SGFValueList;				  

typedef struct sgf_composed_value {
  SGFPropertyValue v1, v2;
} SGFComposedValue;

typedef struct sgf_property {
  SGFPropertyID id;
  char *unknown_tag;
  SGFPropertyValue value;
  struct sgf_property *next;
} SGFProperty;

typedef struct sgf_tree_node {
  SGFProperty *properties;
  struct sgf_tree_node *parent, *first_child, *next_sibling;
} SGFTree;

typedef void (* SGFErrorCallback)(char *format, va_list args);

/* Set the error callback. Normally errors reported by the SGF parser
   are sent to stderr. By setting the error callback the callback gets
   called instead. The idea is that the callback can print the error
   message if it wants. If the callback is set to NULL, no error
   messages are displayed. */
void sgf_set_error_callback(SGFErrorCallback callback);

/* Set compatibility mode. */
void sgf_set_compatibility_mode(int mode);

/* Parse the stream `f' as an SGF file. There may not be any garbage
   in the stream before the actual game collection starts, only
   whitespace. Return either the parsed tree or NULL in the case of an
   error. Parse error messages are printed to stderr.

   The root node of the returned tree contains the individual games as
   its immediate children. Thus, the root node represents the game
   collection and the immediate children the individual games. */
SGFTree *sgf_parse(FILE *f);

/* Reverse of sgf_parse, dump out the SGFTree t, which must represent
   a game collection, to the stream `f'. In essence, the root node
   must be completely empty and contain individual games as its
   immediate children. This even if there is only one game. */
void sgf_dump_collection(SGFTree *t, FILE *f);

/* Free an SGFTree. This free(3)s all the nodes and the property
   values.  All property values that are strings are assumed to be
   strdup(3)ed and are free(3)d. Take this into account if you create
   an SGFTree by hand and then free it by using this function. */
void sgf_free_tree(SGFTree *t);

/* Functions for manipulating SGFTrees. */

/* Add t to be the first child of parent. Previously the parent of t
   must have been NULL. */
void sgf_add_subtree_first(SGFTree *t, SGFTree *parent);

/* Add t to be the last child of parent. Previously the parent of t
   must have been NULL. */
void sgf_add_subtree_last(SGFTree *t, SGFTree *parent);

/* Raise the subtree t by one in the relative order of the children of
   t's parent. If t is already the first child do nothing. */
void sgf_raise_subtree(SGFTree *t);

/* Lower the subtree t by one in the relative order of the children
   of t's parent. If t is already the last one do nothing. */
void sgf_lower_subtree(SGFTree *t);

/* Detach t from t's parent; set t's parent to NULL and remove it from
   the list of t's parent's children. */
void sgf_detach_subtree(SGFTree *t);

/* First detach t if t has a parent; then free t's datastructures. */
void sgf_delete_subtree(SGFTree *t);

/* Create a new SGF tree that consists of one node. */
SGFTree *sgf_create_leaf(void);

/* Find the property structure corresponding to the given id in the
   given node. Return either a pointer to the structure or NULL if the
   property has no value here.

   Observe that also properties with the inherite attribute are found
   only in the nodes where they are actually defined. */
   
SGFPropertyID sgf_property_id_with_name(const char *name);//m
SGFProperty *sgf_get_property(SGFTree *t, SGFPropertyID id);

/* Set the given property to have a given value in the given node.
   The value of the property must have been undefined.  The actual
   value is given as the fourth argument; its type is deduced from the
   value of the argument named type. The allowed values of type and
   the corresponding C datatypes are the following:

   SGF_VALUE_TYPE_INT --- int
   SGF_VALUE_TYPE_REAL --- double
   SGF_VALUE_TYPE_TEXT --- char *, *which will be strdup(3)ed*
   SGF_VALUE_TYPE_COLOR --- SGFColor
   SGF_VALUE_TYPE_POINT --- two int arguments
   SGF_VALUE_TYPE_NONE --- no arguments

   */
void sgf_set_property(SGFTree *t, SGFPropertyID id, SGFValueType type,
		      ...);

/* Set the given property to have a composed value of two undefined values. */
SGFComposedValue *sgf_make_composed_property(SGFTree *t, SGFPropertyID id);

/* Set the given property to have an empty list value. */
void sgf_make_list_property(SGFTree *t, SGFPropertyID id);

/* Add a simple value to a the end of list value. Analogous to
   sgf_set_property. The property must exist already. */
void sgf_add_to_list(SGFTree *t, SGFPropertyID id, SGFValueType type, ...);

/* Similar to sgf_add_to_list, expect that the property will be created
   if it doesn't exist. */
void sgf_add_to_list_create(SGFTree *t, SGFPropertyID id,
			    SGFValueType type, ...);

/* Add a composed value to a list value. Analogous to
   sgf_make_composed_property. */
SGFComposedValue *sgf_add_composed_to_list(SGFTree *t, SGFPropertyID id);

/* Remove a property's value freeing all the corresponding datastructures.
   The property needs to have been defined. */
void sgf_delete_property(SGFTree *t, SGFPropertyID id);

/* Remove a property's value freeing all the corresponding datastructures.
   The property may have been undefined already. */
void sgf_undefine_property(SGFTree *t, SGFPropertyID id);

/* Find the nearest ancestor of a node that defined the given
   property.  This can be used to find the current values of inherited
   properties. NULL is returned if no defining ancestor was found. */
SGFTree *sgf_find_defining_ancestor(SGFTree *t, SGFPropertyID id);

/* Find the nearest common ancestor node of t1 and t2. This can be
   NULL if t1 and t2 are in different collections. */
SGFTree *sgf_find_common_ancestor(SGFTree *t1, SGFTree *t2);

/* Check that the semantic properties of the nodes are in order.
   Return the number of semantic errors. All errors are displayed via
   the standard mechanism.
   
   This checks the following: (1) That board size is defined in every
   root node. (2) That the semantics of the different property types
   are obeyed. (3) That point lists contain only unique points, also
   for those properties that must together also mention every point
   at most once, such as TB and TW. (3) That compressed point lists
   contain compressed point arrays only in the correct orientation,
   i.e. bottom-left corner -- top-right corner. (4) That B and W
   moves are not mixed within a node. (5) That the KO property does
   not appear without a move. (6) That composite points [xy:xy] are not
   used anywhere (for arrows and lines they are illegal and for
   other points lists should use the single format [xy] instead).
   (7) That points do not lie outside the board.
   */
int sgf_check_semantic_validity(SGFTree *t);


/* *** NOTE ***

   Calling the following two functions is only allowed if
   sgf_check_semantic_validity returns zero for the given tree. */

/* Expand all the compressed point lists in the tree `t'. This
   function modifies the values of some properties in `t'.  After the
   call all point lists contain only single points. */
void sgf_uncompress_point_lists(SGFTree *t);

/* Compress all the point lists in the tree `t'. This function
   modifies the values of some properties in `t'. After the call
   some point lists can contain point pairs.
   
   This function may be called only for a tree that does not contain
   any compressed point lists. */
void sgf_compress_point_lists(SGFTree *t);

#ifdef __cplusplus
}
#endif

#endif /* SGF_H_INCLUDED */
