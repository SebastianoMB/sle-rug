module Check

import AST;
import Resolve;
import Message; // see standard library
import Set;

data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown()
  ;
  
Type ATypeToType(boolean()) = tbool();
Type ATypeToType(integer()) = tint();
Type ATypeToType(string()) = tstr();
default Type ATypeToType(AType _) = tunknown();

// the type environment consisting of defined questions in the form 
alias TEnv = rel[loc def, str name, str label, Type \type];

// Deep matching form with `for (/question(...) := f) {...}` 
TEnv collect(AForm f) {
	TEnv tenv = {};	
	for(/AQuestion q <- f.questions) {
		tenv += {<q.src, q.name, q.label, ATypeToType(q.t)> | q has name};
	}
	return tenv;
}

set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
	set[Message] msgs = {};
	 msgs = ( {} | it + check(q, tenv, useDef) | /AQuestion q := f ) + ( {} | it + check(e, tenv, useDef) | /AExpr e := f);
	if(msgs == {} ){
		return {info("No errors/warning found", f.src)};
	}
	return msgs;
}


// Checks questions for errors
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
	set[Message] msgs = {};
			 
	// error: Reference to undefined question
	msgs += {error("Reference to undefined question", q.src)
			 | q has expr && q.expr.src notin useDef<uses>};
					 
    // error: Duplicate question declaration with different types
	msgs += {error("Duplicate question declaration \"<name>\" with different types", q.src) 
		     | q has name && size((tenv<1,3>)[q.name]) > 1 };
		     
 	// error: type of conditions is not boolean
	msgs += {error("Conditions must be of type boolean, instead is: <typeOf(q.expr, tenv, useDef)>", q.expr.src) 
			 | q has expr && typeOf(q.expr, tenv, useDef) != tbool()};
			 
	// error: type of computed question does not match type of expression	     
	msgs += {error("Type of computed question := \"<ATypeToType(q.t)>\" does not match type of expression: \"<typeOf(q.expr, tenv, useDef)>\" ", q.src) // 
			 | q has expr && ATypeToType(q.t) != typeOf(q.expr, tenv, useDef) };
			  
	// warning: duplicated labels
	msgs += {warning("Duplicate labels \"<q.label>\"", q.src) 
			 | q has label && size((tenv<2,0>)[q.label]) > 1};

	return msgs;
}

// Checks operand compatibility with operators, if incompatible then error is returned
set[Message] check(ref(str name, src = loc u), _, UseDef useDef) 
	= {error("Question not declared", u) 
	| useDef[u] == {}};
	
set[Message] check(a:not(AExpr e), TEnv tenv, UseDef useDef) 
    = {error("The operand for (! \"not\")  expression is invalid", a.src) 
	| checkTypesExprs(l, r, tenv, useDef, tbool())}; 
	
set[Message] check(a:mult(AExpr l, AExpr r), TEnv tenv, UseDef useDef) 
    = {error("The operand for (* \"multiplication\") expression is invalid", a.src) 
	| checkTypesExprs(l, r, tenv, useDef, tint())}; 

set[Message] check(a:div(AExpr l, AExpr r), TEnv tenv, UseDef useDef) 
    = {error("The operand for (\\ \"division\") expression is invalid", a.src) 
	| checkTypesExprs(l, r, tenv, useDef, tint())}; 

set[Message] check(a:add(AExpr l, AExpr r), TEnv tenv, UseDef useDef)
    = {error("The operand for (+ \"addition\") expression is invalid", a.src) 
	| checkTypesExprs(l, r, tenv, useDef, tint())}; 

set[Message] check(a:sub(AExpr l, AExpr r), TEnv tenv, UseDef useDef) 
    = {error("The operand for (- \"subtraction\") expression is invalid", a.src) 
	| checkTypesExprs(l, r, tenv, useDef, tint())}; 

set[Message] check(a:and(AExpr l, AExpr r), TEnv tenv, UseDef useDef)
    = {error("The operand for (&& \"and\") expression is invalid", a.src) 
	| checkTypesExprs(l, r, tenv, useDef, tbool())}; 

set[Message] check(a:or(AExpr l, AExpr r), TEnv tenv, UseDef useDef)
    = {error("The operand for (|| \"or\") expression is invalid", a.src) 
	| checkTypesExprs(l, r, tenv, useDef, tbool())}; 

set[Message] check(a:gt(AExpr l, AExpr r), TEnv tenv, UseDef useDef) 
    = {error("The operand for (\> \"greater than\") expression is invalid", a.src) 
	| checkTypesExprs(l, r, tenv, useDef, tbool())}; 

set[Message] check(a:lt(AExpr l, AExpr r), TEnv tenv, UseDef useDef)
    = {error("The operand for (\< \"less than\") expression is invalid", a.src) 
	| checkTypesExprs(l, r, tenv, useDef, tbool())}; 

set[Message] check(a:leq(AExpr l, AExpr r), TEnv tenv, UseDef useDef)
    = {error("The operand for (\<= \"less or equal\") expression is invalid", a.src) 
	| checkTypesExprs(l, r, tenv, useDef, tbool())}; 

set[Message] check(a:geq(AExpr l, AExpr r), TEnv tenv, UseDef useDef) 
    = {error("The operand for (\>= \"greater or equal\") expression is invalid", a.src) 
    | checkTypesExprs(l, r, tenv, useDef, tbool())}; 

set[Message] check(a:eq(AExpr l, AExpr r), TEnv tenv, UseDef useDef)
    = {error("The operand for (== \"equality\") expression is invalid", a.src) 
    | checkTypesExprs(l, r, tenv, useDef, tbool())}; 

set[Message] check(a:neq(AExpr l, AExpr r), TEnv tenv, UseDef useDef) 
    = {error("The operand for (!= \"not equal\") expression is invalid", a.src) 
	| checkTypesExprs(l, r, tenv, useDef, tbool())}; 
		
default set[Message] check(AExpr _, TEnv _, UseDef _) = {};

bool checkTypesExprs(AExpr l, AExpr r, TEnv tenv, UseDef useDef, Type t) {
	return (typeOf(l, tenv, useDef) != t && typeOf(r, tenv, useDef) != t);
}

// returns the equivalent type of an expression (e.g ae1 * ae2 if both are integers then tint() is returned)
Type typeOf(ref(str x, src = loc u), TEnv tenv, UseDef useDef) = t
	when <u, loc d> <- useDef, <d, x, _, Type t> <- tenv;

Type typeOf(not(AExpr e), TEnv tenv, UseDef useDef) = tbool() 
	when typeOf(e, tenv, useDef) == tbool();

Type typeOf(bracs(AExpr e), TEnv tenv, UseDef useDef) = typeOf(e, tenv, useDef);
	
Type typeOf(mult(AExpr l, AExpr r), TEnv tenv, UseDef useDef) = tint()
	when typeOf(l, tenv, useDef) == tint() && typeOf(r, tenv, useDef) == tint();

Type typeOf(div(AExpr l, AExpr r), TEnv tenv, UseDef useDef) = tint()
	when typeOf(l, tenv, useDef) == tint() && typeOf(r, tenv, useDef) == tint();

Type typeOf(add(AExpr l, AExpr r), TEnv tenv, UseDef useDef) = tint()
	when typeOf(l, tenv, useDef) == tint() && typeOf(r, tenv, useDef) == tint();		

Type typeOf(sub(AExpr l, AExpr r), TEnv tenv, UseDef useDef) = tint()
	when typeOf(l, tenv, useDef) == tint() && typeOf(r, tenv, useDef) == tint();

Type typeOf(and(AExpr l, AExpr r), TEnv tenv, UseDef useDef) = tbool()
	when typeOf(l, tenv, useDef) == tbool() && typeOf(r, tenv, useDef) == tbool();

Type typeOf(or(AExpr l, AExpr r), TEnv tenv, UseDef useDef) = tbool()
	when typeOf(l, tenv, useDef) == tbool() && typeOf(r, tenv, useDef) == tbool();

Type typeOf(gt(AExpr l, AExpr r), TEnv tenv, UseDef useDef) = tbool()
	when typeOf(l, tenv, useDef) == tbool() && typeOf(r, tenv, useDef) == tbool();

Type typeOf(lt(AExpr l, AExpr r), TEnv tenv, UseDef useDef) = tbool()
	when typeOf(l, tenv, useDef) == tbool() && typeOf(r, tenv, useDef) == tbool();

Type typeOf(leq(AExpr l, AExpr r), TEnv tenv, UseDef useDef) = tbool()
	when typeOf(l, tenv, useDef) == tbool() && typeOf(r, tenv, useDef) == tbool();

Type typeOf(geq(AExpr l, AExpr r), TEnv tenv, UseDef useDef) = tbool()
	when typeOf(l, tenv, useDef) == tbool() && typeOf(r, tenv, useDef) == tbool();

Type typeOf(eq(AExpr l, AExpr r), TEnv tenv, UseDef useDef) = tbool()
	when typeOf(l, tenv, useDef) == tbool() && typeOf(r, tenv, useDef) == tbool();

Type typeOf(neq(AExpr l, AExpr r), TEnv tenv, UseDef useDef) = tbool()
	when typeOf(l, tenv, useDef) == tbool() && typeOf(r, tenv, useDef) == tbool();
	
Type typeOf(\integer(_), _, _) = tint();
Type typeOf(\boolean(_), _, _) = tbool();
Type typeOf(\string(_), _, _) = tstring();
default Type typeOf(AExpr, _, _) = tunknown();	
 

