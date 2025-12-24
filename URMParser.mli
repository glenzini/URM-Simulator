type token =
  | NUMBER of (int)
  | NAME of (string)
  | INDEX of (string)
  | EVAL
  | EXIT
  | LOAD
  | MU
  | EQUALZERO
  | PRINT
  | PRINTALL
  | PROG
  | HELP
  | ENCODE
  | DECODE
  | REC
  | RUN
  | RUNBOUND
  | SAVE
  | SUCC
  | TRAN
  | ZERO
  | JUMP
  | COLON
  | SIMULATE
  | SEMI
  | DSEMI
  | COMMA
  | LPAREN
  | RPAREN
  | LBRACKET
  | RBRACKET
  | ARROW
  | DOT
  | EOF
  | EOL

val mainParser :
  (Lexing.lexbuf  -> token) -> Lexing.lexbuf -> URM_types.top list
