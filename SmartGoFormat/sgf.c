/*              Copyright (C) Antti Huima & Mika Kojo 1998, 1999

  $Id: sgf.c,v 1.2 2001/10/02 16:09:05 phink Exp $

  THIS FILE IS PART OF THE GO MACHINE PROJECT AND IS DISTRIBUTED UNDER CERTAIN
  CONDITIONS. PLEASE READ THE ACCOMPANYING LICENSE. BY COMPILING, DISTRIBUTING
  OR OTHERWISE USING THIS SOURCE CODE YOU IMPLICITLY ACCEPT THE LICENSING
  TERMS. ALL RIGHTS ARE RESERVED BY THE AUTHORS.

  */

/*
  sgf.c

  Author: Antti Huima <huima@ssh.fi>

  */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <setjmp.h>
#include <stdarg.h>
#include <string.h>

#include "sgf.h"

/* Different types of property values to parse. */

#define PT_LIST_OF_POINTS	0
#define PT_POINT		1
#define PT_SIMPLETEXT		2
#define PT_REAL			3
#define PT_COLOR		4
#define PT_NONE			5
#define PT_INTEGER		6
#define PT_TEXT                 7
#define PT_SIMPLETEXT_2		8   /* simpletext:simpletext */
#define PT_LIST_OF_2_POINTS	9   /* List of point:point */
#define PT_LIST_OF_POINT_ST    10   /* List of point:simpletext */
#define PT_SIZE		       11   /* either integer or integer:integer */
#define PT_2_POINTS            12   /* point:point */
#define PT_POINT_ST            13   /* point:simpletext */
#define PT_ELIST_OF_POINTS     14
#define PT_FIGURE	       15   /* either empty of integer:st */
#define PT_POINT_OR_2POINT     16   /* either point or point:point */
#define PT_DOUBLE              17   /* 1 or 2 */
#define PT_ELIST_OF_SIMPLETEXT 18   /* for the unknown values */

/* Logical places in an SGF tree. */

#define PM_SETUP		0
#define PM_GAMEINFO		1
#define PM_ROOT			2
#define PM_MOVE			3
#define PM_NONE                 4

/* Catalog of supported properties. */

typedef struct {
  SGFPropertyID id;
  char *name;
  char *descr;
  int mode;
  int parse_as;
} SGFPropertySpec;

static int compat_mode = SGF_COMPAT_NONE;

const SGFPropertySpec specs[] =
{
  /* This comes first */
  { SGF_PROP_UNKNOWN, "??", "Unknown", PM_NONE, PT_ELIST_OF_SIMPLETEXT },
  { SGF_PROP_AB, "AB", "Add black", PM_SETUP, PT_LIST_OF_POINTS },
  { SGF_PROP_AE, "AE", "Add empty", PM_SETUP, PT_LIST_OF_POINTS },
  { SGF_PROP_AN, "AN", "Annotation", PM_GAMEINFO, PT_SIMPLETEXT },
  { SGF_PROP_AP, "AP", "Application", PM_ROOT, PT_SIMPLETEXT_2 },
  { SGF_PROP_AR, "AR", "Arrow", PM_NONE, PT_LIST_OF_2_POINTS },
  { SGF_PROP_AW, "AW", "Add White", PM_SETUP, PT_LIST_OF_POINTS },
  { SGF_PROP_B,  "B",  "Black", PM_MOVE, PT_POINT },
  { SGF_PROP_BL, "BL", "Black time left", PM_MOVE, PT_REAL },
  { SGF_PROP_BM, "BM", "Bad move", PM_MOVE, PT_DOUBLE },
  { SGF_PROP_BR, "BR", "Black rank", PM_GAMEINFO, PT_SIMPLETEXT },
  { SGF_PROP_BT, "BT", "Black team", PM_GAMEINFO, PT_SIMPLETEXT },
  { SGF_PROP_C,  "C",  "Comment", PM_NONE, PT_TEXT },
  { SGF_PROP_CA, "CA", "Charset", PM_ROOT, PT_SIMPLETEXT },
  { SGF_PROP_CP, "CP", "Copyright", PM_GAMEINFO, PT_SIMPLETEXT },
  { SGF_PROP_CR, "CR", "Circle", PM_NONE, PT_LIST_OF_POINTS },
  { SGF_PROP_DD, "DD", "Dim points", PM_NONE, PT_ELIST_OF_POINTS },
  { SGF_PROP_DM, "DM", "Even position", PM_NONE, PT_DOUBLE },
  { SGF_PROP_DO, "DO", "Doubtful", PM_MOVE, PT_NONE },
  { SGF_PROP_DT, "DT", "Date", PM_GAMEINFO, PT_SIMPLETEXT },
  { SGF_PROP_EV, "EV", "Event", PM_GAMEINFO, PT_SIMPLETEXT },
  { SGF_PROP_FF, "FF", "Fileformat", PM_ROOT, PT_INTEGER },
  { SGF_PROP_FG, "FG", "Figure", PM_ROOT, PT_FIGURE },
  { SGF_PROP_GB, "GB", "Good for Black", PM_NONE, PT_DOUBLE },
  { SGF_PROP_GC, "GC", "Game comment", PM_GAMEINFO, PT_TEXT },
  { SGF_PROP_GM, "GM", "Game", PM_ROOT, PT_INTEGER },
  { SGF_PROP_GN, "GN", "Game name", PM_GAMEINFO, PT_SIMPLETEXT },
  { SGF_PROP_GW, "GW", "Good for White", PM_NONE, PT_DOUBLE },
  { SGF_PROP_HA, "HA", "Handicap", PM_GAMEINFO, PT_INTEGER },
  { SGF_PROP_HO, "HO", "Hotspot", PM_NONE, PT_DOUBLE },
  { SGF_PROP_IT, "IT", "Interesting", PM_MOVE, PT_NONE },
  { SGF_PROP_KM, "KM", "Komi", PM_GAMEINFO, PT_REAL },
  { SGF_PROP_KO, "KO", "Ko", PM_MOVE, PT_NONE },
  { SGF_PROP_LB, "LB", "Label", PM_NONE, PT_LIST_OF_POINT_ST },
  { SGF_PROP_LN, "LN", "Line", PM_NONE, PT_LIST_OF_2_POINTS },
  { SGF_PROP_MA, "MA", "Mark", PM_NONE, PT_LIST_OF_POINTS },
  { SGF_PROP_MN, "MN", "Set move number", PM_MOVE, PT_INTEGER },
  { SGF_PROP_N,  "N",  "Nodename", PM_NONE, PT_SIMPLETEXT },
  { SGF_PROP_OB, "OB", "OtStones Black", PM_MOVE, PT_INTEGER },
  { SGF_PROP_ON, "ON", "Opening", PM_GAMEINFO, PT_TEXT },
  { SGF_PROP_OT, "OT", "Overtime", PM_GAMEINFO, PT_SIMPLETEXT },
  { SGF_PROP_OW, "OW", "OtStones White", PM_MOVE, PT_INTEGER },
  { SGF_PROP_PB, "PB", "Player Black", PM_GAMEINFO, PT_SIMPLETEXT },
  { SGF_PROP_PC, "PC", "Place", PM_GAMEINFO, PT_SIMPLETEXT },
  { SGF_PROP_PL, "PL", "Player to play", PM_SETUP, PT_COLOR },
  { SGF_PROP_PM, "PM", "Print move mode", PM_NONE, PT_INTEGER },
  { SGF_PROP_PW, "PW", "Player White", PM_GAMEINFO, PT_SIMPLETEXT },
  { SGF_PROP_RE, "RE", "Result", PM_GAMEINFO, PT_SIMPLETEXT },
  { SGF_PROP_RO, "RO", "Round", PM_GAMEINFO, PT_SIMPLETEXT },
  { SGF_PROP_RU, "RU", "Rules", PM_GAMEINFO, PT_SIMPLETEXT },
  { SGF_PROP_SL, "SL", "Selected", PM_NONE, PT_LIST_OF_POINTS },
  { SGF_PROP_SO, "SO", "Source", PM_GAMEINFO, PT_SIMPLETEXT },
  { SGF_PROP_SQ, "SQ", "Square", PM_NONE, PT_LIST_OF_POINTS },
  { SGF_PROP_ST, "ST", "Style", PM_ROOT, PT_INTEGER },
  { SGF_PROP_SZ, "SZ", "Size", PM_ROOT, PT_SIZE },
  { SGF_PROP_TB, "TB", "Territory Black", PM_NONE, PT_ELIST_OF_POINTS },
  { SGF_PROP_TE, "TE", "Tesuji", PM_MOVE, PT_DOUBLE },
  { SGF_PROP_TM, "TM", "Timelimit", PM_GAMEINFO, PT_REAL },
  { SGF_PROP_TR, "TR", "Triangle", PM_NONE, PT_LIST_OF_POINTS },
  { SGF_PROP_TW, "TW", "Territory White", PM_NONE, PT_ELIST_OF_POINTS },
  { SGF_PROP_UC, "UC", "Unclear pos", PM_NONE, PT_DOUBLE },
  { SGF_PROP_US, "US", "User", PM_GAMEINFO, PT_SIMPLETEXT },
  { SGF_PROP_V,  "V",  "Value", PM_NONE, PT_REAL },
  { SGF_PROP_VW, "VW", "View", PM_NONE, PT_ELIST_OF_POINTS },
  { SGF_PROP_W,  "W",  "White", PM_MOVE, PT_POINT },
  { SGF_PROP_WL, "WL", "White time left", PM_MOVE, PT_REAL },
  { SGF_PROP_WR, "WR", "White rank", PM_GAMEINFO, PT_SIMPLETEXT },
  { SGF_PROP_WT, "WT", "White team", PM_GAMEINFO, PT_SIMPLETEXT },
  { 0, NULL, NULL, 0, 0 } /* terminator */
};

static const SGFPropertySpec *unknown_spec_ptr = &(specs[0]);
                        
static jmp_buf error_continuation;

static void sgf_default_error_callback(char *format, va_list args)
{
  fprintf(stderr, "SGF: ");
  vfprintf(stderr, format, args);
  fprintf(stderr, "\n");
}

static SGFErrorCallback errorcb = sgf_default_error_callback;

static void sgf_output_error(char *format, ...)
{
  va_list args;

  if (errorcb != NULL)
    {
      va_start(args, format);
      errorcb(format, args);
      va_end(args);
    }
}

static void sgf_error(char *format, ...)
{
  va_list args;
  if (errorcb != NULL)
    {
      va_start(args, format);
      errorcb(format, args);
      va_end(args);      
    }
  longjmp(error_continuation, 1);
}

static void sgf_fatal(char *format, ...)
{
  va_list args;
  va_start(args, format);
  fprintf(stderr, "SGF FATAL: ");
  vfprintf(stderr, format, args);
  fprintf(stderr, "\n");
  va_end(args);
  exit(1);
}

#define sgf_assert(x) do { if(!(x)) sgf_fatal("Assertion '%s' failed in %s on line %d.", #x, __FILE__, __LINE__); } while(0)

static void skip_whitespace(FILE *f)
{
  int c;
  do
    {
      c = fgetc(f);
    }
  while (c != EOF && c <= ' ');
  ungetc(c, f);
}

static void skip_lowercase(FILE *f)
{
  int c;
  do
    {
      c = fgetc(f);
    }
  while (c != EOF && (c >= 'a' && c <= 'z'));
  ungetc(c, f);
}

static int look_ahead(FILE *f)
{
  int c;
  c = fgetc(f); ungetc(c, f); return c;
}

static int look_ahead_sw(FILE *f)
{
  skip_whitespace(f);
  return look_ahead(f);
}

static SGFTree *alloc_node(void)
{
  return malloc(sizeof(SGFTree));
}

static const SGFPropertySpec *find_property_spec(char *name)
{
  int i;
  for (i = 0; specs[i].name != NULL; i++)
    {
      if (!strcmp(name, specs[i].name))
	return &(specs[i]);
    }
  return NULL;
}

static const SGFPropertySpec *find_property_spec_by_id(SGFPropertyID id)
{
  int i;
  for (i = 0; specs[i].name != NULL; i++)
    {
      if (specs[i].id == id)
	return &(specs[i]);
    }
  return NULL;
}

static char *buffer = NULL;
static int in_buf  = 0;
static int buf_len = 0;

static void empty_buffer(void)
{
  in_buf = 0;
}

static void add_to_buffer(int c)
{
  if ((buf_len - in_buf) == 0)
    {
      if (buf_len == 0) buf_len = 100;
      buffer = realloc(buffer, buf_len * 2);
      buf_len *= 2;
    }
  buffer[in_buf] = c;
  in_buf++;  
}

/* This removes backslashes and eats consequtive whitespaces
   translating them to a single space.*/
   #if o
static void process_simpletext(char *buffer)
{
  char *rptr = buffer, *wptr = buffer;
  while (*rptr != '\0')
    {
      if (*rptr == '\\')
	rptr++;
      /* Skip over consequtive whitespaces. */
      while (*rptr != '\0' && *rptr <= ' ' && (*wptr == ' ')) 
            rptr++;
      if (rptr > wptr) 
            *wptr = *rptr;
      rptr++;
      wptr++;
    }
  *wptr = '\0';
  /* Kill the possibly trailing space */
  if (wptr > buffer && (*(wptr-1) == ' '))
    *(wptr-1) = '\0';
}
#endif

/* This removes backslashes and soft newlines.
   It translates all other whitespaces to simple spaces. 
   After translation, hard linebreaks are LF characters '\n'. */
static void process_text(char *buffer)
{
  char *rptr = buffer, *wptr = buffer;
  while (*rptr != '\0')
    {
      if (*rptr == '\\')
	{
	  rptr++;
	  if (*rptr == '\r' || *rptr == '\n')
	    {
	      rptr++;
	      /* Check for a compound newline character. */
	      if ((*rptr == 'r' || *rptr == '\n') && (*rptr != *(rptr - 1)))
		{
		  rptr++;
		}
	      /* At this point we have skipped over a shoft linebreak. */
	      continue;
	    }
	  /* Not a newline next, so fall to the next conditional. */
	}
      if (*rptr < ' ')
	{
	  if (*rptr == '\r' || *rptr == '\n')
	    {
	      rptr++;
	      if ((*rptr == 'r' || *rptr == '\n') && (*rptr != *(rptr - 1)))
		{
		  rptr++;
		}
	      /* Hard newline got. */
	      *wptr++ = '\n';
	      continue;
	    }
	  /* Convert to space. */
	  *wptr++ = ' ';
	  rptr++;
	  continue;
	}
      *wptr++ = *rptr++;
    }
  *wptr = '\0';
}

static char *compound_break(char *buf)
{
  while (*buf != '\0')
    {
      if (*buf == '\\')
	{
	  buf++;
	}
      else
	{
	  if (*buf == ':')
	    {
	      *buf = '\0';
	      return buf + 1;
	    }
	}
      buf++;
    }
  return NULL;
}

static void sgf_get_property_value(char *buf, int parse_type,
				   SGFPropertyValue *target,
				   const SGFPropertySpec *s)
{
  int len = strlen(buf);
  char *ptr;

  switch (parse_type)
    {
    case PT_POINT_OR_2POINT:
      ptr = compound_break(buf);
      if (ptr)
	{
	  target->type = SGF_VALUE_TYPE_COMPOSED;
	  target->value.composed = malloc(sizeof(SGFComposedValue));
	  sgf_get_property_value(buf, PT_POINT,
				 &(target->value.composed->v1), s);
	  sgf_get_property_value(ptr, PT_POINT,
				 &(target->value.composed->v2), s);
	  break;
	}
      /* Fall through to parse a single-point value. */

    case PT_POINT:
      if (len == 0)
	{
	  target->type = SGF_VALUE_TYPE_NONE;
	  break;
	}
      if (len != 2)
	sgf_error("Invalid point `%s' for property `%s'.", buf, s->descr);
      if (!strcmp("tt", buf))
	{
	  target->type = SGF_VALUE_TYPE_NONE;
	  break;
	}
      target->value.point.x = buf[0] - 'a';
      target->value.point.y = buf[1] - 'a';
      if (target->value.point.x < 0 || target->value.point.y > 18 ||
	  target->value.point.y < 0 || target->value.point.y > 18)
	{
	  sgf_error("Invalid point `%s' for property `%s'.", buf, s->descr);
	}
      target->type = SGF_VALUE_TYPE_POINT;
      break;

    case PT_REAL:
      target->type = SGF_VALUE_TYPE_REAL;
      target->value.real_val = atof(buf);
      break;

    case PT_NONE:
      if (len != 0)
	sgf_error("Invalid empty value `%s' for property `%s'.", buf,
		  s->descr);
      target->type = SGF_VALUE_TYPE_NONE;
      break;

    case PT_INTEGER:
      target->type = SGF_VALUE_TYPE_INT;
      target->value.int_val = atoi(buf);
      break;

    case PT_DOUBLE:
      target->type = SGF_VALUE_TYPE_INT;
      target->value.int_val = atoi(buf);
      if (target->value.int_val != 1 && target->value.int_val != 2)
	  sgf_error("Invalid `double' value %d for property `%s'.",
		    target->value.int_val, s->descr);
      break;

    case PT_SIZE:
      ptr = compound_break(buf);
      if (ptr)
	{
	  target->type = SGF_VALUE_TYPE_COMPOSED;
	  target->value.composed = malloc(sizeof(SGFComposedValue));
	  target->value.composed->v1.type = SGF_VALUE_TYPE_INT;
	  target->value.composed->v1.value.int_val = atoi(buf);
	  target->value.composed->v2.type = SGF_VALUE_TYPE_INT;
	  target->value.composed->v2.value.int_val = atoi(ptr + 1);
	  break;
	}
      target->value.int_val = atoi(buf);      
      target->type = SGF_VALUE_TYPE_INT;
      break;

    case PT_FIGURE:
      if (len == 0)
	{
	  target->type = SGF_VALUE_TYPE_NONE;
	  break;
	}
      ptr = compound_break(buf);
      if (ptr == NULL)
	sgf_error("Need a compound value for property `%s'.", buf, s->descr);
      target->type = SGF_VALUE_TYPE_COMPOSED;
      target->value.composed = malloc(sizeof(SGFComposedValue));
      sgf_get_property_value(buf, PT_INTEGER,
			     &(target->value.composed->v1), s);
      sgf_get_property_value(ptr, PT_SIMPLETEXT,
			     &(target->value.composed->v2), s);
      break;
	
    case PT_COLOR:
      if (len != 1)
	sgf_error("Invalid color `%s' for property `%s'.", buf,
		  s->descr);
      target->type = SGF_VALUE_TYPE_COLOR;
      if (buf[0] == 'B') target->value.color_val = SGF_COLOR_BLACK;
      else if (buf[0] == 'W') target->value.color_val = SGF_COLOR_WHITE;
      else sgf_error("Invalid color `%s' for property `%s'.", buf, s->descr);
      break;

    case PT_SIMPLETEXT:
      //process_simpletext(buf);
      target->type = SGF_VALUE_TYPE_TEXT;
      target->value.text = strdup(buf);
      break;

    case PT_TEXT:
      process_text(buf);
      target->type = SGF_VALUE_TYPE_TEXT;
      target->value.text = strdup(buf);
      break;

    case PT_2_POINTS:
      ptr = compound_break(buf); 
      if (ptr == NULL)
	sgf_error("Need a compound value for property `%s'.", buf, s->descr);
      target->type = SGF_VALUE_TYPE_COMPOSED;
      target->value.composed = malloc(sizeof(SGFComposedValue));
      sgf_get_property_value(buf, PT_POINT, &(target->value.composed->v1), s);
      sgf_get_property_value(ptr, PT_POINT, &(target->value.composed->v2), s);
      break;
      
    case PT_POINT_ST:
      ptr = compound_break(buf); 
      if (ptr == NULL)
	sgf_error("Need a compound value for property `%s'.", buf, s->descr);
      target->type = SGF_VALUE_TYPE_COMPOSED;
      target->value.composed = malloc(sizeof(SGFComposedValue));
      sgf_get_property_value(buf, PT_POINT, &(target->value.composed->v1), s);
      sgf_get_property_value(ptr, PT_SIMPLETEXT,
			     &(target->value.composed->v2), s);
      break;

    case PT_SIMPLETEXT_2:      
      ptr = compound_break(buf); 
      if (ptr == NULL)
	sgf_error("Need a compound value for property `%s'.", buf, s->descr);
      target->type = SGF_VALUE_TYPE_COMPOSED;
      target->value.composed = malloc(sizeof(SGFComposedValue));
      sgf_get_property_value(buf, PT_SIMPLETEXT,
			     &(target->value.composed->v1), s);
      sgf_get_property_value(ptr, PT_SIMPLETEXT,
			     &(target->value.composed->v2), s);
      break;
    }
}

static void sgf_parse_single_value(FILE *f)
{
  int c;

  skip_whitespace(f);
  c = fgetc(f);

  if (c != '[')
    sgf_error("Expecting `[' but got `%c' when parsing a property value.", c);

  empty_buffer();

  while (1)
    {
      c = fgetc(f);

      if (c == EOF)
	sgf_error("Premature EOF while reading a property value.");

      if (c == ']') break;

      if (c == '\\')
	{
	  add_to_buffer(c);
	  c = fgetc(f);
	  if (c == EOF)
	    sgf_error("Premature EOF after backslash.");
	  add_to_buffer(c);
	  continue;
	}

      add_to_buffer(c);
    }
  add_to_buffer(0);
}

static void sgf_parse_list_value(FILE *f, int parse_type,
				 SGFPropertyValue *target, 
				 const SGFPropertySpec *s)
{
  SGFValueList **ptr;

  if (!look_ahead_sw(f) == '[')
      sgf_error("List missing for property `%s'.", s->descr);

  target->type = SGF_VALUE_TYPE_LIST;
  target->value.list = NULL;
  ptr = &(target->value.list);
  while (look_ahead_sw(f) == '[')
    {
      *ptr = malloc(sizeof(SGFValueList));
      sgf_parse_single_value(f);
      sgf_get_property_value(buffer, parse_type, &((*ptr)->value), s);
      (*ptr)->next = NULL;
      ptr = &((*ptr)->next);
    }
  return;
}

static void sgf_parse_elist_value(FILE *f, int parse_type,
				  SGFPropertyValue *target,
				  const SGFPropertySpec *s)
{
  int c;
  if (look_ahead_sw(f) == '[')
    {
      c = fgetc(f);
      if (look_ahead_sw(f) == ']')
	{
	  target->type = SGF_VALUE_TYPE_LIST;
	  target->value.list = NULL;
	  fgetc(f);
	  return;
	}
      ungetc(c, f);
      sgf_parse_list_value(f, parse_type, target, s);
    }
  else
    sgf_error("List missing for property `%s'.", s->descr);
}

static void sgf_parse_property_value(FILE *f, const SGFPropertySpec *s,
				     SGFPropertyValue *target)
{
  switch (s->parse_as)
    {
    case PT_LIST_OF_POINTS:
      sgf_parse_list_value(f, PT_POINT_OR_2POINT, target, s);
      return;

    case PT_ELIST_OF_SIMPLETEXT:
      sgf_parse_elist_value(f, PT_SIMPLETEXT, target, s);
      return;

    case PT_ELIST_OF_POINTS:
      sgf_parse_elist_value(f, PT_POINT_OR_2POINT, target, s);
      return;

    case PT_LIST_OF_2_POINTS:
      sgf_parse_list_value(f, PT_2_POINTS, target, s);
      return;

    case PT_LIST_OF_POINT_ST:
      sgf_parse_list_value(f, PT_POINT_ST, target, s);
      return;
    }

  sgf_parse_single_value(f);

  sgf_get_property_value(buffer, s->parse_as, target, s);
}

static void sgf_free_properties(SGFProperty *p);

static SGFTree *sgf_parse_node(FILE *f)
{
  int c;
  char propname[3];
  const SGFPropertySpec *s;
  SGFTree *t = alloc_node();
  SGFProperty *p;
  SGFProperty **ptr;

  t->first_child = NULL; t->next_sibling = NULL; t->parent = NULL;
  t->properties = NULL;
  ptr = &(t->properties);
  
  if (fgetc(f) != ';')
    sgf_error("A node must start with ';'.");

  while (1)
    {
      skip_whitespace(f);
      if (compat_mode & SGF_COMPAT_FF3_IDS)
	skip_lowercase(f);
      if ((c = look_ahead(f)), (c < 'A' || c > 'Z'))
	break;
      propname[0] = fgetc(f);
      if (compat_mode & SGF_COMPAT_FF3_IDS)
	skip_lowercase(f);
      if ((c = look_ahead(f)), (c >= 'A' && c <= 'Z'))
	{
	  propname[1] = fgetc(f);
	  propname[2] = '\0';
	}
      else
	{
	  propname[1] = '\0';
	}
      if (compat_mode & SGF_COMPAT_FF3_IDS)
	skip_lowercase(f);
      s = find_property_spec(propname);

      if (s == NULL)
	{
	  if (compat_mode & SGF_COMPAT_ACCEPT_UNKNOWN)
	    {
	      s = unknown_spec_ptr;
	    }
	  else
	    {
	      sgf_error("Unrecognized property identifier `%s'.", propname);
	    }
	}

      p = malloc(sizeof(SGFProperty));

      p->id = s->id;
      p->next = NULL;
      p->unknown_tag = NULL;

      sgf_parse_property_value(f, s, &(p->value));

      if (s == unknown_spec_ptr)
	{
	  if (compat_mode & SGF_COMPAT_DISCARD_UNKNOWN)
	    {
	      sgf_free_properties(p);
	      continue;
	    }
	  p->unknown_tag = strdup(propname);
	}

      (*ptr) = p;
      ptr = &((*ptr)->next);

      /* Check certain restrictions. */
      /* Check that this version is supported. */
      if (s->id == SGF_PROP_FF)
	{
	  if (!((p->value.value.int_val == 4)
		|| (p->value.value.int_val == 3 &&
		    (compat_mode & SGF_COMPAT_ACCEPT_FF3))
		|| (p->value.value.int_val == 2 &&
		    (compat_mode & SGF_COMPAT_ACCEPT_FF2))
		|| (p->value.value.int_val == 1 &&
		    (compat_mode & SGF_COMPAT_ACCEPT_FF1))))
	    {
	      sgf_error("Unsupported SGF format version %d.",
			p->value.value.int_val);
	    }
	}

      /* Check that the game type is supported. */
      if (s->id == SGF_PROP_GM)
	{
	  if (p->value.value.int_val != 1)
	    {
	      sgf_error("Unsupported game type %d.",
			p->value.value.int_val);
	    }
	}

      /* Other bounds checking */
      if (s->id == SGF_PROP_ST)
	{
	  if (p->value.value.int_val < 0 ||
	      p->value.value.int_val > 3)
	    {
	      sgf_error("Value %d out of bounds for the style property.",
			p->value.value.int_val);
	    }
	}

      if (s->id == SGF_PROP_SZ)
	{
	  if (p->value.type == SGF_VALUE_TYPE_INT &&
	      (p->value.value.int_val < 1 ||
	       p->value.value.int_val > 19))
	    {
	      sgf_error("Invalid or unsupported size %d",
			p->value.value.int_val);
	    }
	  if (p->value.type == SGF_VALUE_TYPE_COMPOSED &&
	      (p->value.value.composed->v1.value.int_val < 1 ||
	       p->value.value.composed->v1.value.int_val < 19 ||
	       p->value.value.composed->v2.value.int_val < 1 ||
	       p->value.value.composed->v2.value.int_val < 19))
	    {
	      sgf_error("Invalid or unsupported size %d x %d",
			p->value.value.composed->v1.value.int_val,
			p->value.value.composed->v2.value.int_val);
	    }
	}
    }
  return t;
}

SGFTree *sgf_parse_tree(FILE *f)
{
  SGFTree *t = NULL;
  SGFTree *r = NULL;
  SGFTree *t2;
  SGFTree **ptr;
  int c; 

  c = fgetc(f);
  if (c != '(')
    sgf_error("Trees must start with '('.");

  while (look_ahead_sw(f) == ';')
    {
      t2 = sgf_parse_node(f);
      if (t != NULL)
	{
	  t2->parent = t;
	  t->first_child = t2;
	  t = t2;
	}
      else
	{
	  r = t2; t = r;
	}
    }

  ptr = &(t->first_child);

  while (look_ahead_sw(f) == '(')
    {
      t2 = sgf_parse_tree(f);
      t2->next_sibling = NULL;
      t2->parent = t;
      *ptr = t2;
      ptr = &((*ptr)->next_sibling);
    }

  skip_whitespace(f);

  if (fgetc(f) != ')')
    sgf_error("Game tree does not end in ')'.");

  return r;
}

static void sgf_free_value_data(SGFPropertyValue *v);

static void sgf_free_value_list(SGFValueList *l)
{
  SGFValueList *tmp;

  while (l != NULL)
    {
      tmp = l->next;
      sgf_free_value_data(&(l->value));
      free(l);
      l = tmp;
    }
}

static void sgf_free_value_data(SGFPropertyValue *v)
{
  switch (v->type)
    {
    case SGF_VALUE_TYPE_TEXT:
      free(v->value.text);
      break;

    case SGF_VALUE_TYPE_COMPOSED:
      sgf_free_value_data(&v->value.composed->v1);
      sgf_free_value_data(&v->value.composed->v2);
      free(v->value.composed);
      break;

    case SGF_VALUE_TYPE_LIST:
      sgf_free_value_list(v->value.list);
      break;

    default:
      break;
    }
}

static void sgf_free_properties(SGFProperty *p)
{
  SGFProperty *tmp;
  while (p != NULL)
    {
      tmp = p->next;
      sgf_free_value_data(&(p->value));
      if (p->unknown_tag != NULL)
	free(p->unknown_tag);
      free(p);
      p = tmp;
    }
}

static void sgf_free_node(SGFTree *n)
{
  sgf_free_properties(n->properties);
  free(n);
}

void sgf_free_tree(SGFTree *t)
{
  SGFTree *i, *tmp;

  i = t->first_child;
  while (i != NULL)
    {
      tmp = i->next_sibling;
      sgf_free_tree(i);
      i = tmp;
    }

  sgf_free_node(t);

  return;
}

static int dump_col = 0;

static void dumppf(FILE *f, char *fmt, ...)
{
  va_list args;
  char buf[100];
  char *ptr;
  char *cptr;
  va_start(args, fmt);
  vsprintf(buf, fmt, args);
  va_end(args);
  fputs(buf, f);
  ptr = strrchr(buf, '\n');
  if (ptr != NULL)
    {
      dump_col = 0;
      cptr = ptr + 1;
    }
  else
    cptr = buf;

  while (*cptr != '\0')
    {
      if (*cptr >= ' ') dump_col++;
      if (*cptr == '\t') dump_col += 8;
      cptr++;
    }
}

static void indent(FILE *f, int ind)
{
  if (ind > 24) ind = 24;
  while (ind >= 8) { dumppf(f, "\t"); ind -= 8; }
  while (ind > 0)  { dumppf(f, " "); ind--; }
}

static void sgf_dump_text(char *text, FILE *f, int formatted_text)
{
  while (*text != '\0')
    {
      if (formatted_text && dump_col > 77)
	{
	  dumppf(f, "\\\n");
	}
      switch (*text)
	{
	//case ':':
	case '\\':
	case ']':
	  dumppf(f, "\\%c", *text);
	  break;
	default:
	  dumppf(f, "%c", *text);
	}
      text++;
    }
}

static void sgf_dump_value_atomic(SGFPropertyValue *v, FILE *f,
				  int formatted_text)
{
  switch (v->type)
    {
    case SGF_VALUE_TYPE_INT:
      dumppf(f, "%d", v->value.int_val);
      break;
    case SGF_VALUE_TYPE_REAL:
      dumppf(f, "%.1f", v->value.real_val);
      break;
    case SGF_VALUE_TYPE_TEXT:
      sgf_dump_text(v->value.text, f, formatted_text);
      break;
    case SGF_VALUE_TYPE_COLOR:
      dumppf(f, "%c", v->value.color_val == SGF_COLOR_BLACK ? 'B' : 'W');
      break;
    case SGF_VALUE_TYPE_POINT:
      dumppf(f, "%c%c", v->value.point.x + 'a', v->value.point.y + 'a');
      break;
    case SGF_VALUE_TYPE_NONE:
      break;
    default:
      sgf_fatal("Internal error in sgf_dump_value_atomic.");
    }
}

static void sgf_dump_value(SGFPropertyValue *v, FILE *f,
			   int formatted_text, int ind)
{
  SGFValueList *l;
  switch (v->type)
    {
    case SGF_VALUE_TYPE_LIST:
      if (v->value.list == NULL) dumppf(f, "[]");
      else
	for (l = v->value.list; l != NULL; l = l->next)
	  {
	    if (dump_col > 60)
	      {
		dumppf(f, "\n"); indent(f, ind);
		dumppf(f, "  ");
	      }
	    sgf_dump_value(&(l->value), f, formatted_text, ind);
	  }
      break;
    case SGF_VALUE_TYPE_COMPOSED:
      dumppf(f, "[");
      sgf_dump_value_atomic(&(v->value.composed->v1), f, formatted_text);
      dumppf(f, ":");
      sgf_dump_value_atomic(&(v->value.composed->v2), f, formatted_text);
      dumppf(f, "]");
      break;
    default:
      dumppf(f, "[");
      sgf_dump_value_atomic(v, f, formatted_text);
      dumppf(f, "]");
    }
}

static void sgf_dump_property(SGFProperty *p, FILE *f,
			      const SGFPropertySpec *s, int ind)
{
  if (p->unknown_tag != NULL)
    dumppf(f, "%s", p->unknown_tag);
  else
    dumppf(f, "%s", s->name);
  sgf_dump_value(&(p->value), f, (s->parse_as == PT_TEXT), ind);
}

static int next_node_from_new_line = 0;

static void sgf_dump_node(SGFTree *t, FILE *f, int ind)
{
  const SGFPropertySpec *s;

  SGFProperty *p;
  if (next_node_from_new_line && dump_col > ind)
    {
      dumppf(f, "\n"); indent(f, ind);
      next_node_from_new_line = 0;
    }
  dumppf(f, ";");
  for (p = t->properties; p != NULL; p = p->next)
    {      
      s = find_property_spec_by_id(p->id);
      if (s == NULL)
	sgf_fatal("sgf_dump_node: cannot find entry.\n");
      if ((s->parse_as != PT_POINT)
	  && p->id != SGF_PROP_WL
	  && p->id != SGF_PROP_BL)
	{
	  next_node_from_new_line = 1;
	  if (dump_col > (ind+1))
	    {
	      dumppf(f, "\n", s->parse_as);
	      indent(f, ind); dumppf(f, " ");
	    }
	}
      if (dump_col > 65)
	{
	  dumppf(f, "\n");
	  indent(f, ind); dumppf(f, " ");
	}
      sgf_dump_property(p, f, s, ind);
    }
}

static void sgf_dump_tree(SGFTree *t, FILE *f, int ind)
{
  SGFTree *i;
  if (t == NULL) return;
redo:
  if (dump_col == 0) indent(f, ind);
  if (dump_col > 60)
    { 
      dumppf(f, "\n");
      indent(f, ind);
    }
  sgf_dump_node(t, f, ind);
  if (t->first_child == NULL) return;
  if (t->first_child->next_sibling == NULL)
    {
      t = t->first_child;
      goto redo;
    }
  for (i = t->first_child; i != NULL; i = i->next_sibling)
    {
      dumppf(f, "\n");
      indent(f, ind); dumppf(f, "(\n");
      sgf_dump_tree(i, f, ind + 2);
      dumppf(f, "\n");
      indent(f, ind); dumppf(f, ")");
    }
}

void sgf_dump_collection(SGFTree *t, FILE *f)
{
  SGFTree *i;
  dump_col = 0;
  for (i = t->first_child; i != NULL; i = i->next_sibling)
    {
      dumppf(f, "(\n");
      sgf_dump_tree(i, f, 0);
      dumppf(f, ")\n");
    }
}

SGFTree *sgf_parse(FILE *f)
{
  int c;
  int i;
  SGFTree *root = alloc_node();
  SGFTree *tree;
  SGFTree **ptr;
  char tempbuf[50];

  root->parent = NULL; root->next_sibling = NULL; root->first_child = NULL;
  root->properties = NULL;

  if (setjmp(error_continuation) != 0)
    {
      /* Error while parsing */
      sgf_free_tree(root);
      i = 0;
      while (i<49 && ((c = fgetc(f)) != EOF))
	{
	  if (c < 32) c = 32;
	  tempbuf[i++] = c;
	}
      tempbuf[i] = '\0';
      sgf_output_error("Error before: '%s'.", tempbuf);      
      return NULL;      
    }

  ptr = &(root->first_child);

  while (1)
    {
      skip_whitespace(f);
      c = look_ahead(f);
      if (EOF == c) break;
      if (c != '(')
	{
	  sgf_error("Expected start of a game tree missing: got `%c'.", c);
	}
      tree = sgf_parse_tree(f);
      *ptr = tree;
      ptr = &(tree->next_sibling);
      tree->parent = root;
      tree->next_sibling = NULL;
    }
  return root;
}

void sgf_add_subtree_first(SGFTree *t, SGFTree *parent)
{
  sgf_assert(t->parent == NULL);
  sgf_assert(t->next_sibling == NULL);
  t->next_sibling = parent->first_child;
  parent->first_child = t;
  t->parent = parent;
}

void sgf_add_subtree_last(SGFTree *t, SGFTree *parent)
{
  SGFTree **ptr;

  sgf_assert(t->parent == NULL);
  sgf_assert(t->next_sibling == NULL);
  ptr = &(parent->first_child);
  while ((*ptr) != NULL) ptr = &((*ptr)->next_sibling);
  *ptr = t;
  t->parent = parent;
}

void sgf_raise_subtree(SGFTree *t)
{
  SGFTree **ptr;
  SGFTree *temp;

  sgf_assert(t->parent != NULL);
  if (t->parent->first_child == t) return;
  ptr = &(t->parent->first_child);
  while ((*ptr)->next_sibling != t) ptr = &((*ptr)->next_sibling);
  temp = t->next_sibling;
  t->next_sibling = *ptr;
  (*ptr)->next_sibling = temp;
  *ptr = t;
}

void sgf_lower_subtree(SGFTree *t)
{
  SGFTree *temp;
  SGFTree **ptr;

  sgf_assert(t->parent != NULL);
  if (t->next_sibling == NULL) return;
  ptr = &(t->parent->first_child);
  while ((*ptr) != t) ptr = &((*ptr)->next_sibling);
  *ptr = t->next_sibling;
  temp = (*ptr)->next_sibling;
  (*ptr)->next_sibling = t;
  t->next_sibling = temp;
}

void sgf_detach_subtree(SGFTree *t)
{
  SGFTree **ptr;

  sgf_assert(t->parent != NULL);
  ptr = &(t->parent->first_child);
  while (*ptr != t) ptr = &((*ptr)->next_sibling);
  *ptr = t->next_sibling;
  t->parent = NULL;
  t->next_sibling = NULL;
}

void sgf_delete_subtree(SGFTree *t)
{
  sgf_detach_subtree(t);
  sgf_free_tree(t);
}

SGFTree *sgf_create_leaf(void)
{
  SGFTree *t = alloc_node();
  t->parent = t->first_child = t->next_sibling = NULL;
  t->properties = NULL;  
  return t;
}

SGFProperty *sgf_get_property(SGFTree *t, SGFPropertyID id)
{
  SGFProperty *p;
  for (p = t->properties; p != NULL; p = p->next)
    {
      if (p->id == id) return p;
    }
  return NULL;
}

SGFPropertyID sgf_property_id_with_name(const char *name)
{
    const SGFPropertySpec *spec = find_property_spec((char *)name);
    return (spec != NULL) ? spec->id : SGF_PROP_UNKNOWN;
}


static void sgf_set_value_to(SGFPropertyValue *v, SGFValueType type,
			     va_list args)
{
  switch (type)    
    {
    case SGF_VALUE_TYPE_INT:
      v->value.int_val = va_arg(args, int);
      break;
    case SGF_VALUE_TYPE_REAL:
      v->value.real_val = va_arg(args, double);
      break;
    case SGF_VALUE_TYPE_TEXT:
      v->value.text = strdup(va_arg(args, char *));
      break;
    case SGF_VALUE_TYPE_COLOR:
      v->value.color_val = va_arg(args, SGFColor);
      break;
    case SGF_VALUE_TYPE_NONE:
      break;
    case SGF_VALUE_TYPE_POINT:
      v->value.point.x = va_arg(args, int);
      v->value.point.y = va_arg(args, int);
      break;
    default:
      sgf_assert(0);
    }
  v->type = type;
}

static SGFProperty *sgf_add_property(SGFTree *t, SGFPropertyID id)
{
  SGFProperty *p = malloc(sizeof(*p));
  p->id = id;
  p->next = t->properties;
  p->unknown_tag = NULL;
  t->properties = p;
  p->value.type = SGF_VALUE_TYPE_NONE; 
  return p;
}

void sgf_set_property(SGFTree *t, SGFPropertyID id, SGFValueType type,
		      ...)
{
  SGFProperty *p = sgf_add_property(t, id);
  va_list args;

  va_start(args, type);
  p->id = id;
  sgf_set_value_to(&(p->value), type, args);
  va_end(args);
}

SGFComposedValue *sgf_make_composed_property(SGFTree *t, SGFPropertyID id)
{
  SGFProperty *p = sgf_add_property(t, id);
  p->value.value.composed = malloc(sizeof(SGFComposedValue));
  p->value.value.composed->v1.type = SGF_VALUE_TYPE_NONE;
  p->value.value.composed->v2.type = SGF_VALUE_TYPE_NONE;
  return p->value.value.composed;
}

void sgf_make_list_property(SGFTree *t, SGFPropertyID id)
{
  SGFProperty *p = sgf_add_property(t, id);
  p->value.type = SGF_VALUE_TYPE_LIST;
  p->value.value.list = NULL;
}

static SGFValueList *sgf_add_list_element(SGFTree *t, SGFPropertyID id)
{
  SGFProperty *p; 
  SGFValueList *l; 
  SGFValueList **ptr;

  sgf_assert(t != NULL);

  p = sgf_get_property(t, id);
  sgf_assert(p != NULL);

  l = malloc(sizeof(*l));

  ptr = &(p->value.value.list);

  while ((*ptr) != NULL) ptr = &((*ptr)->next);
  *ptr = l; l->next = NULL;

  return l;
}

void sgf_add_to_list(SGFTree *t, SGFPropertyID id, SGFValueType type, ...)
{
  SGFValueList *l;
  va_list args;

  sgf_assert(t != NULL);

  l = sgf_add_list_element(t, id);

  va_start(args, type);
  sgf_set_value_to(&(l->value), type, args);
  va_end(args);
}

void sgf_add_to_list_create(SGFTree *t, SGFPropertyID id,
			    SGFValueType type, ...)
{
  SGFValueList *l;
  va_list args;

  sgf_assert(t != NULL);

  if (sgf_get_property(t, id) == NULL)
    sgf_make_list_property(t, id);

  l = sgf_add_list_element(t, id);

  va_start(args, type);
  sgf_set_value_to(&(l->value), type, args);
  va_end(args);
}

SGFComposedValue *sgf_add_composed_to_list(SGFTree *t, SGFPropertyID id)
{
  SGFValueList *l = sgf_add_list_element(t, id);

  l->value.type = SGF_VALUE_TYPE_COMPOSED;
  l->value.value.composed = malloc(sizeof(SGFComposedValue));
  l->value.value.composed->v1.type = SGF_VALUE_TYPE_NONE;
  l->value.value.composed->v2.type = SGF_VALUE_TYPE_NONE;

  return l->value.value.composed;
}

void sgf_delete_property(SGFTree *t, SGFPropertyID id)
{
  SGFProperty **ptr;
  SGFProperty *p;

  ptr = &(t->properties);
  while ((*ptr)->id != id) ptr = &((*ptr)->next);
  p = *ptr;
  *ptr = (*ptr)->next;
  sgf_free_value_data(&(p->value));
  free(p);
}

void sgf_undefine_property(SGFTree *t, SGFPropertyID id)
{
  if (sgf_get_property(t, id) != NULL)
    sgf_delete_property(t, id);
}

SGFTree *sgf_find_defining_ancestor(SGFTree *t, SGFPropertyID id)
{
  while (1)
    {
      if (t->parent == NULL) return NULL;
      if (sgf_get_property(t, id) != NULL) return t;
      t = t->parent;
    }
}


static int game_info_counter[SGF_NUM_PROPERTIES];
static int misc_counter[SGF_NUM_PROPERTIES];
static SGFPropertyValue *current_size;

static int test_board[19][19];

static int checkp(SGFPropertyValue *v, int sx, int sy)
{
  int x1, y1, x2, y2;
  int x, y;
  SGFValueList *l;
  int result = 0;

  switch (v->type)
    {
    case SGF_VALUE_TYPE_LIST:
      for (l = v->value.list; l != NULL; l = l->next)
	{
	  result += checkp(&(l->value), sx, sy);
	}
      break;

    case SGF_VALUE_TYPE_COMPOSED:
      if (v->value.composed->v1.type != SGF_VALUE_TYPE_POINT)
	return checkp(&(v->value.composed->v2), sx, sy);
      if (v->value.composed->v2.type != SGF_VALUE_TYPE_POINT)
	return checkp(&(v->value.composed->v1), sx, sy);
      x1 = v->value.composed->v1.value.point.x;
      y1 = v->value.composed->v1.value.point.y;
      x2 = v->value.composed->v2.value.point.x;
      y2 = v->value.composed->v2.value.point.y;
      if (x1 > sx || y1 > sy)
	{
	  sgf_output_error("Point coordinates (%d,%d) out of board.",
			   x1, y1);
	  result++;
	  break;
	}
      if (x2 > sx || y2 > sy)
	{
	  sgf_output_error("Point coordinates (%d,%d) out of board.",
			   x2, y2);
	  result++;
	  break;
	}
      if (x1 > x2 || y1 > y2)
	{
	  sgf_output_error("Compressed point array badly oriented.");
	  result++;
	  break;
	}
      for (x = x1; x <= x2; x++)
	for (y = y1; y <= y2; y++)
	  {
	    test_board[y][x]++;
	    if (test_board[y][x] > 1)
	      {
		sgf_output_error("Multiply defined point (%d,%d).",
				 x, y);
		result++;
	      }
	  }
      if ((x1 == x2) && (y1 == y2))
	{
	  sgf_output_error("Used composite point type to describe "
                           "a single point (%d,%d).", x1, y1);
	  result++;
	}
      break;

    case SGF_VALUE_TYPE_POINT:
      x1 = v->value.point.x;
      y1 = v->value.point.y;
      if (x1 > sx || y1 > sy)
	{
	  sgf_output_error("Point coordinates (%d,%d) out of board.",
			   x1, y1);
	  result++;
	  break;
	}
      test_board[y1][x1]++;
      if (test_board[y1][x1] > 1)
	{
	  sgf_output_error("Multiply defined point (%d,%d).",
			   x1, y1);
	  result++;
	}
      break;

    default:
      break;
    }
  return result;
}

static void reset_points(void)
{
  memset(test_board, 0, sizeof(test_board));
}

static int check_points(SGFPropertyValue *v)
{
  int sx, sy;
  if (current_size == NULL)
    {
      sx = 19; sy = 19; /* Assumedly */
    }
  else if (current_size->type != SGF_VALUE_TYPE_INT)
    {
      sx = current_size->value.composed->v1.value.int_val;
      sy = current_size->value.composed->v2.value.int_val;
    }
  else
    {
      sy = sx = current_size->value.int_val;      
    }
  if (sx > 19 || sy > 19) return 0; /* > 19x19 board not currently supported */
  return checkp(v, sx, sy);
}

static int sgf_csv(SGFTree *t, int depth)
{
  int result = 0;
  SGFTree *i;
  SGFProperty *p;
  const SGFPropertySpec *s = NULL;
  int has_move_prop = 0;
  int has_setup_prop = 0;

  if (depth == 1) /* root node */
    {
      current_size = NULL;

      for (p = t->properties; p != NULL; p = p->next)
	{
	  if (p->id == SGF_PROP_SZ)
	    current_size = &(p->value);
	}

      if (current_size == NULL)
	{
	  sgf_output_error("Root node does not define board size "
			   "(assume 19 x 19).");
	  result++;
	}
    }

  for (p = t->properties; p != NULL; p = p->next)
    {
      misc_counter[p->id]++;

      s = find_property_spec_by_id(p->id);

      if (misc_counter[p->id] > 1 && p->id != SGF_PROP_UNKNOWN)
	{
	  sgf_output_error("Multiple instances of the property `%s'.",
			   s->descr);
	  result++;
	}

      game_info_counter[p->id]++;

      switch (s->mode)
	{
	case PM_NONE:
	  break;
	    
	case PM_SETUP:
	  has_setup_prop++;
	  if (has_move_prop)
	    {
	      sgf_output_error("Setup property `%s' in a "
			       "node with move properties.", s->descr);
	      result++;
	    }
	  break;

	case PM_MOVE:
	  has_move_prop++;
	  if (has_setup_prop)
	    {
	      sgf_output_error("Move property `%s' in a "
			       "node with setup properties.", s->descr);
	      result++;
	    }
	  break;

	case PM_ROOT:
	  if (depth != 1)
	    {
	      sgf_output_error("Root property `%s' in a non-root node.",
			       s->descr);
	      result++;
	    }
	  break;

	case PM_GAMEINFO:
	  if (game_info_counter[p->id] != 1)
	    {
	      sgf_output_error("Multiple game info properties `%s'.",
			       s->descr);
	      result++;
	    }
	  break;
	}
    }

  reset_points();
  for (p = t->properties; p != NULL; p = p->next)
    {
      if (p->id == SGF_PROP_AB ||
	  p->id == SGF_PROP_AE ||
	  p->id == SGF_PROP_AW)
	result += check_points(&(p->value));
    }

  reset_points();
  for (p = t->properties; p != NULL; p = p->next)
    {
      if (p->id == SGF_PROP_CR ||
	  p->id == SGF_PROP_MA ||
	  p->id == SGF_PROP_SL ||
	  p->id == SGF_PROP_SQ ||
	  p->id == SGF_PROP_TR)
	result += check_points(&(p->value));
    }

  reset_points();
  for (p = t->properties; p != NULL; p = p->next)
    {
      if (p->id == SGF_PROP_TW ||
	  p->id == SGF_PROP_TB)
	result += check_points(&(p->value));
    }

  for (p = t->properties; p != NULL; p = p->next)
    {
      reset_points();
      result += check_points(&(p->value));
    }

  if (misc_counter[SGF_PROP_DM] +
      misc_counter[SGF_PROP_GB] +
      misc_counter[SGF_PROP_GW] +
      misc_counter[SGF_PROP_UC] > 1)
    {
      sgf_output_error("Mixed DM, GB, GW and UC properties.");
      result++;
    }

  if (misc_counter[SGF_PROP_BM] +
      misc_counter[SGF_PROP_DO] +
      misc_counter[SGF_PROP_IT] +
      misc_counter[SGF_PROP_TE] > 1)
    {
      sgf_output_error("Mixed BM, DO, IT and TE properties.");
      result++;
    }

  if ((misc_counter[SGF_PROP_BM] +
       misc_counter[SGF_PROP_DO] +
       misc_counter[SGF_PROP_IT] +
       misc_counter[SGF_PROP_TE]) > 0 &&
      (misc_counter[SGF_PROP_B] + misc_counter[SGF_PROP_W]) == 0)
    {
      sgf_output_error("Move annotation without a move.");
      result++;
    }

  if (misc_counter[SGF_PROP_B] && misc_counter[SGF_PROP_W])
    {
      sgf_output_error("B and W properties mixed within a node.");
      result++;
    }

  if (misc_counter[SGF_PROP_KO] && !(misc_counter[SGF_PROP_W] ||
				     misc_counter[SGF_PROP_B]))
    {
      sgf_output_error("Ko property in a node without a move.");
      result++;
    }
      
  for (p = t->properties; p != NULL; p = p->next)
    {
      misc_counter[p->id]--;
    }

  for (i = t->first_child; i != NULL; i = i->next_sibling)
    {
      result += sgf_csv(i, depth + 1);
    }

  for (p = t->properties; p != NULL; p = p->next)
    {
      game_info_counter[p->id]--;
    }

  return result;
}

int sgf_check_semantic_validity(SGFTree *t)
{
  int i;

  for (i = 0; i < SGF_NUM_PROPERTIES; i++)
    {
      game_info_counter[i] = 0;
      misc_counter[i] = 0;
    }
  current_size = NULL;

  return sgf_csv(t, 0);
}

SGFTree *sgf_find_common_ancestor(SGFTree *t1, SGFTree *t2)
{
  int d1 = 0, d2 = 0;
  SGFTree *i;

  sgf_assert(t1 != NULL);
  sgf_assert(t2 != NULL);

  /* Calculate depths */

  for (i = t1; i != NULL; i = i->parent) d1++;
  for (i = t2; i != NULL; i = i->parent) d2++;

  /* Descend to the highest common depth. */

  while (d1 > d2) { t1 = t1->parent; d1--; }
  while (d2 > d1) { t2 = t2->parent; d2--; }

  while (t1 != t2 && t1 != NULL)
    {
      t1 = t1->parent; t2 = t2->parent;
    }
  return t1;
}

void sgf_set_compatibility_mode(int mode)
{
  compat_mode = mode;
}

static void uncompress_here(SGFTree *t, int sx, int sy)
{
  SGFProperty *p;
  const SGFPropertySpec *spec;
  SGFValueList *l;
  int x, y;
  int x1, y1, x2, y2;

  for (p = t->properties; p != NULL; p = p->next)
    {
      spec = find_property_spec_by_id(p->id);
      if (spec->parse_as == PT_LIST_OF_POINTS ||
	  spec->parse_as == PT_ELIST_OF_POINTS)
	{
	  sgf_assert(p->value.type == SGF_VALUE_TYPE_LIST);
	  
	  l = p->value.value.list;

	  memset(test_board, 0, sizeof(test_board));

	  /* Iterate through the values. Because `p' must have been
	     parsed as a list of points, the values can be only
	     points or composed point pairs. */

	  while (l != NULL)
	    {
	      if (l->value.type == SGF_VALUE_TYPE_POINT)
		{
		  test_board[l->value.value.point.x]
		    [l->value.value.point.y] = 1;
		}
	      else if (l->value.type == SGF_VALUE_TYPE_COMPOSED)
		{
		  x1 = l->value.value.composed->v1.value.point.x;
		  y1 = l->value.value.composed->v1.value.point.y;
		  x2 = l->value.value.composed->v2.value.point.x;
		  y2 = l->value.value.composed->v2.value.point.y;
		  for (x = x1; x <= x2; x++)
		    {
		      for (y = y1; y <= y2 ; y++)
			{
			  test_board[x][y] = 1;
			}
		    }
		}
	      l = l->next;
	    }

	  /* Discard the old value list. */
	  sgf_free_value_data(&p->value);
	  p->value.value.list = NULL;

	  /* Create a new list. */
	  for (x = 0; x < sx; x++)
	    {
	      for (y = 0; y < sy; y++)
		{
		  if (test_board[x][y])
		    {
		      sgf_add_to_list(t, p->id, SGF_VALUE_TYPE_POINT,
				      x, y);
		    }
		}
	    }
	}
    }
}

static void uncompress_point_lists(SGFTree *t, int sx, int sy)
{
  SGFTree *i;
  SGFProperty *p;

  /* Get an overriding size specification. */

  p = sgf_get_property(t, SGF_PROP_SZ);

  if (p != NULL)
    {
      if (p->value.type == SGF_VALUE_TYPE_INT)
	{
	  sx = p->value.value.int_val;
	  sy = sx;
	}
      else if (p->value.type == SGF_VALUE_TYPE_COMPOSED)
	{
	  sx = p->value.value.composed->v1.value.int_val;
	  sy = p->value.value.composed->v2.value.int_val;
	}
    }

  uncompress_here(t, sx, sy);
  for (i = t->first_child; i != NULL; i = i->next_sibling)
    uncompress_point_lists(i, sx, sy);
}

void sgf_uncompress_point_lists(SGFTree *t)
{
  /* The default size is 19 x 19. */
  uncompress_point_lists(t, 19, 19);
}

static void do_compress(SGFTree *t, SGFPropertyID id,
			int count, int sx, int sy)
{
  /* The used algorithm is the following: find the top-leftmost marked
     intersection (x1, y1). Scan to right until we hit the board edge
     at x2 - 1 or a non-marked intersection at x2.  Then descend from
     y1 until we hit the board edge at y2 - 1 or a value of y2 such
     that some of the intersections (x1,y2)..(x2-1,y2) does not have
     the mark.  Then create the composed point [x1y1:x2y2] and remove
     the rectangle from test_board. Continue until `count' is zero; we
     decrease `count' by one for every single mark consumed. */
  
  int x1, y1, x2, y2;
  int i, j;
  SGFComposedValue *v;

  for (x1 = 0; x1 < sx; x1++)
    for (y1 = 0; y1 < sy; y1++)
      {
	if (count == 0) return;

	sgf_assert(count >= 0);

	if (!test_board[x1][y1]) continue;
	
	x2 = x1;
	while (x2 < sx && test_board[x2][y1])
	  x2++;
	y2 = y1;
	while (y2 < sy)
	  {
	    for (i = x1; i < x2 ; i++)
	      {
		if (!test_board[i][y2])
		  goto done;
	      }
	    y2++;
	  }
      done:
	/* Add a single point as a single point to conform
	   with the SGF standard. */
	if (x1 == x2 - 1 && y1 == y2 - 1)
	  {
	    sgf_add_to_list(t, id, SGF_VALUE_TYPE_POINT, x1, y1);
	    count--;
	  }
	else
	  {
	    v = sgf_add_composed_to_list(t, id);
	    v->v1.type = SGF_VALUE_TYPE_POINT;
	    v->v2.type = SGF_VALUE_TYPE_POINT;
	    v->v1.value.point.x = x1;
	    v->v1.value.point.y = y1;
	    v->v2.value.point.x = x2-1;
	    v->v2.value.point.y = y2-1;
	    count -= ((x2-x1)*(y2-y1));
	    for (j = y1; j < y2; j++)
	      for (i = x1; i < x2; i++)
		test_board[i][j] = 0;
	  }
      }
  sgf_assert(count == 0);
}

static void compress_here(SGFTree *t, int sx, int sy)
{
  SGFProperty *p;
  const SGFPropertySpec *spec;
  SGFValueList *l;
  int x, y;
  int x1, y1, x2, y2;
  int count;

  for (p = t->properties; p != NULL; p = p->next)
    {
      spec = find_property_spec_by_id(p->id);
      if (spec->parse_as == PT_LIST_OF_POINTS ||
	  spec->parse_as == PT_ELIST_OF_POINTS)
	{
	  sgf_assert(p->value.type == SGF_VALUE_TYPE_LIST);
	  
	  l = p->value.value.list;

	  memset(test_board, 0, sizeof(test_board));
	  count = 0;

	  /* Iterate through the values. Because `p' must have been
	     parsed as a list of points, the values can be only
	     points or composed point pairs. */

	  while (l != NULL)
	    {
	      if (l->value.type == SGF_VALUE_TYPE_POINT)
		{

		  /* This condition should always evaluate to true but
		     check anyway. */

		  if (test_board[l->value.value.point.x]
		      [l->value.value.point.y] == 0)
		    {
		      test_board[l->value.value.point.x]
			[l->value.value.point.y] = 1;
		      count++;
		    }
		}
	      else if (l->value.type == SGF_VALUE_TYPE_COMPOSED)
		{
		  x1 = l->value.value.composed->v1.value.point.x;
		  y1 = l->value.value.composed->v1.value.point.y;
		  x2 = l->value.value.composed->v2.value.point.x;
		  y2 = l->value.value.composed->v2.value.point.y;
		  for (x = x1; x <= x2; x++)
		    {
		      for (y = y1; y <= y2 ; y++)
			{

			  /* This condition should always evaluate to
		             true but check anyway. */

			  if (test_board[x][y] == 0)
			    {
			      test_board[x][y] = 1;
			      count++;
			    }
			}
		    }
		}
	      l = l->next;
	    }

	  /* Discard the old value list. */
	  sgf_free_value_data(&p->value);
	  p->value.value.list = NULL;

	  /* Create a new list. This is done in a separate function in
	     order to avoid cluttering this one too much. */

	  do_compress(t, p->id, count, sx, sy);
	}
    }
}

static void compress_point_lists(SGFTree *t, int sx, int sy)
{
  SGFTree *i;
  SGFProperty *p;

  /* Get an overriding size specification. */

  p = sgf_get_property(t, SGF_PROP_SZ);

  if (p != NULL)
    {
      if (p->value.type == SGF_VALUE_TYPE_INT)
	{
	  sx = p->value.value.int_val;
	  sy = sx;
	}
      else if (p->value.type == SGF_VALUE_TYPE_COMPOSED)
	{
	  sx = p->value.value.composed->v1.value.int_val;
	  sy = p->value.value.composed->v2.value.int_val;
	}
    }

  compress_here(t, sx, sy);
  for (i = t->first_child; i != NULL; i = i->next_sibling)
    compress_point_lists(i, sx, sy);
}

void sgf_compress_point_lists(SGFTree *t)
{
  compress_point_lists(t, 19, 19);
  return;
}
