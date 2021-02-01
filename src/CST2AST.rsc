 module CST2AST

import Syntax;
import AST;

import ParseTree;
import String;
import Boolean;

/*
 * Mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 */

// Mapping of form concrete syntax to abstract syntax
AForm cst2ast(start[Form] sf) {
  return cst2ast(sf.top); // remove layout before and after form
}

AForm cst2ast((Form) `form <Id name> {<Question* questions>}` ) {
  return form("<name>", [cst2ast(q) | Question q <- questions], src=name@\loc);
}

// Mapping of question concrete syntax to abstract syntax
AQuestion cst2ast(Question q) {
  switch(q) {
  	case (Question) `<Str label> <Id name>: <Type t>`: 
  		return question("<label>", "<name>", cst2ast(t), src=q@\loc);
  	case (Question) `<Str label> <Id name>: <Type t> = <Expr e>`: 
  		return computedquestion("<label>", "<name>", cst2ast(t), cst2ast(e), src=q@\loc);
 	case (Question) `{<Question* questions>}`: 
 		return blockquestion([cst2ast(q) | Question q <- questions], src=q@\loc);
 	case (Question) `if (<Expr e>) { <Question* ifquestions> } else { <Question* elsequestions> }`: 
 		return ifelsequestion(cst2ast(e), [cst2ast(ifq) | ifq <- ifquestions], [cst2ast(elseq) | elseq <- elsequestions], src=q@\loc );
 	case (Question) `if (<Expr e>) { <Question* ifquestions> }` : 
 		return ifquestion(cst2ast(e), [cst2ast(ifq) | ifq <- ifquestions], src=q@\loc);
    default: throw "Unhandled question: <q>";
  }
}

// Mapping of expression concrete syntax to abstract syntax
AExpr cst2ast(Expr e) {
  switch (e) {
    case (Expr)`<Id x>`: 			    return ref("<x>", src=x@\loc); 
    case (Expr)`<Str s>`: 				return string(s, src=s@\loc);
    case (Expr)`<Int n>`: 				return integer(toInt("<n>"), src=n@\loc);
    case (Expr)`<Bool b>`: 				return boolean(fromString("<b>"), src=b@\loc);
    case (Expr)`(<Expr e>)`:		    return bracs(cst2ast(e), src=e@\loc);
    case (Expr)`!<Expr e>`: 			return not(cst2ast(e), src=e@\loc);
    case (Expr)`<Expr l> * <Expr r>`:   return mult(cst2ast(l), cst2ast(r), src=e@\loc);
    case (Expr)`<Expr l> / <Expr r>`:   return div(cst2ast(l), cst2ast(r), src=e@\loc);
    case (Expr)`<Expr l> + <Expr r>`:   return add(cst2ast(l), cst2ast(r), src=e@\loc);
    case (Expr)`<Expr l> - <Expr r>`:   return sub(cst2ast(l), cst2ast(r), src=e@\loc);
    case (Expr)`<Expr l> && <Expr r>`:  return and(cst2ast(l), cst2ast(r), src=e@\loc);
    case (Expr)`<Expr l> || <Expr r>`:  return or(cst2ast(l), cst2ast(r), src=e@\loc);
    case (Expr)`<Expr l> \> <Expr r>`:  return gt(cst2ast(l), cst2ast(r), src=e@\loc);
    case (Expr)`<Expr l> \< <Expr r>`:  return lt(cst2ast(l), cst2ast(r), src=e@\loc);
    case (Expr)`<Expr l> \<= <Expr r>`: return leq(cst2ast(l), cst2ast(r), src=e@\loc);
    case (Expr)`<Expr l> \>= <Expr r>`: return geq(cst2ast(l), cst2ast(r), src=e@\loc);
    case (Expr)`<Expr l> == <Expr r>`:  return eq(cst2ast(l), cst2ast(r), src=e@\loc);
    case (Expr)`<Expr l> != <Expr r>`:  return neq(cst2ast(l), cst2ast(r), src=e@\loc);
    default: throw "Unhandled expression: <e>";
  }
}

// Mapping of type concrete syntax to abstract syntax
AType cst2ast(Type t) {
  switch(t) {
  	case (Type) `string`:  return string(src=t@\loc);
  	case (Type) `integer`: return integer(src=t@\loc);
  	case (Type) `boolean`: return boolean(src=t@\loc);
    default: throw "Unhandled type: <t>";
  }
}
