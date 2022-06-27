%{
  #include <stdio.h>
  #include <stdlib.h>
  #include "defs.h"
  #include "symtab.h"

  int yyparse(void);
  int yylex(void);
  int yyerror(char *s);
  void warning(char *s);

  extern int yylineno;
  char char_buffer[CHAR_BUFFER_LENGTH];
  int error_count = 0;
  int warning_count = 0;
  int macro_idx = -1;
%}

%union {
  int i;
  char *s;
}

%token <i> _TYPE
%token _IF
%token _ELSE
%token _RETURN
%token <s> _ID
%token <s> _INT_NUMBER
%token <s> _UINT_NUMBER
%token _LPAREN
%token _RPAREN
%token _LBRACKET
%token _RBRACKET
%token _ASSIGN
%token _SEMICOLON
%token <i> _AROP
%token <i> _RELOP
%token _DEFINE
%token _IFDEF
%token _IFNDEF
%token _ENDIF
%token _DEF_ELSE

%nonassoc ONLY_IF
%nonassoc _ELSE

%%

program
  : macro_list function_list
  ;

macro_list
	: /* empty */
	| macros
	;

macros
	: macro
	| macros macro
	;

macro
	: _DEFINE _ID
		{
			if (lookup_symbol($2, MACRO) == NO_INDEX) 
				insert_symbol($2, MACRO, NO_TYPE, NO_ATR, NO_ATR);
			else
				err("redefinition of macro '%s'", $2);
		} 
	literal
	| _DEFINE _ID 
		{
			macro_idx = lookup_symbol($2, MACRO);
			if (macro_idx == NO_INDEX) 
				insert_symbol($2, MACRO, NO_TYPE, NO_ATR, NO_ATR);
			else
				err("redefinition of macro '%s'", $2);
		}
	_LPAREN _ID
	_RPAREN num_exp
	;

function_list
  : if_function
  | function_list if_function
  ;

if_function
  : function
  | def_if_part _ENDIF
  | def_if_part _DEF_ELSE function _ENDIF
  ;

function
	: type _ID _LPAREN parameter _RPAREN body
	;
  
def_if_part
	: inclusion_if _ID function
	;

inclusion_if
	: _IFDEF
	| _IFNDEF
	;

type
  : _TYPE
  ;

parameter
  : /* empty */
  | type _ID
  ;

body
  : _LBRACKET variable_list statement_list _RBRACKET
  ;

variable_list
  : /* empty */
  | variable_list variable
  ;

variable
  : type _ID _SEMICOLON
  ;

statement_list
  : /* empty */
  | statement_list statement
  ;

statement
  : compound_statement
  | assignment_statement
  | if_statement
  | return_statement
  ;

compound_statement
  : _LBRACKET statement_list _RBRACKET
  ;

assignment_statement
  : _ID _ASSIGN num_exp _SEMICOLON
  ;

num_exp
  : exp
  | num_exp _AROP exp
  ;

exp
  : literal
  | _ID
  | function_call
  | _LPAREN num_exp _RPAREN
  ;

literal
  : _INT_NUMBER
  | _UINT_NUMBER
  ;

function_call
  : _ID _LPAREN argument _RPAREN
  ;

argument
  : /* empty */
  | num_exp
  ;

if_statement
  : if_part %prec ONLY_IF
  | if_part _ELSE statement
  ;

if_part
  : _IF _LPAREN rel_exp _RPAREN statement
  ;

rel_exp
  : num_exp _RELOP num_exp
  ;

return_statement
  : _RETURN num_exp _SEMICOLON
  ;
%%

int yyerror(char *s) {
  fprintf(stderr, "\nline %d: ERROR: %s", yylineno, s);
  error_count++;
  return 0;
}

void warning(char *s) {
  fprintf(stderr, "\nline %d: WARNING: %s", yylineno, s);
  warning_count++;
}

int main() {
  int synerr;
  init_symtab();

  synerr = yyparse();

  clear_symtab();
  
  if(warning_count)
    printf("\n%d warning(s).\n", warning_count);

  if(error_count)
    printf("\n%d error(s).\n", error_count);

  if(synerr)
    return -1; //syntax error
  else
    return error_count; //semantic errors
}

