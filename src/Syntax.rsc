module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id name "{" Question* questions"}"; 

// question, computed question, blockquestion, if-then-else, if-then
syntax Question
  = question: Str label Id name ":" Type t
  | computedquestion: Str label Id name ":" Type t "=" Expr e 
  | blockquestion: "{" Question* questions "}"
  | ifelsequestion: "if" "(" Expr e ")" "{" Question* ifquestions "}" "else" "{" Question* elsequestions "}"
  | ifquestion: "if" "(" Expr e ")" "{" Question* ifquestions "}"
  ; 

// operators: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
syntax Expr 
  = id: Id identifier \ "true" \ "false" // true/false are reserved keywords.
  | \string: Str string 
  | \integer: Int integer
  | \boolean: Bool boolean 
  | bracs: "(" Expr e ")"
  | not: "!" Expr e
  > left (
  	mult: Expr l "*" Expr r
  | div: Expr l "/" Expr r
  )
  > left (
    add: Expr l "+" Expr r
  | sub: Expr l "-" Expr r
  )
  > left (
    and: Expr l "&&" Expr r
  | or: Expr l "||" Expr r
  )	
  > non-assoc (
    gt: Expr l "\>" Expr r
  | lt: Expr l "\<" Expr r
  | leq: Expr l "\<=" Expr r
  | geq: Expr l "\>=" Expr r
  | eq: Expr l "==" Expr r
  | neq: Expr l "!=" Expr r
  )
  ;
  
syntax Type
  = "string"
  | "integer"
  | "boolean"
  ;  
  
lexical Str = "\"" ![\"]* "\"" ; // we have string defined as: a quote, anything but a quote, and another quote

lexical Int // int can be negative or positive 1..9 followed by * 0..9, or a simple 0
  = "-"?[1-9][0-9]*
  | [0]
  ;

lexical Bool = "true" | "false"; // strings for true and false literals



