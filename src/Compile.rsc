module Compile

import AST;
import Resolve;
import IO;
import lang::html5::DOM;


void compile(AForm f) {
  writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, toString(form2html(f)));
}

// Translates initial form of AST into html readable code 
HTML5Node form2html(AForm f) {
  return html(
  	lang("en"),
    head(
      meta(charset("utf-8")),
      title(f.name)
	),
    body(
      h1("Query Language for: " + f.name, align("center")),
      div(
      	id("app"),
        div([question2html(q) | /AQuestion q <- f.questions])
      ),        
      script(src("https://cdn.jsdelivr.net/npm/vue/dist/vue.js")),
      script(src(f.src[extension="js"].file))
    )
  );
}

// Translates questions from the AST form into html
HTML5Node question2html(AQuestion q) {
  switch(q) {
  
    case question(str qlabel, str qname, AType qtype):
      return div(
        label(\for("<qname>"), qlabel),
        input(name(qname), html5attr("v-model", qname), type2html(qtype)),
        align("center")
      );
      
    case computedquestion(str qlabel, str qname, AType qtype, AExpr e):
      return div(
        label(\for("<qname>"), qlabel),
        input(name(qname), html5attr("v-model", qname), type2html(qtype), mapLoc2string(e.src)),
        align("center")
      );
      
    case blockquestion(list[AQuestion] questions):
      return div([question2html(q) | q <- questions]);
      
    case ifelsequestion(AExpr e, list[AQuestion] ifquestions, list[AQuestion] elsequestions):
      return div([html5attr("v-if", mapLoc2string(e.src)), 
      			question2html(ifq), question2html(elseq) | ifq <- ifquestions, elseq <- elsequestions]);
        
    case ifquestion(AExpr e, list[AQuestion] ifquestions):
      return div([html5attr("v-if", mapLoc2string(e.src)),
      		    question2html(ifq) | ifq <- ifquestions]);
      
    default: throw "Question: <q> is not supported";
  }
}

// Translates query language into JavaScript, in this case "VueJs" was used  
str form2js(AForm f) {
  return "var app = new Vue({
         '  el: \'#app\',
         '  data: {
         '    <for (/AQuestion q <- f.questions) {>
         '    <if (!(q has e) && q has name) {>
         '    <q.name>: <type2js(q.t)>,
         '    <}>
         '    <}>
         '  },
         '  computed: {
         '    <for (/AQuestion q <- f.questions) {>
         '    <if (q has e && q has name) {>
         '    <q.name>: function() {
         '      return <expr2js(q.e)>;
         '    },
         '    <}>
         '    <}>
         '    <for (/AQuestion q <- f.questions) {>
         '    <if (q has e && q has ifq) {>
         '    <mapLoc2string(q.ifq.src)>: function() {
         '      return <expr2js(q.e)>;
         '    },
         '    <}>
         '    <}>
         '  }
         '});
         ";
}

// Translates AST expressions into JavaScript
str expr2js(AExpr e) {
  switch(e) {
    case ref(str name): 		 return "this.<name>";
   	case string(str s): 	     return "<s>";
	case integer(int n):  		 return "<n>";
   	case boolean(true): 		 return "true";
   	case boolean(false): 		 return "false";
   	case bracs(AExpr e): 		 return "(" + expr2js(e) + ")";
   	case not(AExpr e):   		 return "!" + expr2js(e);
    case mult(AExpr l, AExpr r): return expr2js(l) + "*" + expr2js(r);
    case div(AExpr l, AExpr r):  return expr2js(l) + "/" + expr2js(r);
    case add(AExpr l, AExpr r):  return expr2js(l) + "+" + expr2js(r);
    case sub(AExpr l, AExpr r):  return expr2js(l) + "-" + expr2js(r);
    case and(AExpr l, AExpr r):  return expr2js(l) + "&&" + expr2js(r);
    case or(AExpr l, AExpr r):   return expr2js(l) + "||" + expr2js(r);
    case gt(AExpr l, AExpr r):   return expr2js(l) + "\>" + expr2js(r);
    case lt(AExpr l, AExpr r):   return expr2js(l) + "\<" + expr2js(r);
    case leq(AExpr l, AExpr r):  return expr2js(l) + "\<=" + expr2js(r);
    case geq(AExpr l, AExpr r):  return expr2js(l) + "\>=" + expr2js(r);
    case eq(AExpr l, AExpr r):   return expr2js(l) + "==" + expr2js(r);
    case neq(AExpr l, AExpr r):  return expr2js(l) + "!=" + expr2js(r);
    default: throw "Expression: <e> is not supported";
  }
}

// converts AST type to html type: string = "text", integer = "number", boolean = "checkbox"
HTML5Attr type2html(string())  = \type("text");
HTML5Attr type2html(integer()) = \type("number");
HTML5Attr type2html(boolean()) = \type("checkbox");

// Translates initial AST types from AST to corresponding strings for JavaScript
str type2js(integer()) = "0";
str type2js(boolean()) = "false";
str type2js(string()) = "\'\'";

// Since we get an Abstract Expr we have to map the location to a readable string so that it can be used in html and js
str mapLoc2string(loc src){
	return "expression_<src.offset>_<src.length>_<src.begin.line>_<src.begin.column>_<src.end.line>_<src.end.column>";
}
