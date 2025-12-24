 (* URM_machine *)

open URM_types 

(* -------------------- *)
(* type URM instruction *)
(* -------------------- *)
(*
type instr = 
  Zero of int
| Succ of int
| Tran of int * int
| Jump of int * int * int ;;


(* type program *)
type program = 
instr array
;;
*)

(* type URM *)
type urmmachine = {
mutable rs: int array; 
mutable pc: int;
} ;;


(* pretty print an instruction *)
let print_instruction i =
match i with
Zero n -> Printf.printf "Z(%n)\n" n ; 
|Succ n -> Printf.printf "S(%n)\n" n ; 
|Tran (m, n) ->  Printf.printf "T(%n,%n)\n" m n ;  
|Jump (m, n, q) ->  Printf.printf "J(%n,%n,%n)\n" m n q 
;;

(* pretty print a program *)
let print_program (p:program) =
  for  i=0 to ((Array.length p) - 1) do
      Printf.printf "%n : " (i+1); 
      print_instruction p.(i);
  done ;
  print_newline() 
;;

  (* sugar *)

let print_urm = print_program ;;

(* execute one instruction i on a machine u *)
let exec i u =
u.pc <- u.pc + 1;
match i with
  Zero n -> u.rs.(n-1) <- 0 ;
|Succ n -> u.rs.(n-1) <- (u.rs.(n-1) + 1) ;
|Tran (m, n) -> u.rs.(n-1) <- u.rs.(m-1) ;
|Jump (m, n, q) ->  u.pc <- if (u.rs.(m-1) == u.rs.(n-1)) then q else u.pc ;;

(* find the max in the new register list *)
let getmax = fun instlist -> 
let rec getmaxaux = fun  m i ->
if i > m then i else m 
in List.fold_left getmaxaux 0 instlist  ;;


(* pretty print an instruction *)
let print_instruction i =
match i with
Zero n -> Printf.printf "Z(%n)\n" n ; 
|Succ n -> Printf.printf "S(%n)\n" n ; 
|Tran (m, n) ->  Printf.printf "T(%n,%n)\n" m n ;  
|Jump (m, n, q) ->  Printf.printf "J(%n,%n,%n)\n" m n q 
;;

(* pretty print a program *)
let print_program (p:program) =
  for  i=0 to ((Array.length p) - 1) do
      Printf.printf "%n : " (i+1); 
      print_instruction p.(i);
  done ;
  print_newline() 
;;

  (* sugar *)

let print_urm = print_program ;;

(* execute one instruction i on a machine u *)
let exec i u =
u.pc <- u.pc + 1;
match i with
  Zero n -> u.rs.(n-1) <- 0 ;
|Succ n -> u.rs.(n-1) <- (u.rs.(n-1) + 1) ;
|Tran (m, n) -> u.rs.(n-1) <- u.rs.(m-1) ;
|Jump (m, n, q) ->  u.pc <- if (u.rs.(m-1) == u.rs.(n-1)) then q else u.pc ;;

(* find the max in the new register list *)
let getmax = fun instlist -> 
let rec getmaxaux = fun  m i ->
if i > m then i else m 
in List.fold_left getmaxaux 0 instlist  ;;


(* create a list (a,..,a+n-1) of length n*)
let rec listinit = fun a n ->
if n <= 0 then [] else
if n = 1 then [a] else a :: listinit (a+1) (n-1) ;;

(* create a list (a,..,a) of length n*)
let rec listreset = fun a n ->
if n <= 0 then [] else
if n = 1 then [a] else
a :: listreset (a) (n-1) ;;
    
(* find rho in one instruction *)
let rhoinst (inst:instr) =
  match inst with 
     Jump (m,n,q) -> getmax[m;n]
   | Tran(m,n) -> getmax[m;n]
   | Zero(n) -> n 
   | Succ(n) -> n
;;

let rho (p:program) = 
let rec rhoaux = fun (instlist:program) i max  -> 
if i = Array.length instlist then max
else let m' = rhoinst (instlist.(i)) in 
    rhoaux instlist (i+1) (getmax [m';max])
in rhoaux p 0 0 ;;

(* run P(a1,..,an) *)
let run (p:program) (il: int list) : int array = 
(* load input *)
let rlist = il@(listreset 0 (rho p)) in 
let u = {rs = (Array.of_list rlist); pc = 1} in
while u.pc <= (Array.length p) do
  let i = p.(u.pc-1) in
    exec i u
done;
u.rs ;;

(* run P(a1,..,an) for n steps *)
let runbound p il n = 
  (* load input *)
  let count = ref 0 in 
    let rlist = il@(listreset 0 (rho p)) in 
      let u = {rs = (Array.of_list rlist); pc = 1} in
        while u.pc <= (Array.length p) && (!count < n) do
          let i = p.(u.pc-1) in
          exec i u;
        count := !count + 1
        done;
  u.rs ;;

(* run P(a1,..,an) as a function *)
let eval (p:program) (il:int list) :int = 
(* load input *)
let rlist = il@(listreset 0 (rho p)) in 
let u = {rs = (Array.of_list rlist); pc = 1} in
while u.pc <= (Array.length p) do
  let i = p.(u.pc-1) in
    exec i u
done;
u.rs.(0) ;;
    
(* run P(a1,..,an) on a machine u *)
let runthis u p il = 
let rlist = il@(listreset 0 (rho p)) in 
u.rs <- (Array.of_list rlist);
while u.pc <= (Array.length p) do
  let i = p.(u.pc-1) in
    exec i u
done;
u ;;

(* operations on programs*)
let standardize (p:program):program =
  let standardize_instruction = fun l i ->
  match i with  
      Jump (n,m,k) -> Jump (n,m,(if k >= l+1 then l+1 else k));
    | Tran(n,m) -> Tran(n,m);
    | Zero(n) -> Zero(n);
    | Succ(n) -> Succ(n);
  in let l = Array.length p in
  Array.map (standardize_instruction l) p 
;;

(* ================================ *)
(* 1. concatenation: P; P'          *)
(* ================================ *)

let concatenate (p:program) (p':program) : program =
let reindex = fun s i ->
match i with  
    Jump (m,n,q) -> Jump (m,n,s+q) ;
  | Tran(m,n) -> Tran(m,n);
  | Zero(n) -> Zero(n);
  | Succ(n) -> Succ(n);
in let s = Array.length p in
let q = Array.map (reindex s) (standardize p')
in Array.append (standardize p) q ;;

(* ================================ *)
(* 1.b. concatenation ('): P; P'    *)
(* assumptions: P in standard form  *)
(* ================================ *)

let concatenate' (p:program) (p':program) : program =
let reindex = fun s i ->
match i with  
   Jump (m,n,q) -> Jump (m,n,s+q) ;
  | Tran(m,n) -> Tran(m,n);
  | Zero(n) -> Zero(n);
  | Succ(n) -> Succ(n);
in let s = Array.length p in
let q = Array.map (reindex s) (standardize p')
in Array.append p q ;;


(* ================================ *)
(* 1.c. concatenation program list  *)
(* ================================ *)

  let concatenateList pl = 
    List.fold_right concatenate pl [||] ;;

(* building up other compositional operations *)

(*   find the max in the new register list *)
let getmax = fun instlist -> 
let rec getmaxaux = fun  m i ->
if i > m then i else m 
in List.fold_left getmaxaux 0 instlist  ;;

    
(* find rho aux*)
let rhoinst = fun instlist -> 
let rhoinstaux = fun max i ->
match i with 
    Jump (m,n,q) -> getmax[m;n;max]
  | Tran(m,n) -> getmax[m;n;max]
  | Zero(n) -> getmax [max;n]
  | Succ(n) -> getmax [max;n]
in rhoinstaux 0 instlist ;;
 
   
let rho = fun program  -> 
let rec rhoaux = fun instlist i max  -> 
if i = Array.length instlist then max
else let m' = rhoinst (instlist.(i)) in 
    rhoaux instlist (i+1) (getmax [m';max])
in rhoaux program 0 0 ;;

(* Trans(m,n), .. ,Tran(m+k-1,n+k-1)*)
let rec listOfTrans = fun m n k -> 
if k <= 0 then []
else if k = 1 then [Tran (m,n)]
else Tran(m,n)::(listOfTrans (m+1) (n+1) (k-1)) ;;
    
(* Trans(l_1,1), .. ,Tran(l_k,k), given a list of l_1,..,l_k*)
let listOfTrans' = fun rlist -> 
let rec aux = fun rlist k -> 
if (List.length rlist) = 1 then [Tran((List.hd rlist),k)]
else let ln = List.length rlist in 
    Tran((List.hd rlist),k-ln+1)::(aux (List.tl rlist) k) 
in aux rlist (List.length rlist) ;;

(* Zero(m), .. , Zero(m+k) *)
let rec listOfZeros = fun m k -> 
if k >= 1 then
Zero(m)::(listOfZeros (m+1) (k-1))
else [] ;;


(* ======================= *)
(* P[i1,..,in --> i_{n+1}] *)
(* ======================= *)

let relocate (p:program) (ris: int list) (ro: int) :program = 
(* find max aux *)
let k = rho p 
in let n = List.length ris in 
let ts = Array.of_list (listOfTrans' ris) in
(* Z(n+1) .. Z(rho(P)) *)
let zs = Array.of_list (listOfZeros (n+1) (if k-n > 0 then k-n-1 else 0)) in
(* I need to concatenate P here *)
let ht = Array.append ts zs in
let htp = concatenate ht p in 
Array.append htp [|Tran(1,ro)|] ;;

(* ====== now I have a programmable machine =======*)

(* G_1[m,.., m+n-1 -> m+n], .. ,G_k[m,..,m+n-1 -> m+n+k-1], given G_1,..,G_k and m and n *)

let listOfGs (glist: program list) m n =
  let rlist = listinit m n in
  let relocated_list =
    List.mapi (fun i g -> relocate g rlist (m + n + i)) glist
  in
  Array.concat relocated_list
;; 

(* ========================= *)
(* compose f(g1(x),.., gk(x))*)
(* assumptions:              *)
(* f k-ary, gs n-ary         *) 
(* ========================= *)

let compose (f: program) (glist: program list) (n: int) : program =
  let k = List.length glist in
   let rhoglist = List.map rho (f :: glist) in
    let m = getmax (n :: k :: rhoglist) in
     let ts = Array.of_list (listOfTrans 1 (m + 1) n) in
      let gs = listOfGs glist (m + 1) n in
       let rlist = listinit (m + n + 1) k in
        let f_relocated = relocate f rlist 1 in
  (* errata: Array.concat [ts; gs; f_relocated] *)
    concatenateList[ts;gs;f_relocated]
;; 

(* ========================= *)
(* recursion f g n           *)
(* assumptions:              *)
(* f n-ary, g n+2-ary        *) 
(* output: h is n+1-ary      *)
(* ========================= *)


let recursion (f : program) (g : program) (n : int) : program =
  let m = getmax [n + 2; rho f; rho g] in
  let t = m + n in

  (* T(1,m+1),...,T(n+1,m+n+1) *)
  let ts = Array.of_list (listOfTrans 1 (m + 1) (n + 1)) in

  (* F(1,...,n) -> t+3 *)
  let rf =
    if n > 0 then relocate f (listinit 1 n) (t + 3)
    else relocate f [1] (t + 3)
  in

  let tsrf = concatenate ts rf in
  let q = Array.length tsrf + 1 in

  (* G(m+1,...,m+n,t+2,t+3) -> t+3 *)
  let rlist = (listinit (m + 1) n) @ [t + 2; t + 3] in
  let rg = relocate g rlist (t + 3) in

  (* Compose everything *)
  let tsrf_jump = Array.concat [tsrf; [| Jump(t + 1, t + 2, q + Array.length rg + 3) |]] in
  let tsrfrg = concatenate' tsrf_jump rg in

  Array.concat [ tsrfrg; [| Succ(t + 2); Jump(1, 1, q); Tran(t + 3, 1) |] ]
;;

(* ========================= *)
(* minimalization    f n     *)
(* assumptions:              *)
(* f n+1-ary,                *) 
(* output: h is n+1-ary      *)
(* ------------------------- *)
(* should it be h n-ary?     *)
(* ========================= *)
                
let minimalization (f:program) (n:int) :program =
let m = getmax [n+1;rho(f)] in
(* T(1,m+1),..,T(n,m+n), length n-1*)
let ts = Array.of_list (listOfTrans 1 (m+1) (n)) in
(* F(m+1,..,m+n,m+n+1 -> 1) *)
let rf = relocate f (listinit (m+1) (n+1)) (1) in
let p = n+1   in
              let q = n + (Array.length rf) + 4 in
               let tsrf = concatenate ts rf in
                  Array.concat [tsrf;
                    [|
                    Jump(1,m+n+2,q);
                    Succ(m+n+1);
                    Jump(1,1,p); 
                    Tran (m+n+1,1)
                    |]
                 ];;
