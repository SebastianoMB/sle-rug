module AST

/*
 * Abstract Syntax for QL
 */

data AForm(loc src = |tmp:///|)
  = form(str name, list[AQuestion] questions)
  ; 
  
data AQuestion(loc src = |tmp:///|)
  = question(str label, str name, AType t)
  | computedquestion(str label, str name, AType t, AExpr e)
  | blockquestion(list[AQuestion] questions)
  | ifelsequestion(AExpr e, list[AQuestion] ifquestions, list[AQuestion] elsequestions)
  | ifquestion(AExpr e, list[AQuestion] ifquestions)
  ; 

data AExpr(loc src = |tmp:///|)
  = ref(str name)
  | string(str string)
  | integer(int n)
  | boolean(bool b)
  | bracs(AExpr e)
  | not(AExpr e)
  | mult(AExpr l, AExpr r)
  | div(AExpr l, AExpr r)
  | add(AExpr l, AExpr r)
  | sub(AExpr l, AExpr r)
  | and(AExpr l, AExpr r)
  | or(AExpr l, AExpr r)
  | gt(AExpr l, AExpr r)
  | lt(AExpr l, AExpr r)
  | leq(AExpr l, AExpr r)
  | geq(AExpr l, AExpr r)
  | eq(AExpr l, AExpr r)
  | neq(AExpr l, AExpr r)
  ;

data AType(loc src = |tmp:///|)
  = integer()
  | boolean()
  | string();
