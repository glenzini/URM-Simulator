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

open Parsing;;
let _ = parse_error;;
# 2 "URMParser.mly"
  open URM_types
  exception Parse_error
# 44 "URMParser.ml"
let yytransl_const = [|
  260 (* EVAL *);
  261 (* EXIT *);
  262 (* LOAD *);
  263 (* MU *);
  264 (* EQUALZERO *);
  265 (* PRINT *);
  266 (* PRINTALL *);
  267 (* PROG *);
  268 (* HELP *);
  269 (* ENCODE *);
  270 (* DECODE *);
  271 (* REC *);
  272 (* RUN *);
  273 (* RUNBOUND *);
  274 (* SAVE *);
  275 (* SUCC *);
  276 (* TRAN *);
  277 (* ZERO *);
  278 (* JUMP *);
  279 (* COLON *);
  280 (* SIMULATE *);
  281 (* SEMI *);
  282 (* DSEMI *);
  283 (* COMMA *);
  284 (* LPAREN *);
  285 (* RPAREN *);
  286 (* LBRACKET *);
  287 (* RBRACKET *);
  288 (* ARROW *);
  289 (* DOT *);
    0 (* EOF *);
  290 (* EOL *);
    0|]

let yytransl_block = [|
  257 (* NUMBER *);
  258 (* NAME *);
  259 (* INDEX *);
    0|]

let yylhs = "\255\255\
\001\000\002\000\002\000\003\000\003\000\004\000\006\000\006\000\
\006\000\006\000\006\000\006\000\007\000\007\000\007\000\011\000\
\011\000\011\000\011\000\011\000\011\000\011\000\011\000\009\000\
\009\000\009\000\010\000\010\000\010\000\008\000\008\000\008\000\
\005\000\005\000\005\000\005\000\005\000\005\000\005\000\005\000\
\005\000\005\000\005\000\005\000\000\000"

let yylen = "\002\000\
\002\000\000\000\003\000\001\000\001\000\004\000\001\000\006\000\
\003\000\006\000\008\000\007\000\001\000\002\000\003\000\006\000\
\004\000\006\000\004\000\008\000\006\000\010\000\008\000\003\000\
\001\000\000\000\003\000\001\000\000\000\003\000\001\000\000\000\
\005\000\006\000\005\000\002\000\001\000\002\000\002\000\001\000\
\003\000\005\000\002\000\001\000\002\000"

let yydefred = "\000\000\
\000\000\000\000\000\000\044\000\000\000\000\000\037\000\000\000\
\040\000\000\000\000\000\000\000\000\000\000\000\000\000\045\000\
\000\000\000\000\004\000\005\000\000\000\043\000\036\000\000\000\
\038\000\039\000\000\000\000\000\000\000\000\000\001\000\000\000\
\000\000\000\000\000\000\000\000\041\000\000\000\003\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\006\000\007\000\000\000\000\000\000\000\000\000\000\000\
\035\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\014\000\033\000\000\000\042\000\
\030\000\000\000\000\000\000\000\000\000\000\000\009\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\015\000\034\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\017\000\000\000\019\000\000\000\
\000\000\000\000\000\000\000\000\024\000\027\000\000\000\000\000\
\000\000\000\000\000\000\000\000\016\000\000\000\018\000\000\000\
\010\000\008\000\000\000\000\000\021\000\000\000\000\000\000\000\
\012\000\000\000\000\000\020\000\000\000\011\000\023\000\000\000\
\022\000"

let yydgoto = "\002\000\
\016\000\017\000\018\000\019\000\020\000\050\000\051\000\041\000\
\079\000\081\000\052\000"

let yysindex = "\004\000\
\035\255\000\000\007\255\000\000\023\255\024\255\000\000\030\255\
\000\000\032\255\039\255\041\255\048\255\054\255\057\255\000\000\
\061\000\036\255\000\000\000\000\037\255\000\000\000\000\040\255\
\000\000\000\000\038\255\042\255\062\255\043\255\000\000\035\255\
\066\255\009\255\066\255\066\255\000\000\066\255\000\000\045\255\
\044\255\046\255\234\254\047\255\049\255\050\255\051\255\052\255\
\053\255\000\000\000\000\255\254\055\255\056\255\058\255\066\255\
\000\000\249\254\072\255\074\255\066\255\080\255\081\255\067\255\
\085\255\087\255\088\255\016\255\000\000\000\000\089\255\000\000\
\000\000\063\255\064\255\065\255\068\255\069\255\000\000\070\255\
\071\255\073\255\090\255\075\255\077\255\076\255\078\255\082\255\
\000\000\000\000\094\255\098\255\100\255\103\255\072\255\074\255\
\091\255\107\255\083\255\108\255\000\000\110\255\000\000\112\255\
\086\255\092\255\093\255\096\255\000\000\000\000\115\255\095\255\
\097\255\099\255\101\255\102\255\000\000\116\255\000\000\117\255\
\000\000\000\000\120\255\104\255\000\000\123\255\105\255\106\255\
\000\000\124\255\109\255\000\000\130\255\000\000\000\000\111\255\
\000\000"

let yyrindex = "\000\000\
\132\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\132\000\
\113\255\000\000\113\255\113\255\000\000\113\255\000\000\025\255\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\118\255\000\000\000\000\000\000\026\255\
\000\000\000\000\119\255\114\255\121\255\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\122\255\000\000\125\255\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\119\255\114\255\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000"

let yygindex = "\000\000\
\000\000\103\000\000\000\000\000\000\000\000\000\211\255\222\255\
\041\000\043\000\000\000"

let yytablesize = 154
let yytable = "\042\000\
\053\000\054\000\059\000\055\000\001\000\060\000\069\000\061\000\
\021\000\042\000\043\000\074\000\075\000\076\000\077\000\044\000\
\042\000\046\000\047\000\048\000\049\000\073\000\089\000\045\000\
\022\000\023\000\082\000\046\000\047\000\048\000\049\000\024\000\
\068\000\025\000\046\000\047\000\048\000\049\000\003\000\004\000\
\005\000\026\000\027\000\006\000\007\000\008\000\009\000\010\000\
\011\000\028\000\012\000\013\000\014\000\031\000\032\000\029\000\
\031\000\032\000\015\000\030\000\031\000\032\000\034\000\037\000\
\033\000\035\000\040\000\085\000\058\000\036\000\038\000\056\000\
\057\000\078\000\062\000\080\000\063\000\064\000\065\000\066\000\
\067\000\083\000\084\000\070\000\071\000\086\000\072\000\087\000\
\088\000\090\000\091\000\092\000\093\000\095\000\105\000\094\000\
\096\000\099\000\106\000\097\000\107\000\100\000\102\000\108\000\
\098\000\101\000\103\000\112\000\104\000\114\000\115\000\113\000\
\116\000\111\000\117\000\121\000\127\000\128\000\118\000\123\000\
\129\000\119\000\120\000\131\000\134\000\122\000\130\000\124\000\
\126\000\125\000\136\000\002\000\133\000\132\000\039\000\109\000\
\000\000\135\000\110\000\137\000\000\000\032\000\029\000\013\000\
\026\000\000\000\000\000\025\000\000\000\000\000\000\000\000\000\
\032\000\028\000"

let yycheck = "\001\001\
\035\000\036\000\025\001\038\000\001\000\028\001\052\000\030\001\
\002\001\001\001\002\001\019\001\020\001\021\001\022\001\007\001\
\001\001\019\001\020\001\021\001\022\001\056\000\068\000\015\001\
\002\001\002\001\061\000\019\001\020\001\021\001\022\001\002\001\
\034\001\002\001\019\001\020\001\021\001\022\001\004\001\005\001\
\006\001\003\001\002\001\009\001\010\001\011\001\012\001\013\001\
\014\001\002\001\016\001\017\001\018\001\029\001\029\001\002\001\
\032\001\032\001\024\001\003\001\000\000\026\001\023\001\002\001\
\028\001\028\001\001\001\001\001\023\001\028\001\028\001\027\001\
\029\001\002\001\028\001\002\001\028\001\028\001\028\001\028\001\
\028\001\002\001\002\001\029\001\029\001\001\001\029\001\001\001\
\001\001\001\001\028\001\028\001\028\001\025\001\001\001\028\001\
\027\001\008\001\001\001\029\001\001\001\027\001\027\001\001\001\
\032\001\029\001\029\001\001\001\027\001\002\001\001\001\029\001\
\001\001\023\001\029\001\001\001\001\001\001\001\027\001\023\001\
\001\001\029\001\027\001\001\001\001\001\031\001\023\001\029\001\
\027\001\029\001\001\001\000\000\027\001\029\001\032\000\095\000\
\255\255\029\001\096\000\029\001\255\255\029\001\029\001\026\001\
\026\001\255\255\255\255\026\001\255\255\255\255\255\255\255\255\
\032\001\029\001"

let yynames_const = "\
  EVAL\000\
  EXIT\000\
  LOAD\000\
  MU\000\
  EQUALZERO\000\
  PRINT\000\
  PRINTALL\000\
  PROG\000\
  HELP\000\
  ENCODE\000\
  DECODE\000\
  REC\000\
  RUN\000\
  RUNBOUND\000\
  SAVE\000\
  SUCC\000\
  TRAN\000\
  ZERO\000\
  JUMP\000\
  COLON\000\
  SIMULATE\000\
  SEMI\000\
  DSEMI\000\
  COMMA\000\
  LPAREN\000\
  RPAREN\000\
  LBRACKET\000\
  RBRACKET\000\
  ARROW\000\
  DOT\000\
  EOF\000\
  EOL\000\
  "

let yynames_block = "\
  NUMBER\000\
  NAME\000\
  INDEX\000\
  "

let yyact = [|
  (fun _ -> failwith "parser")
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 1 : 'items) in
    Obj.repr(
# 23 "URMParser.mly"
              ( _1 )
# 263 "URMParser.ml"
               : URM_types.top list))
; (fun __caml_parser_env ->
    Obj.repr(
# 26 "URMParser.mly"
                ( [] )
# 269 "URMParser.ml"
               : 'items))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 2 : 'item) in
    let _3 = (Parsing.peek_val __caml_parser_env 0 : 'items) in
    Obj.repr(
# 27 "URMParser.mly"
                     ( _1 :: _3 )
# 277 "URMParser.ml"
               : 'items))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : 'program) in
    Obj.repr(
# 30 "URMParser.mly"
            ( ProgramDef (fst _1, snd _1) )
# 284 "URMParser.ml"
               : 'item))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : 'exec) in
    Obj.repr(
# 31 "URMParser.mly"
            ( _1 )
# 291 "URMParser.ml"
               : 'item))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 2 : string) in
    let _4 = (Parsing.peek_val __caml_parser_env 0 : 'body) in
    Obj.repr(
# 34 "URMParser.mly"
                         ( (_2, _4) )
# 299 "URMParser.ml"
               : 'program))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : 'instrs) in
    Obj.repr(
# 37 "URMParser.mly"
           ( BodyInstrs _1 )
# 306 "URMParser.ml"
               : 'body))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 5 : string) in
    let _3 = (Parsing.peek_val __caml_parser_env 3 : 'numbers) in
    let _5 = (Parsing.peek_val __caml_parser_env 1 : int) in
    Obj.repr(
# 38 "URMParser.mly"
                                                ( BodyRelocate (_1, _3, _5) )
# 315 "URMParser.ml"
               : 'body))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 2 : string) in
    let _3 = (Parsing.peek_val __caml_parser_env 0 : 'concatlist) in
    Obj.repr(
# 39 "URMParser.mly"
                         ( BodyConcatenate (_1, _3) )
# 323 "URMParser.ml"
               : 'body))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 5 : string) in
    let _3 = (Parsing.peek_val __caml_parser_env 3 : 'namelist) in
    let _6 = (Parsing.peek_val __caml_parser_env 0 : int) in
    Obj.repr(
# 40 "URMParser.mly"
                                             ( BodySubstitute (_1, _3, _6) )
# 332 "URMParser.ml"
               : 'body))
; (fun __caml_parser_env ->
    let _3 = (Parsing.peek_val __caml_parser_env 5 : string) in
    let _5 = (Parsing.peek_val __caml_parser_env 3 : string) in
    let _8 = (Parsing.peek_val __caml_parser_env 0 : int) in
    Obj.repr(
# 41 "URMParser.mly"
                                                   ( BodyRec (_3, _5, _8) )
# 341 "URMParser.ml"
               : 'body))
; (fun __caml_parser_env ->
    let _3 = (Parsing.peek_val __caml_parser_env 4 : string) in
    let _7 = (Parsing.peek_val __caml_parser_env 0 : int) in
    Obj.repr(
# 42 "URMParser.mly"
                                                 ( BodyMin (_3, _7) )
# 349 "URMParser.ml"
               : 'body))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : 'instr) in
    Obj.repr(
# 45 "URMParser.mly"
          ( [| _1 |] )
# 356 "URMParser.ml"
               : 'instrs))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 1 : 'instr) in
    let _2 = (Parsing.peek_val __caml_parser_env 0 : 'instrs) in
    Obj.repr(
# 46 "URMParser.mly"
                 ( Array.append [| _1 |] _2 )
# 364 "URMParser.ml"
               : 'instrs))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 2 : 'instr) in
    let _3 = (Parsing.peek_val __caml_parser_env 0 : 'instrs) in
    Obj.repr(
# 47 "URMParser.mly"
                     ( Array.append [| _1 |] _3 )
# 372 "URMParser.ml"
               : 'instrs))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 5 : int) in
    let _5 = (Parsing.peek_val __caml_parser_env 1 : int) in
    Obj.repr(
# 50 "URMParser.mly"
                                           ( Succ(_5) )
# 380 "URMParser.ml"
               : 'instr))
; (fun __caml_parser_env ->
    let _3 = (Parsing.peek_val __caml_parser_env 1 : int) in
    Obj.repr(
# 51 "URMParser.mly"
                              ( Succ(_3) )
# 387 "URMParser.ml"
               : 'instr))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 5 : int) in
    let _5 = (Parsing.peek_val __caml_parser_env 1 : int) in
    Obj.repr(
# 52 "URMParser.mly"
                                           ( Zero(_5) )
# 395 "URMParser.ml"
               : 'instr))
; (fun __caml_parser_env ->
    let _3 = (Parsing.peek_val __caml_parser_env 1 : int) in
    Obj.repr(
# 53 "URMParser.mly"
                              ( Zero(_3) )
# 402 "URMParser.ml"
               : 'instr))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 7 : int) in
    let _5 = (Parsing.peek_val __caml_parser_env 3 : int) in
    let _7 = (Parsing.peek_val __caml_parser_env 1 : int) in
    Obj.repr(
# 54 "URMParser.mly"
                                                        ( Tran(_5, _7) )
# 411 "URMParser.ml"
               : 'instr))
; (fun __caml_parser_env ->
    let _3 = (Parsing.peek_val __caml_parser_env 3 : int) in
    let _5 = (Parsing.peek_val __caml_parser_env 1 : int) in
    Obj.repr(
# 55 "URMParser.mly"
                                           ( Tran(_3, _5) )
# 419 "URMParser.ml"
               : 'instr))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 9 : int) in
    let _5 = (Parsing.peek_val __caml_parser_env 5 : int) in
    let _7 = (Parsing.peek_val __caml_parser_env 3 : int) in
    let _9 = (Parsing.peek_val __caml_parser_env 1 : int) in
    Obj.repr(
# 56 "URMParser.mly"
                                                                     ( Jump(_5, _7, _9) )
# 429 "URMParser.ml"
               : 'instr))
; (fun __caml_parser_env ->
    let _3 = (Parsing.peek_val __caml_parser_env 5 : int) in
    let _5 = (Parsing.peek_val __caml_parser_env 3 : int) in
    let _7 = (Parsing.peek_val __caml_parser_env 1 : int) in
    Obj.repr(
# 57 "URMParser.mly"
                                                        ( Jump(_3, _5, _7) )
# 438 "URMParser.ml"
               : 'instr))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 2 : string) in
    let _3 = (Parsing.peek_val __caml_parser_env 0 : 'concatlist) in
    Obj.repr(
# 60 "URMParser.mly"
                         ( _1 :: _3 )
# 446 "URMParser.ml"
               : 'concatlist))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : string) in
    Obj.repr(
# 61 "URMParser.mly"
         ( [_1] )
# 453 "URMParser.ml"
               : 'concatlist))
; (fun __caml_parser_env ->
    Obj.repr(
# 62 "URMParser.mly"
                ( [] )
# 459 "URMParser.ml"
               : 'concatlist))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 2 : string) in
    let _3 = (Parsing.peek_val __caml_parser_env 0 : 'namelist) in
    Obj.repr(
# 65 "URMParser.mly"
                        ( _1 :: _3 )
# 467 "URMParser.ml"
               : 'namelist))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : string) in
    Obj.repr(
# 66 "URMParser.mly"
         ( [_1] )
# 474 "URMParser.ml"
               : 'namelist))
; (fun __caml_parser_env ->
    Obj.repr(
# 67 "URMParser.mly"
                ( [] )
# 480 "URMParser.ml"
               : 'namelist))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 2 : int) in
    let _3 = (Parsing.peek_val __caml_parser_env 0 : 'numbers) in
    Obj.repr(
# 70 "URMParser.mly"
                         ( _1 :: _3 )
# 488 "URMParser.ml"
               : 'numbers))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : int) in
    Obj.repr(
# 71 "URMParser.mly"
           ( [_1] )
# 495 "URMParser.ml"
               : 'numbers))
; (fun __caml_parser_env ->
    Obj.repr(
# 72 "URMParser.mly"
                ( [] )
# 501 "URMParser.ml"
               : 'numbers))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 3 : string) in
    let _4 = (Parsing.peek_val __caml_parser_env 1 : 'numbers) in
    Obj.repr(
# 75 "URMParser.mly"
                                    ( Run(_2, _4) )
# 509 "URMParser.ml"
               : 'exec))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 4 : string) in
    let _4 = (Parsing.peek_val __caml_parser_env 2 : 'numbers) in
    let _6 = (Parsing.peek_val __caml_parser_env 0 : int) in
    Obj.repr(
# 76 "URMParser.mly"
                                               ( RunBound(_2, _4, _6) )
# 518 "URMParser.ml"
               : 'exec))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 3 : string) in
    let _4 = (Parsing.peek_val __caml_parser_env 1 : 'numbers) in
    Obj.repr(
# 77 "URMParser.mly"
                                    ( Eval(_2, _4) )
# 526 "URMParser.ml"
               : 'exec))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 0 : string) in
    Obj.repr(
# 78 "URMParser.mly"
                                    ( Print(_2) )
# 533 "URMParser.ml"
               : 'exec))
; (fun __caml_parser_env ->
    Obj.repr(
# 79 "URMParser.mly"
                                    ( PrintAll )
# 539 "URMParser.ml"
               : 'exec))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 0 : string) in
    Obj.repr(
# 80 "URMParser.mly"
                                    ( Encode(_2) )
# 546 "URMParser.ml"
               : 'exec))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 0 : string) in
    Obj.repr(
# 81 "URMParser.mly"
                                    ( Decode(_2) )
# 553 "URMParser.ml"
               : 'exec))
; (fun __caml_parser_env ->
    Obj.repr(
# 82 "URMParser.mly"
                                    ( PrintHelp )
# 559 "URMParser.ml"
               : 'exec))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 1 : string) in
    let _3 = (Parsing.peek_val __caml_parser_env 0 : string) in
    Obj.repr(
# 83 "URMParser.mly"
                                    ( Save(_2, _3) )
# 567 "URMParser.ml"
               : 'exec))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 3 : string) in
    let _4 = (Parsing.peek_val __caml_parser_env 1 : 'numbers) in
    Obj.repr(
# 84 "URMParser.mly"
                                         ( Simulate(_2, _4) )
# 575 "URMParser.ml"
               : 'exec))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 0 : string) in
    Obj.repr(
# 85 "URMParser.mly"
                                    ( Load(_2) )
# 582 "URMParser.ml"
               : 'exec))
; (fun __caml_parser_env ->
    Obj.repr(
# 86 "URMParser.mly"
                                    ( Exit )
# 588 "URMParser.ml"
               : 'exec))
(* Entry mainParser *)
; (fun __caml_parser_env -> raise (Parsing.YYexit (Parsing.peek_val __caml_parser_env 0)))
|]
let yytables =
  { Parsing.actions=yyact;
    Parsing.transl_const=yytransl_const;
    Parsing.transl_block=yytransl_block;
    Parsing.lhs=yylhs;
    Parsing.len=yylen;
    Parsing.defred=yydefred;
    Parsing.dgoto=yydgoto;
    Parsing.sindex=yysindex;
    Parsing.rindex=yyrindex;
    Parsing.gindex=yygindex;
    Parsing.tablesize=yytablesize;
    Parsing.table=yytable;
    Parsing.check=yycheck;
    Parsing.error_function=parse_error;
    Parsing.names_const=yynames_const;
    Parsing.names_block=yynames_block }
let mainParser (lexfun : Lexing.lexbuf -> token) (lexbuf : Lexing.lexbuf) =
   (Parsing.yyparse yytables 1 lexfun lexbuf : URM_types.top list)
