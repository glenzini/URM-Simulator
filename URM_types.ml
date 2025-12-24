type instr = 
  Zero of int
| Succ of int
| Tran of int * int
| Jump of int * int * int ;;


(* type program *)
type program = 
instr array
;;

type name = string
;;

type index = string
;;

type number = int
;;

type body =
  | BodyInstrs of program 
  | BodyRelocate of name * int list * int
  | BodySubstitute of name * name list * int
  | BodyConcatenate of name * name list
  | BodyRec of name * name * int
  | BodyMin of name * int
;; 

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
