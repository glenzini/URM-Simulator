(* URLREPL.ml *)

open URM_types 
open URMinterpret
open URMParser
open URMLEX

let prompt = "# "

(* History file location *)
let history_file = Filename.concat (Sys.getenv "HOME") ".urm_history"

let rec read_statement acc =
  flush stdout;
  try
    (* Display prompt and use Ocamline.read with file-based history support *)
    print_string prompt;
    flush stdout;
    let line = Ocamline.read ~history_loc:history_file () in
    let new_acc = acc ^ "\n" ^ line in
    if String.contains new_acc ';' 
       && String.trim new_acc |> String.ends_with ~suffix:";;"
    then
      new_acc
    else
      read_statement new_acc
  with End_of_file -> acc

let parse_input input =
  let lexbuf = Lexing.from_string input in
  try
    let tops = URMParser.mainParser URMLEX.readtoken lexbuf in
    Ok tops
  with
  | Failure msg -> Error ("Lexing error: " ^ msg)
  | Parsing.Parse_error -> Error "Syntax error"

let rec loop (env : URMinterpret.env) : unit =
  let input = read_statement "" in
  match parse_input input with
  | Ok tops ->
      (try
        let new_env = List.fold_left URMinterpret.interpret_top env tops in
        loop new_env
      with URMinterpret.ExitREPL -> ())
  | Error msg ->
      Printf.printf "Error: %s\n" msg;
      loop env

let () =
  print_file "help.me";
  loop URMinterpret.empty_env