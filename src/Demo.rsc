module Demo

import IO;
import Message;
import ParseTree;
import String;

import Syntax;
import AST;
import CST2AST;
import Resolve;
import Check;
import Eval;
import Compile;
import Transform;

// SYNTAX
start[Form] getCST(str file) = parse(#start[Form], toLocation("project://QL/examples/" + file + ".myql"));

// CST2AST	
AForm ASTfromCST(str file) = cst2ast(getCST(file));

// RESOLVE
UseDef resolveUseDef(str file) = resolve(ASTfromCST(file)).useDef;
	
// CHECK	
set[Message] checkErrors(str file) {
	AForm ast = ASTfromCST(file);
	TEnv tenv = collect(ast);
	UseDef useDef = resolve(ast).useDef;
	
	return check(ast, tenv, useDef);
}

// EVAL (for tax)
VEnv interpreterRun(str file) {
	// hardcoded input for "tax.myql" file
  list[Input] inp = [
	 input("hasBoughtHouse", vbool(true)),
	 input("hasMaintLoan", vbool(false)),
	 input("hasSoldHouse", vbool(true)),
	 input("sellingPrice", vint(250000)),
	 input("privateDebt", vint(10000))
  ];
  AForm f = ASTfromCST(file);
  VEnv venv = initialEnv(f);
 
  for(Input i <- inp) {
    venv += eval(f, i, venv);
  }
  return venv;
}

// COMPILE
void compileFile(str file) {
	compile(ASTfromCST(file));
}

// TRANSFORM - flatten
void flattenForm(str file) {

}

// TRANSFORM - rename
void renameForm(str file) {
	
}