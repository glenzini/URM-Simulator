type instr =
    Zero of int
  | Succ of int
  | Tran of int * int
  | Jump of int * int * int
type program = instr array
type name = string
type number = int
type index = string 
type body =
    BodyInstrs of program
  | BodyRelocate of name * number list * number
  | BodySubstitute of name * name list * number
  | BodyConcatenate of name * name list
  | BodyRec of name * name * number
  | BodyMin of name * number
type top =
  | ProgramDef of name * body
  | Run of name * number list
  | RunBound of name * number list * number
  | Eval of name * number list
  | Print of name 
  | Encode of name 
  | Decode of index 
  | PrintAll
  | PrintHelp
  | Save of name * name
  | Simulate of index * number list
  | Load of name
  | Exit
;;