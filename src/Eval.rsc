module Eval

import AST;
import Resolve;

/*
 * Implement big-step semantics for QL
 */
 
// NB: Eval may assume the form is type- and name-correct.


// Semantic domain for expressions (values)
data Value
  = vint(int n)
  | vbool(bool b)
  | vstr(str s)
  | vunknown()
  ;

// The value environment
alias VEnv = map[str name, Value \value];

// Modeling user input
data Input = input(str question, Value \value);

Value ATypeToVal(integer()) = vint(0);
Value ATypeToVal(boolean()) = vbool(false);
Value ATypeToVal(string()) = vstr("");

// produce an environment which for each question has a default value
// (e.g. 0 for int, "" for str, false for bool)
VEnv initialEnv(AForm f) {
  VEnv venv = ();
  for(/AQuestion q <- f.questions) {
    venv += (q.name: ATypeToVal(q.t) | q has name);
  }
  return venv;
}

// Because of out-of-order use and declaration of questions
// we use the solve primitive in Rascal to find the fixpoint of venv.
VEnv eval(AForm f, Input inp, VEnv venv) {
  return solve (venv) {
    venv = evalOnce(f, inp, venv);
  }
}

VEnv evalOnce(AForm f, Input inp, VEnv venv) {
  for(AQuestion q <- f.questions) {
	venv = eval(q, inp, venv);
  }
  return venv; 
}

VEnv eval(AQuestion q, Input inp, VEnv venv) {
  // evaluate conditions for branching,
  switch (q) {
  	case question(str label, str name, AType _):
  		if(name == inp.question) { venv[name] = inp.\value; }
  		
  	case computedquestion(str label, str name, AType t, AExpr ae):
  		venv[name] = eval(ae, venv);
  	
  	case blockquestion(list[AQuestion] questions):
  		for(AQuestion q <- questions) { venv = eval(q, inp, venv); }
  		
  	// evaluate inp and computed questions to return updated VEnv
  	case ifelsequestion(AExpr ae, list[AQuestion] ifquestions, list[AQuestion] elsequestions): {
  		for(AQuestion ifq <- ifquestions, AQuestion elseq <- elsequestions){
	  		if(eval(ae, venv) == vbool(true) ){
				venv = eval(ifq, inp, venv);
	  		} else {
				venv = eval(elseq, inp, venv);
			}
		}
  	}
  	
  	case ifquestion(AExpr ae, list[AQuestion] ifquestions):
  	{
		for(AQuestion ifq <- ifquestions){
			if(eval(ae, venv) == vbool(true) ){
				venv = eval(ifq, inp, venv);
			}
		}
  	}
  	
    default: throw "Unsupported question <q>";
  }
  
  return venv; 
}

// Handles evaluation cases for types (str, int, bool) and functions: "*, /, +, -, &&, ||, >, <, <=, >= , ==, !="
Value eval(AExpr e, VEnv venv) {
  switch (e) {
    case ref(str x): 			 return venv[x];
    case integer(int n): 		 return vint(n); 
    case boolean(bool b): 		 return vbool(b);
    case bracs(AExpr e): 		 return eval(e, venv);
    case not(AExpr e):           return vbool(!eval(e, venv));
    case mult(AExpr l, AExpr r): return vint(eval(l, venv).n * eval(r, venv).n);
    case div(AExpr l, AExpr r):  return vint(eval(l, venv).n / eval(r, venv).n);
    case add(AExpr l, AExpr r):  return vint(eval(l, venv).n + eval(r, venv).n);
    case sub(AExpr l, AExpr r):  return vint(eval(l, venv).n - eval(r, venv).n);
    case and(AExpr l, AExpr r):  return vbool(eval(l, venv).b && eval(r, venv).b);
    case or(AExpr l, AExpr r):   return vbool(eval(l, venv).b || eval(r, venv).b);
    case gt(AExpr l, AExpr r):   return vbool(eval(l, venv).n > eval(r, venv).n);
    case lt(AExpr l, AExpr r):   return vbool(eval(l, venv).n < eval(r, venv).n);
    case leq(AExpr l, AExpr r):  return vbool(eval(l, venv).n <= eval(r, venv).n);
    case geq(AExpr l, AExpr r):  return vbool(eval(l, venv).n >= eval(r, venv).n);
    case eq(AExpr l, AExpr r):   return vbool(eval(l, venv).n == eval(r, venv).n);
    case neq(AExpr l, AExpr r):  return vbool(eval(l, venv).n != eval(r, venv).n); 
    default: throw "Unsupported expression <e>";
  }
} 