(* URM_server.ml
   Dream-based HTTP server for the URM Simulator web UI.

   Architecture:
   - Every request that needs to run something sends the full editor source.
   - The server parses + builds the env fresh on each stateless request.
   - Step-by-step execution is the only stateful operation: a session table
     maps session_id -> (program * urmmachine) so the client can call
     /api/step/next repeatedly.

   Note: we avoid let%lwt (requires lwt_ppx) and use Lwt.bind / >>= instead.
*)

open URM_types
open URM_machine
open URM_counting_programs
open URM_input_output
open URMinterpret

let ( >>= ) = Lwt.bind

(* ------------------------------------------------------------------ *)
(* 1.  Parse source text into an env (all PROG definitions)           *)
(* ------------------------------------------------------------------ *)

let parse_source (source : string) : (env, string) result =
  let lexbuf = Lexing.from_string source in
  match
    (try Ok (URMParser.mainParser URMLEX.readtoken lexbuf)
     with
     | Failure msg -> Error ("Lexing error: " ^ msg)
     | Parsing.Parse_error -> Error "Syntax error in program source")
  with
  | Error e -> Error e
  | Ok tops ->
    (* Only process ProgramDef entries — exec commands are ignored here;
       they are handled by the individual API endpoints. *)
    List.fold_left
      (fun acc_result t ->
        match acc_result with
        | Error _ as e -> e
        | Ok env ->
          match t with
          | ProgramDef (name, body) ->
            (try
              let p = interpret_body env body in
              let p_std = standardize p in
              Ok { programs = ProgramTable.add name p_std env.programs }
            with
            | ProgramNotFound msg -> Error ("Program not found: " ^ msg)
            | Failure msg -> Error ("Error building program: " ^ msg))
          | _ -> Ok env (* skip exec commands *))
      (Ok empty_env)
      tops

(* ------------------------------------------------------------------ *)
(* 2.  Step-by-step session table                                     *)
(* ------------------------------------------------------------------ *)

type session = {
  prog    : program;
  machine : urmmachine;
}

let sessions : (string, session) Hashtbl.t = Hashtbl.create 16

let new_session_id () =
  let b = Bytes.create 16 in
  for i = 0 to 15 do
    Bytes.set b i (Char.chr (Random.int 256))
  done;
  Bytes.to_seq b
  |> Seq.map (fun c -> Printf.sprintf "%02x" (Char.code c))
  |> List.of_seq
  |> String.concat ""

(* Initialise machine for a given program + input list *)
let make_machine (p : program) (args : int list) : urmmachine =
  let rho_val = rho p in
  let nargs   = List.length args in
  let padding = List.init (max 0 (rho_val - nargs)) (fun _ -> 0) in
  { rs = Array.of_list (args @ padding); pc = 1 }

(* ------------------------------------------------------------------ *)
(* 3.  JSON helpers                                                   *)
(* ------------------------------------------------------------------ *)

let ok_json data =
  `Assoc [("ok", `Bool true); ("data", data)]

let err_json msg =
  `Assoc [("ok", `Bool false); ("error", `String msg)]

let registers_to_json (rs : int array) : Yojson.Basic.t =
  `List (Array.to_list (Array.map (fun v -> `Int v) rs))

let instructions_to_json (p : program) : Yojson.Basic.t =
  `List (Array.to_list
    (Array.mapi
      (fun i instr -> `String (string_of_int (i+1) ^ ": " ^ instruction_to_string instr))
      p))

let respond json =
  Dream.json (Yojson.Basic.to_string json)

let respond_err msg =
  Dream.json (Yojson.Basic.to_string (err_json msg))

(* ------------------------------------------------------------------ *)
(* 4.  Request body parsing helpers                                   *)
(* ------------------------------------------------------------------ *)

let body_json req =
  Dream.body req >>= fun body ->
  Lwt.return (
    try Ok (Yojson.Basic.from_string body)
    with _ -> Error "Invalid JSON body"
  )

let get_string key json =
  match Yojson.Basic.Util.member key json with
  | `String s -> Ok s
  | _ -> Error (Printf.sprintf "Missing or invalid string field: '%s'" key)

let get_int key json =
  match Yojson.Basic.Util.member key json with
  | `Int i -> Ok i
  | _ -> Error (Printf.sprintf "Missing or invalid int field: '%s'" key)

let get_int_list key json =
  match Yojson.Basic.Util.member key json with
  | `List items ->
    Ok (List.filter_map (function `Int i -> Some i | _ -> None) items)
  | `Null -> Ok []
  | _ -> Error (Printf.sprintf "Field '%s' must be a list of integers" key)

(* ------------------------------------------------------------------ *)
(* 5.  Route handlers                                                 *)
(* ------------------------------------------------------------------ *)

(* GET /api/examples — list built-in example names *)
let handle_examples _req =
  let dir = "examples" in
  let entries =
    if Sys.file_exists dir && Sys.is_directory dir then
      Array.to_list (Sys.readdir dir)
      |> List.filter (fun f -> Filename.check_suffix f ".txt")
      |> List.map   (fun f -> Filename.chop_suffix f ".txt")
      |> List.sort  String.compare
    else []
  in
  respond (ok_json (`Assoc [("examples", `List (List.map (fun s -> `String s) entries))]))

(* GET /api/examples/:name — return source of named example *)
let handle_example_get req =
  let name = Dream.param req "name" in
  let path = Filename.concat "examples" (name ^ ".txt") in
  if not (Sys.file_exists path) then
    respond_err ("Example not found: " ^ name)
  else
    let ic     = In_channel.open_text path in
    let source = In_channel.input_all ic in
    In_channel.close ic;
    respond (ok_json (`Assoc [("source", `String source); ("name", `String name)]))

(* ------------------------------------------------------------------ *)
(* Saved-file helpers                                                 *)
(* ------------------------------------------------------------------ *)

let saved_dir = "saved"

let list_saved () =
  if Sys.file_exists saved_dir && Sys.is_directory saved_dir then
    Array.to_list (Sys.readdir saved_dir)
    |> List.filter (fun f -> Filename.check_suffix f ".txt")
    |> List.map   (fun f -> Filename.chop_suffix f ".txt")
    |> List.sort  String.compare
  else []

(* Sanitise a filename: keep only alphanumerics, dash, underscore, dot *)
let sanitise_name name =
  let buf = Buffer.create (String.length name) in
  String.iter (fun c ->
    if (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
       (c >= '0' && c <= '9') || c = '-' || c = '_' || c = '.'
    then Buffer.add_char buf c)
    name;
  Buffer.contents buf

(* GET /api/saved — list saved file names *)
let handle_saved_list _req =
  respond (ok_json (`Assoc [("saved", `List (List.map (fun s -> `String s) (list_saved ())))]))

(* GET /api/saved/:name — return source of a saved file *)
let handle_saved_get req =
  let name = sanitise_name (Dream.param req "name") in
  let path = Filename.concat saved_dir (name ^ ".txt") in
  if not (Sys.file_exists path) then
    respond_err ("Saved file not found: " ^ name)
  else
    let ic     = In_channel.open_text path in
    let source = In_channel.input_all ic in
    In_channel.close ic;
    respond (ok_json (`Assoc [("source", `String source); ("name", `String name)]))

(* POST /api/save — write editor source to saved/<name>.txt
   Body: { "name": "filename", "source": "...", "overwrite": true|false }
   If the file exists and overwrite is false, return an error so the
   browser can ask the user to confirm before retrying with overwrite:true. *)
let handle_save req =
  body_json req >>= function
  | Error e -> respond_err e
  | Ok json ->
    match get_string "name" json, get_string "source" json with
    | Error e, _ | _, Error e -> respond_err e
    | Ok raw_name, Ok source ->
      let name = sanitise_name raw_name in
      if name = "" then respond_err "Invalid filename" else
      let overwrite =
        match Yojson.Basic.Util.member "overwrite" json with
        | `Bool b -> b | _ -> false
      in
      let () = if not (Sys.file_exists saved_dir) then Unix.mkdir saved_dir 0o755 in
      let path = Filename.concat saved_dir (name ^ ".txt") in
      if Sys.file_exists path && not overwrite then
        (* Signal to the browser that confirmation is needed *)
        respond (ok_json (`Assoc [
          ("saved",    `Bool false);
          ("exists",   `Bool true);
          ("name",     `String name);
        ]))
      else begin
        let oc = Out_channel.open_text path in
        Out_channel.output_string oc source;
        Out_channel.flush oc;
        Out_channel.close oc;
        respond (ok_json (`Assoc [
          ("saved",  `Bool true);
          ("name",   `String name);
          ("exists", `Bool false);
        ]))
      end

(* POST /api/parse — parse source, return list of defined program names *)
let handle_parse req =
  body_json req >>= function
  | Error e  -> respond_err e
  | Ok json  ->
    match get_string "source" json with
    | Error e  -> respond_err e
    | Ok source ->
      match parse_source source with
      | Error e  -> respond_err e
      | Ok env   ->
        let names = ProgramTable.fold (fun k _ acc -> `String k :: acc) env.programs [] in
        respond (ok_json (`Assoc [("programs", `List names)]))

(* POST /api/run *)
let handle_run req =
  body_json req >>= function
  | Error e -> respond_err e
  | Ok json ->
    match get_string "source" json, get_string "name" json, get_int_list "args" json with
    | Error e, _, _ | _, Error e, _ | _, _, Error e -> respond_err e
    | Ok source, Ok name, Ok args ->
      match parse_source source with
      | Error e -> respond_err e
      | Ok env  ->
        match (try Ok (find_program name env)
               with ProgramNotFound n -> Error ("Program not found: " ^ n)) with
        | Error e -> respond_err e
        | Ok p    ->
          (try
            let rs = run p args in
            respond (ok_json (`Assoc [
              ("registers", registers_to_json rs);
              ("steps",     `Int (Array.length p));
            ]))
          with exn ->
            respond_err ("Runtime error: " ^ Printexc.to_string exn))

(* POST /api/runbound *)
let handle_runbound req =
  body_json req >>= function
  | Error e -> respond_err e
  | Ok json ->
    match get_string "source" json, get_string "name" json,
          get_int_list "args" json, get_int "bound" json with
    | Error e, _, _, _ | _, Error e, _, _ | _, _, Error e, _ | _, _, _, Error e ->
      respond_err e
    | Ok source, Ok name, Ok args, Ok bound ->
      match parse_source source with
      | Error e -> respond_err e
      | Ok env  ->
        match (try Ok (find_program name env)
               with ProgramNotFound n -> Error ("Program not found: " ^ n)) with
        | Error e -> respond_err e
        | Ok p    ->
          (try
            let rs = runbound p args bound in
            respond (ok_json (`Assoc [
              ("registers", registers_to_json rs);
              ("halted",    `Bool true);
            ]))
          with exn ->
            respond_err ("Runtime error: " ^ Printexc.to_string exn))

(* POST /api/eval *)
let handle_eval req =
  body_json req >>= function
  | Error e -> respond_err e
  | Ok json ->
    match get_string "source" json, get_string "name" json, get_int_list "args" json with
    | Error e, _, _ | _, Error e, _ | _, _, Error e -> respond_err e
    | Ok source, Ok name, Ok args ->
      match parse_source source with
      | Error e -> respond_err e
      | Ok env  ->
        match (try Ok (find_program name env)
               with ProgramNotFound n -> Error ("Program not found: " ^ n)) with
        | Error e -> respond_err e
        | Ok p    ->
          (try
            let result = eval p args in
            respond (ok_json (`Assoc [("result", `Int result)]))
          with exn ->
            respond_err ("Runtime error: " ^ Printexc.to_string exn))

(* POST /api/print *)
let handle_print req =
  body_json req >>= function
  | Error e -> respond_err e
  | Ok json ->
    match get_string "source" json, get_string "name" json with
    | Error e, _ | _, Error e -> respond_err e
    | Ok source, Ok name ->
      match parse_source source with
      | Error e -> respond_err e
      | Ok env  ->
        match (try Ok (find_program name env)
               with ProgramNotFound n -> Error ("Program not found: " ^ n)) with
        | Error e -> respond_err e
        | Ok p    ->
          respond (ok_json (`Assoc [("instructions", instructions_to_json p)]))

(* POST /api/printall *)
let handle_printall req =
  body_json req >>= function
  | Error e -> respond_err e
  | Ok json ->
    match get_string "source" json with
    | Error e -> respond_err e
    | Ok source ->
      match parse_source source with
      | Error e -> respond_err e
      | Ok env  ->
        let programs_json =
          ProgramTable.fold
            (fun name p acc -> (name, instructions_to_json p) :: acc)
            env.programs []
        in
        respond (ok_json (`Assoc [("programs", `Assoc programs_json)]))

(* POST /api/encode *)
let handle_encode req =
  body_json req >>= function
  | Error e -> respond_err e
  | Ok json ->
    match get_string "source" json, get_string "name" json with
    | Error e, _ | _, Error e -> respond_err e
    | Ok source, Ok name ->
      match parse_source source with
      | Error e -> respond_err e
      | Ok env  ->
        match (try Ok (find_program name env)
               with ProgramNotFound n -> Error ("Program not found: " ^ n)) with
        | Error e -> respond_err e
        | Ok p    ->
          (try
            let index = yota p in
            respond (ok_json (`Assoc [("index", `String (show index))]))
          with exn ->
            respond_err ("Encoding error: " ^ Printexc.to_string exn))

(* POST /api/decode *)
let handle_decode req =
  body_json req >>= function
  | Error e -> respond_err e
  | Ok json ->
    match get_string "index" json with
    | Error e -> respond_err e
    | Ok index_str ->
      (try
        let n = bs index_str in
        let p = uyota n in
        respond (ok_json (`Assoc [("instructions", instructions_to_json p)]))
      with exn ->
        respond_err ("Decoding error: " ^ Printexc.to_string exn))

(* POST /api/simulate *)
let handle_simulate req =
  body_json req >>= function
  | Error e -> respond_err e
  | Ok json ->
    match get_string "index" json, get_int_list "args" json with
    | Error e, _ | _, Error e -> respond_err e
    | Ok index_str, Ok args ->
      (try
        let n = bs index_str in
        let p = uyota n in
        let rs = run p args in
        respond (ok_json (`Assoc [("registers", registers_to_json rs)]))
      with exn ->
        respond_err ("Simulation error: " ^ Printexc.to_string exn))

(* POST /api/step/start *)
let handle_step_start req =
  body_json req >>= function
  | Error e -> respond_err e
  | Ok json ->
    match get_string "source" json, get_string "name" json, get_int_list "args" json with
    | Error e, _, _ | _, Error e, _ | _, _, Error e -> respond_err e
    | Ok source, Ok name, Ok args ->
      match parse_source source with
      | Error e -> respond_err e
      | Ok env  ->
        match (try Ok (find_program name env)
               with ProgramNotFound n -> Error ("Program not found: " ^ n)) with
        | Error e -> respond_err e
        | Ok p    ->
          let machine = make_machine p args in
          let sid     = new_session_id () in
          Hashtbl.replace sessions sid { prog = p; machine };
          respond (ok_json (`Assoc [
            ("session_id",     `String sid);
            ("registers",      registers_to_json machine.rs);
            ("pc",             `Int machine.pc);
            ("done",           `Bool (machine.pc > Array.length p));
            ("program_length", `Int (Array.length p));
            ("instructions",   instructions_to_json p);
          ]))

(* POST /api/step/next *)
let handle_step_next req =
  body_json req >>= function
  | Error e -> respond_err e
  | Ok json ->
    match get_string "session_id" json with
    | Error e -> respond_err e
    | Ok sid  ->
      match Hashtbl.find_opt sessions sid with
      | None -> respond_err "Session not found or expired"
      | Some { prog; machine } ->
        if machine.pc > Array.length prog then
          respond (ok_json (`Assoc [
            ("registers", registers_to_json machine.rs);
            ("pc",        `Int machine.pc);
            ("done",      `Bool true);
            ("executed",  `String "(halted)");
          ]))
        else begin
          let instr    = prog.(machine.pc - 1) in
          let executed = instruction_to_string instr in
          exec instr machine;
          respond (ok_json (`Assoc [
            ("registers", registers_to_json machine.rs);
            ("pc",        `Int machine.pc);
            ("done",      `Bool (machine.pc > Array.length prog));
            ("executed",  `String executed);
          ]))
        end

(* POST /api/step/reset *)
let handle_step_reset req =
  body_json req >>= function
  | Error e -> respond_err e
  | Ok json ->
    match get_string "session_id" json with
    | Error e -> respond_err e
    | Ok sid  ->
      Hashtbl.remove sessions sid;
      respond (ok_json (`Assoc []))

(* ------------------------------------------------------------------ *)
(* 6.  CORS middleware                                                *)
(* ------------------------------------------------------------------ *)

let cors_middleware handler req =
  handler req >>= fun response ->
  Dream.add_header response "Access-Control-Allow-Origin"  "*";
  Dream.add_header response "Access-Control-Allow-Methods" "GET, POST, OPTIONS";
  Dream.add_header response "Access-Control-Allow-Headers" "Content-Type";
  Lwt.return response

(* ------------------------------------------------------------------ *)
(* 7.  Main                                                           *)
(* ------------------------------------------------------------------ *)

let () =
  Random.self_init ();
  Dream.run ~port:8080
  @@ Dream.logger
  @@ cors_middleware
  @@ Dream.router [

    (* Examples (built-in, read-only) *)
    Dream.get  "/api/examples"       handle_examples;
    Dream.get  "/api/examples/:name" handle_example_get;

    (* Saved files (user-writable) *)
    Dream.get  "/api/saved"          handle_saved_list;
    Dream.get  "/api/saved/:name"    handle_saved_get;
    Dream.post "/api/save"           handle_save;

    (* Parse / inspect *)
    Dream.post "/api/parse"          handle_parse;
    Dream.post "/api/print"          handle_print;
    Dream.post "/api/printall"       handle_printall;

    (* Execute *)
    Dream.post "/api/run"            handle_run;
    Dream.post "/api/runbound"       handle_runbound;
    Dream.post "/api/eval"           handle_eval;

    (* Gödel encoding *)
    Dream.post "/api/encode"         handle_encode;
    Dream.post "/api/decode"         handle_decode;
    Dream.post "/api/simulate"       handle_simulate;

    (* Step-by-step *)
    Dream.post "/api/step/start"     handle_step_start;
    Dream.post "/api/step/next"      handle_step_next;
    Dream.post "/api/step/reset"     handle_step_reset;

    (* OPTIONS preflight for CORS *)
    Dream.options "/**" (fun _req -> Dream.empty `No_Content);

    (* Root — serve index.html explicitly *)
    Dream.get "/" (fun _req -> Dream.from_filesystem "public" "index.html" _req);

    (* Static files — serve the public/ directory last *)
    Dream.get "/**" (Dream.static "public");
  ]
