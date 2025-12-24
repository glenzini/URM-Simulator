open URM_types;;
open URMLEX ;;

(* ---------------- *)
(*   input/output   *)
(* ---------------- *)

(* pretty print an instruction *)
let instruction_to_string (i:instr) =
match i with
|  Zero n -> "Z(" ^ Int.to_string n ^ ")"  ; 
|  Succ n -> "S(" ^ Int.to_string n ^ ")"  ; 
|  Tran (m,n) -> "T(" ^ Int.to_string m ^"," ^ Int.to_string n ^")"  ; 
|  Jump (m,n,q)-> "J(" ^ Int.to_string m ^ "," ^ Int.to_string n ^ "," ^Int.to_string q ^ ")"   
;;

(* program to string *)
let program_to_string (p:program) =
  let build_line n inst = 
    Int.to_string (n+1) ^ ": " ^ instruction_to_string inst in
  String.concat "\n" (Array.to_list (Array.mapi build_line p)) ^ "\n"
;;
(* ---------------- *)
(* save into a file *)
(* ---------------- *)

let write_to_file (head : string) (p:program) (filename : string) =
  (* Step 1: Open the File *)
  let oc = Out_channel.open_text filename in
      Out_channel.output_string oc (head);
  (* Step 2b: Write to the Channel *)
    let build_line n inst = 
       Int.to_string (n+1) ^": " ^ instruction_to_string inst in 
  Array.iteri
    (fun i instr ->
      let s = build_line i instr in
      Out_channel.output_string oc (s^"\n"))
    p;
  (* Step 3: Flush the Channel *)
  Out_channel.output_string oc (";;");
  Out_channel.flush oc;
  (* Step 4: Close the Channel *)
  Out_channel.close oc
;;

