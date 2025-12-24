open URM_types  ;;
open URM_machine  ;;
open URM_counting_programs ;; 
open URM_input_output  ;;
open URMLEX ;;
open URMParser ;;

exception ProgramNotFound of string
exception ExitREPL

module ProgramTable = Map.Make(String)

type env = {
  programs : program ProgramTable.t;
}
let empty_env = { programs = ProgramTable.empty }

(* ---------------- *)
(* load from a file *)
(* ---------------- *)

let read_from_file (filename : string) : top list =
  let ic = In_channel.open_text filename in
  let lexbuf = Lexing.from_channel ic in
  try
    let parsed = mainParser readtoken lexbuf in
    In_channel.close ic;
    parsed
  with
  | Failure msg ->
      In_channel.close ic;
      Printf.printf "Lexing error in file %s: %s\n" filename msg;
      raise (Failure msg) 
  | Parsing.Parse_error ->
      In_channel.close ic;
      Printf.printf "Syntax error in file %s\n" filename;
      raise (Parsing.Parse_error) 
  | e ->
      In_channel.close ic;
      Printf.printf "Unexpected error while reading %s: %s\n" filename (Printexc.to_string e);
      raise e
  ;; 

(* ----------------  *)
(* print a text file *)
(* ----------------  *)
 let print_file filename =
  let ic = In_channel.open_text filename in
  let content = In_channel.input_all ic in
  In_channel.close ic;
  print_string content
;;

(* let read_from_file (filename : string) : top list =
  let ic = In_channel.open_text filename in
  let lexbuf = Lexing.from_channel ic in
  let parsed = mainParser readtoken lexbuf in 
  In_channel.close ic;
  parsed  
;; *)

(* ------------- *)
(* find a program in the environment table *)
(* ------------- *)
let find_program name env =
  try ProgramTable.find name env.programs
with Not_found -> raise (ProgramNotFound name)  


let interpret_body (env : env) (body : body) : program =
  match body with
  | BodyInstrs code -> code

  | BodyRelocate (name, inputs, output) ->
      let p =
        try find_program name env
        with ProgramNotFound n -> raise (ProgramNotFound ("Relocate: " ^ n))
      in
      relocate p inputs output

  | BodySubstitute (fname, gnames, n) ->
      let f =
        try find_program fname env
        with ProgramNotFound n -> raise (ProgramNotFound ("Substitute (f): " ^ n))
      in
      let gs =
        try List.map (fun name -> find_program name env) gnames
        with ProgramNotFound n -> raise (ProgramNotFound ("Substitute (g): " ^ n))
      in
      compose f gs n

  | BodyConcatenate (fname, gnames) ->
      let f =
        try find_program fname env
        with ProgramNotFound n -> raise (ProgramNotFound ("Concatenate (f): " ^ n))
      in
      let gs =
        try List.map (fun name -> find_program name env) gnames
        with ProgramNotFound n -> raise (ProgramNotFound ("Concatenate (g): " ^ n))
      in
      concatenateList (f :: gs)

  | BodyRec (f, g, n) ->
      let pf =
        try find_program f env
        with ProgramNotFound n -> raise (ProgramNotFound ("Rec (f): " ^ n))
      in
      let pg =
        try find_program g env
        with ProgramNotFound n -> raise (ProgramNotFound ("Rec (g): " ^ n))
      in
      recursion pf pg n

  | BodyMin (f, n) ->
      let pf =
        try find_program f env
        with ProgramNotFound n -> raise (ProgramNotFound ("Min: " ^ n))
      in
      minimalization pf n
;;

let interpret_top (env : env) (t : top) : env =
  match t with
  | ProgramDef (name, body) ->
    (try
      let p = interpret_body env body in
      let p_std = standardize p in
      { programs = ProgramTable.add name p_std env.programs }
    with
       | ProgramNotFound msg ->
           Printf.printf "Error: program not found — %s\n" msg;
      env)

  | Run (name, args) ->
      (try
         let p = find_program name env in
         let result = run p args in
         Array.iteri (fun i v -> Printf.printf "R%d = %d\n" (i+1) v) result;
         env
       with
       | ProgramNotFound msg ->
           Printf.printf "Error: program not found — %s\n" msg;
           env)

  | RunBound (name, args, max) ->
      (try
         let p = find_program name env in
         let result = runbound p args max in
         Array.iteri (fun i v -> Printf.printf "R%d = %d\n" (i+1) v) result;
         env
       with
       | ProgramNotFound msg ->
           Printf.printf "Error: program not found — %s\n" msg;
           env)

  | Eval (name, args) ->
      (try
         let p = find_program name env in
         let result = eval p args in
         Printf.printf "Result (R1) = %d\n" result;
         env
       with
       | ProgramNotFound msg ->
           Printf.printf "Error: program not found — %s\n" msg;
           env)

  | Encode name ->
      (try
         let p = find_program name env in
           let index = yota p in
           Printf.printf "Index: %s\n" (show index);
         env
       with
       | ProgramNotFound msg ->
           Printf.printf "Error: program not found — %s\n" msg;
           env)
           
  | Decode index ->
      (try
        let program = uyota (bs index) in 
          Array.iteri (fun i instr ->
           Printf.printf "%d: %s\n" (i+1) (instruction_to_string instr)) program;
         env
       with
       | ProgramNotFound msg ->
           Printf.printf "Error: program not found — %s\n" msg;
           env)

  | Print name ->
      (try
         let p = find_program name env in
         Array.iteri (fun i instr ->
           Printf.printf "%d: %s\n" (i+1) (instruction_to_string instr)) p;
         env
       with
       | ProgramNotFound msg ->
           Printf.printf "Error: program not found — %s\n" msg;
           env)

  | PrintAll -> 
      Printf.printf "Here are all programs:\n" ;
      let printone name p =
        Printf.printf "PROG %s:\n" name;
        Array.iteri (fun i instr -> Printf.printf "%d: %s\n" (i+1) (instruction_to_string instr)) p 
      in
      ProgramTable.iter printone env.programs;
      env

  | PrintHelp -> 
      print_file "help.me";
      env

  | Save (name, filename) -> 
      (try
         let p = find_program name env in
         let head = "PROG " ^ name ^ ":\n" in
         write_to_file head p (filename ^ ".txt") ;
         Printf.printf "Program %s saved to %s.txt\n" name filename ;
         env
       with
       | ProgramNotFound msg ->
           Printf.printf "Error: program not found — %s\n" msg;
           env)

  | Simulate (index, args) -> 
         let program = uyota(bs index) in 
           let result = run program args in
              Array.iteri (fun i v -> Printf.printf "R%d = %d\n" (i+1) v) result;
           env

  | Load name ->
      let filename = name ^ ".txt" in
      if not (Sys.file_exists filename) then (
        Printf.printf "File does not exist\n";
        env
      ) else (
        try
          let tops = read_from_file filename in
          let env' = List.fold_left
            (fun e t ->
               match t with
               | ProgramDef (n, b) ->
                   let p = interpret_body e b in
                   let p_std = standardize p in
                   { programs = ProgramTable.add n p_std e.programs }
               | _ ->
                   Printf.printf "Ignored non-program in %s\n" filename;
                   e)
            env tops
          in
          Printf.printf "Loaded programs from %s\n" filename;
          env'
        with 
        | Failure msg ->
            Printf.printf "File %s not loaded (lexing error): %s\n" filename msg;
            env
        | Parsing.Parse_error ->
            Printf.printf "File %s not loaded (syntax error)\n" filename;
            env
        | ProgramNotFound msg -> 
            Printf.printf "Error: program not found — %s\n" msg;
            env 
        | _ ->
            Printf.printf "File %s not loaded (unexpected error)\n" filename;
            env
      )

  | Exit ->
      Printf.printf "Goodbye!\n";
      raise ExitREPL
  ;;
