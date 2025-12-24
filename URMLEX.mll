 (* LEXER mll *) 

{
  open URM_types
  open URMParser
}

let digit = ['0'-'9']
let letter = ['a'-'z' 'A'-'Z']
let index = '#' digit+
let name = letter (letter | digit | '\'' | '_')*

rule readtoken = parse 
  | [' ' '\t' '\r' '\n'] { readtoken lexbuf }  (* skip whitespace and newlines *)

  (* Comments *)
  | "//" [^'\n']* { readtoken lexbuf }
  | '%'  [^'\n']* { readtoken lexbuf }

  (* Keywords *)
  | "ENCODE"   { ENCODE }
  | "Encode"   { ENCODE }
  | "EVAL"     { EVAL }
  | "Eval"     { EVAL }
  | "DECODE"   { DECODE }
  | "Decode"   { DECODE }
  | "EXIT"     { EXIT }
  | "Exit"     { EXIT }
  | "Help"     { HELP }
  | "HELP"     { HELP }
  | "LOAD"     { LOAD }
  | "Load"     { LOAD }
  | "MIN"      { MU }
  | "Min"      { MU }
  | "PRINT"    { PRINT }
  | "Print"    { PRINT }
  | "PRINTALL" { PRINTALL }
  | "Printall" { PRINTALL }
  | "PROG"     { PROG }
  | "Prog"     { PROG }
  | "REC"      { REC }
  | "Rec"      { REC }
  | "RUN"      { RUN }
  | "Run"      { RUN }
  | "RUNBOUND" { RUNBOUND }
  | "Runbound" { RUNBOUND }
  | "SAVE"     { SAVE }
  | "Save"     { SAVE }
  | "SIMULATE" { SIMULATE }
  | "Simulate" { SIMULATE } 
  | "S"        { SUCC }
  | "T"        { TRAN }
  | "Z"        { ZERO }
  | "J"        { JUMP }

  (* Symbols *)
  | ":"        { COLON }
  | ";"        { SEMI }
  | ";;"       { DSEMI }
  | ","        { COMMA }
  | "("        { LPAREN }
  | ")"        { RPAREN }
  | "["        { LBRACKET }
  | "]"        { RBRACKET }
  | "->"       { ARROW }
  | "==0"      { EQUALZERO}
  | "."        { DOT }

  (* Tokens *)
  | digit+ as num  { NUMBER (int_of_string num) }
  | name as id     { NAME id }
  | index as ix    { INDEX (String.sub ix 1 (String.length ix -1)) }

  | eof { EOF }
  | _ as c  { failwith (Printf.sprintf "Unexpected character: %c" c) }
