/* -*-c++-*- */

%{
/*
 * parse_mdl.y - parser for an IC-CAP MDL data file
 *
 * Copyright (C) 2006 Stefan Jahn <stefan@lkcc.org>
 *
 * This is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 * 
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this package; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street - Fifth Floor,
 * Boston, MA 02110-1301, USA.  
 *
 * $Id: parse_mdl.y,v 1.2 2006-08-21 08:10:30 raimi Exp $
 *
 */

#if HAVE_CONFIG_H
# include <config.h>
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#define YYERROR_VERBOSE 42
#define YYDEBUG 1
#define YYMAXDEPTH 1000000

#include "object.h"
#include "complex.h"
#include "vector.h"
#include "check_mdl.h"

%}

%name-prefix="mdl_"

%token LINK
%token Identifier
%token String
%token InvalidCharacter
%token Real
%token t_LINK
%token t_VIEW
%token t_TABLE
%token t_PSTABLE
%token t_CNTABLE
%token t_BLKEDIT
%token t_HYPTABLE
%token t_ELEMENT
%token t_DATA
%token t_DATASET
%token t_DATASIZE
%token t_POINT
%token t_MEMBER
%token t_LIST
%token t_PLOTOPTIMIZEROPT
%token t_PLOTERROR
%token t_TYPE
%token t_CIRCUITDECK
%token t_PARAM
%token t_CONNPAIR

%union {
  char * ident;
  double f;
  struct mdl_point_t * point;
  struct mdl_dataset_t * dset;
  struct mdl_datasize_t * dsize;
  struct mdl_link_t * link;
  struct mdl_data_t * data;
  struct mdl_dcontent_t * dcontent;
  struct mdl_lcontent_t * lcontent;
  struct mdl_element_t * element;
  struct mdl_hyptable_t * hyptable;
  struct mdl_table_t * table;
}

%type <ident> Identifier t_LINK String TYPE_Line
%type <point> POINT_Line PointList Point
%type <f> Real
%type <dset> DSContent DATASET_Definition
%type <link> LINK_Definition
%type <lcontent> LinkContent LinkContentList
%type <dcontent> DataContent DataContentList
%type <data> DATA_Definition
%type <dsize> DATASIZE_Line
%type <element> ELEMENT_Line HypTableContent HypTableContentList
%type <element> TableContent TableContentList
%type <hyptable> HYPTABLE_Definition
%type <table> TABLE_Definition

%%

Input:
  LINK_Definition {
    mdl_root = $1;
  }
;

TableContent:
  VIEW_Line {
    $$ = NULL;
  }
  | ELEMENT_Line {
    $$ = $1;
  }
  | TABLE_Definition {
    $$ = NULL;
  }
;

TableContentList: /* nothing */ { $$ = NULL; }
  | TableContent TableContentList {
    if ($1) {
      $1->next = $2;
      $$ = $1;
    } else {
      $$ = $2;
    }
  }
;

HypTableContent:
  VIEW_Line {
    $$ = NULL;
  }
  | ELEMENT_Line {
    $$ = $1;
  }
;

HypTableContentList: /* nothing */ { $$ = NULL; }
  | HypTableContent HypTableContentList {
    if ($1) {
      $1->next = $2;
      $$ = $1;
    } else {
      $$ = $2;
    }
  }
;

ConnTableContent:
  CONNPAIR_Line
;

ConnTableContentList: /* nothing */ { }
  | ConnTableContent ConnTableContentList {
  }
;

LinkContent:
  VIEW_Line {
    $$ = NULL;
  }
  | LIST_Line {
    $$ = NULL;
  }
  | MEMBER_Line {
    $$ = NULL;
  }
  | TABLE_Definition {
    $$ = (struct mdl_lcontent_t *) calloc (sizeof (struct mdl_lcontent_t), 1);
    $$->type = t_TABLE;
    $$->table = $1;
  }
  | LINK_Definition {
    $$ = (struct mdl_lcontent_t *) calloc (sizeof (struct mdl_lcontent_t), 1);
    $$->type = t_LINK;
    $$->link = $1;
  }
  | DATA_Definition {
    $$ = (struct mdl_lcontent_t *) calloc (sizeof (struct mdl_lcontent_t), 1);
    $$->type = t_DATA;
    $$->data = $1;
  }
;

LinkContentList: /* nothing */ { $$ = NULL; }
  | LinkContent LinkContentList {
    if ($1) {
      $1->next = $2;
      $$ = $1;
    } else {
      $$ = $2;
    }
  }
;

DataContent:
  PLOTOPTIMIZEROPT_Line {
    $$ = NULL;
  }
  | PLOTERROR_Line {
    $$ = NULL;
  }
  | TABLE_Definition {
    $$ = NULL;
  }
  | PSTABLE_Definition {
    $$ = NULL;
  }
  | CNTABLE_Definition {
    $$ = NULL;
  }
  | HYPTABLE_Definition {
    $$ = (struct mdl_dcontent_t *) calloc (sizeof (struct mdl_dcontent_t), 1);
    $$->type = t_HYPTABLE;
    $$->hyptable = $1;
  }
  | DATASET_Definition {
    $$ = (struct mdl_dcontent_t *) calloc (sizeof (struct mdl_dcontent_t), 1);
    $$->type = t_DATASET;
    $$->data = $1;
  }
  | BLKEDIT_Definition {
    $$ = NULL;
  }
  | CIRCUITDECK_Definition {
    $$ = NULL;
  }
;

DataContentList: /* nothing */ { $$ = NULL; }
  | DataContent DataContentList {
    if ($1) {
      $1->next = $2;
      $$ = $1;
    } else {
      $$ = $2;
    }
  }
;

PSContent:
  PARAM_Line
;

PSContentList: /* nothing */ { }
  | PSContent PSContentList {
  }
;

DSContent:
  DATASIZE_Line TYPE_Line PointList {
    $$ = (struct mdl_dataset_t *) calloc (sizeof (struct mdl_dataset_t), 1);
    $$->dsize = $1;
    $$->type1 = $2;
    $$->data1 = $3;
  }
  | DATASIZE_Line TYPE_Line PointList TYPE_Line PointList {
    $$ = (struct mdl_dataset_t *) calloc (sizeof (struct mdl_dataset_t), 1);
    $$->dsize = $1;
    $$->type1 = $2;
    $$->data1 = $3;
    $$->type2 = $4;
    $$->data2 = $5;
  }
;

Point:
  POINT_Line
;

PointList: /* nothing */ { $$ = NULL; }
  | Point PointList {
    $1->next = $2;
    $$ = $1;
  }
;

ELEMENT_Line:
  t_ELEMENT Real String String String {
    $$ = (struct mdl_element_t *) calloc (sizeof (struct mdl_element_t), 1);
    $$->number = (int) $2;
    $$->name = $3;
    $$->value = $4;
    $$->attr = $5;
  }
  | t_ELEMENT Real String String {
    $$ = (struct mdl_element_t *) calloc (sizeof (struct mdl_element_t), 1);
    $$->number = (int) $2;
    $$->name = $3;
    $$->value = $4;
  }
  | t_ELEMENT String String {
    $$ = (struct mdl_element_t *) calloc (sizeof (struct mdl_element_t), 1);
    $$->name = $2;
    $$->value = $3;
  }
;

VIEW_Line:
  t_VIEW Identifier Real String {
    free ($2);
    free ($4);
  }
;

TABLE_Definition:
  t_TABLE String '{' TableContentList '}' {
    $$ = (struct mdl_table_t *) calloc (sizeof (struct mdl_table_t), 1);
    $$->name = $2;
    $$->data = $4;
  }
;

LINK_Definition:
  LINK t_LINK String '{' LinkContentList '}' {
    $$ = (struct mdl_link_t *) calloc (sizeof (struct mdl_link_t), 1);
    $$->name = $3;
    $$->type = $2;
    $$->content = $5;
  }
;

DATA_Definition:
  t_DATA '{' DataContentList '}' {
    $$ = (struct mdl_data_t *) calloc (sizeof (struct mdl_data_t), 1);
    $$->content = $3;
  }
;

PSTABLE_Definition:
  t_PSTABLE String '{' PSContentList '}' {
    free ($2);
  }
;

CIRCUITDECK_Definition:
  t_CIRCUITDECK '{' '}'
;

BLKEDIT_Definition:
  t_BLKEDIT String '{' '}' {
    free ($2);
  }
;

CNTABLE_Definition:
  t_CNTABLE String '{' ConnTableContentList '}' {
    free ($2);
  }
;

HYPTABLE_Definition:
  t_HYPTABLE String '{' HypTableContentList '}' {
    $$ = (struct mdl_hyptable_t *) calloc (sizeof (struct mdl_hyptable_t), 1);
    $$->name = $2;
    $$->data = $4;
  }
;

DATASET_Definition:
  t_DATASET '{' DSContent '}' {
    $$ = $3;
  }
;

DATASIZE_Line:
  t_DATASIZE Identifier Real Real Real {
    $$ = (struct mdl_datasize_t *) calloc (sizeof (struct mdl_datasize_t), 1);
    $$->type = $2;
    $$->size = (int) $3;
    $$->x = (int) $4;
    $$->y = (int) $5;
  }
;

TYPE_Line:
  t_TYPE Identifier {
    $$ = $2;
  }
;

POINT_Line:
  t_POINT Real Real Real Real Real {
    $$ = (struct mdl_point_t *) calloc (sizeof (struct mdl_point_t), 1);
    $$->n = (int) $2;
    $$->x = (int) $3;
    $$->y = (int) $4;
    $$->r = $5;
    $$->i = $6;
  }
;

LIST_Line:
  t_LIST t_LINK String {
    free ($2);
    free ($3);
  }
;

PLOTOPTIMIZEROPT_Line:
  t_PLOTOPTIMIZEROPT Identifier Real {
    free ($2);
  }
;

PLOTERROR_Line:
  t_PLOTERROR Identifier Real {
    free ($2);
  }
;

MEMBER_Line:
  t_MEMBER t_LINK String {
    free ($2);
    free ($3);
  }
;

PARAM_Line:
  t_PARAM Identifier String {
    free ($2);
    free ($3);
  }
;

CONNPAIR_Line:
  t_CONNPAIR String String {
    free ($2);
    free ($3);
  }
;

%%

int mdl_error (char * error) {
  fprintf (stderr, "line %d: %s\n", mdl_lineno, error);
  return 0;
}
