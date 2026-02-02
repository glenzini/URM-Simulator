%{
  open URM_types
  exception Parse_error
%}

%token <int> NUMBER
%token <string> NAME
%token <string> INDEX

%token EVAL EXIT LOAD MU EQUALZERO PRINT PRINTALL PROG HELP ENCODE DECODE
%token REC RUN RUNBOUND SAVE SUCC TRAN ZERO JUMP COLON SIMULATE 
%token SEMI DSEMI COMMA LPAREN RPAREN LBRACKET RBRACKET ARROW DOT 

%token EOF
%token EOL

%start mainParser
%type <URM_types.top list> mainParser

%%

mainParser:
  | items EOF { $1 }

items:
  | /* empty */ { [] }
  | item DSEMI items { $1 :: $3 }

item:
  | program { ProgramDef (fst $1, snd $1) } 
  | exec    { $1 }

program:
  | PROG NAME COLON body { ($2, $4) }

body:
  | instrs { BodyInstrs $1 }
  | NAME LBRACKET numbers ARROW NUMBER RBRACKET { BodyRelocate ($1, $3, $5) }
  | NAME SEMI concatlist { BodyConcatenate ($1, $3) }
  | NAME LPAREN namelist RPAREN COLON NUMBER { BodySubstitute ($1, $3, $6) }
  | REC LPAREN NAME COMMA NAME RPAREN COLON NUMBER { BodyRec ($3, $5, $8) }
  | MU LPAREN NAME EQUALZERO RPAREN COLON NUMBER { BodyMin ($3, $7) }

instrs:
  | instr { [| $1 |] }
  | instr instrs { Array.append [| $1 |] $2 }
  | instr EOL instrs { Array.append [| $1 |] $3 }

instr:
  | NUMBER COLON SUCC LPAREN NUMBER RPAREN { Succ($5) }
  | SUCC LPAREN NUMBER RPAREN { Succ($3) }
  | NUMBER COLON ZERO LPAREN NUMBER RPAREN { Zero($5) }
  | ZERO LPAREN NUMBER RPAREN { Zero($3) }
  | NUMBER COLON TRAN LPAREN NUMBER COMMA NUMBER RPAREN { Tran($5, $7) }
  | TRAN LPAREN NUMBER COMMA NUMBER RPAREN { Tran($3, $5) }
  | NUMBER COLON JUMP LPAREN NUMBER COMMA NUMBER COMMA NUMBER RPAREN { Jump($5, $7, $9) }
  | JUMP LPAREN NUMBER COMMA NUMBER COMMA NUMBER RPAREN { Jump($3, $5, $7) }

concatlist:
  | NAME SEMI concatlist { $1 :: $3 }
  | NAME { [$1] }
  | /* empty */ { [] }

namelist:
  | NAME COMMA namelist { $1 :: $3 }
  | NAME { [$1] }
  | /* empty */ { [] }

numbers:
  | NUMBER COMMA numbers { $1 :: $3 }
  | NUMBER { [$1] }
  | /* empty */ { [] }

exec:
  | RUN NAME LPAREN numbers RPAREN  { Run($2, $4) }
  | RUNBOUND NAME LPAREN numbers RPAREN NUMBER { RunBound($2, $4, $6) }
  | EVAL NAME LPAREN numbers RPAREN { Eval($2, $4) }
  | PRINT NAME                      { Print($2) }
  | PRINTALL                        { PrintAll }
  | ENCODE NAME                     { Encode($2) }
  | DECODE INDEX                    { Decode($2) }
  | HELP                            { PrintHelp }
  | SAVE NAME NAME                  { Save($2, $3) }
  | SIMULATE INDEX LPAREN numbers RPAREN { Simulate($2, $4) }
  | LOAD NAME                       { Load($2) }
  | EXIT                            { Exit }
