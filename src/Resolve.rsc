module Resolve

import AST;

/*
 * Name resolution for QL
 */ 


// modeling declaring occurrences of names
alias Def = rel[str name, loc def];

// modeling use occurrences of names
alias Use = rel[loc use, str name];

alias UseDef = rel[loc use, loc def];

// the reference graph
alias RefGraph = tuple[
  Use uses, // uses of the program
  Def defs, // definitions of the program
  UseDef useDef // relation to link use location and def location
]; 

RefGraph resolve(AForm f) = <us, ds, us o ds> // relational composition connects targets of uses with sources of definitions 
  when Use us := uses(f), Def ds := defs(f);

// Uses of the expression for obtaining expressions source and name in a tuple
Use uses(AForm f) { 
  return { <e.src, e.name> | /AExpr e := f.questions, e has name }; 
}

// Definitions of questions name and source in a tuple
Def defs(AForm f) {
  return { <q.name, q.src> | /AQuestion q := f.questions, q has name }; 
}