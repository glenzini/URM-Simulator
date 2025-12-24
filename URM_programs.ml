(* -------------------- *)
(*  some example of URM *)
(* -------------------- *)

#use "URM_machine.ml" ;;

(* I need a function that load a program in the machine *)
let rl = create ();;

eval [|Succ(1)|][2;3]  ;;
(* 3 *)
run  [|Succ(1)|][2;3]  ;;
 
eval [|Zero(2)|][2;3]  ;;
(* 2 *)
run  [|Zero(2)|][2;3;4]  ;;

eval [|Tran(3,1)|][2;3;4]  ;;
run  [|Tran(3,1)|][2;3;4]  ;;

(* *************** *)
(* Basic Functions *)

(* Projection *)
let proj i = [|Tran(i,1)|];;

(* BEGIN test *)
print_program (proj 3) ;;

eval (proj 2) [20;3;0]  ;;
(* 3 *)
run (proj 2) [20;3;0]  ;;
(* 3 3 0 *)
(* END tests *)

(* Aritmetic functions *)

(* addition *)
let sum = [|
Jump (1,3,5);
Succ(2); 
Succ(3); 
Jump(1,1,1); 
Tran(2,1)|] ;;

(* test *)
print_program sum ;;

eval sum [20;3;0] ;;
(* 23 *)
run sum [20;3;0]  ;;
(* 23 23 20 *)

(* predecessor  *)
let pred = [|
Zero(3);
Jump (1,3,24);
Zero(2);
Succ(2); 
Jump (1,2,9);
Succ(2);
Succ(3);
Jump(1,1,5); 
Tran(3,1)|] ;; 

print_program pred ;;

eval pred [51] ;;
(*51*)
run pred [51] ;;

(* BEGIN tests *)
(* ----------------- *)
(*    standardize    *)
(* ----------------- *)

print_program pred ;;
print_program (standardize pred) ;;

(* ----------------- *)
(* concatenate p ; q *)
(* ----------------- *)

let doublesum = concatenate sum sum;;
print_program doublesum ;;

eval doublesum [20;30] ;;
(*80*)
run doublesum [20;30] ;;

let doublepred = concatenate pred pred;;
print_program doublepred ;;

eval doublepred [20;30] ;;
(*18*)
run doublepred [20;30] ;;

(* -------------------------------------------------- *)
(* macro p[l1,..,lk --> l]  written as p [l1;..;lk] l *)
(* -------------------------------------------------- *)

let pred' = relocate pred [4] 3 ;;
print_program pred' ;;
run pred' [0;0;0;5;0] ;;

let sum' = relocate sum [5;6] 2 ;;
run sum' [0;0;0;0;6;7] ;;

(* ------------------------------------------------ *)
(*     compose f n-ary, [g1, .. , gn] k-ary, n      *)
(* ------------------------------------------------ *)
let sumsum = compose sum [sum;sum] 2 ;;
print_program sumsum ;;
eval sumsum [2;6] ;;
(* 16 *)

let succ = [|Succ(1)|];;
let succsucc = compose succ [succ] 1 ;;
eval succsucc [3] ;;
(* 5*)
let sumsucc = compose sum [succ; succ] 2 ;;
eval sumsucc [3] ;;
(* 8 *)

(* ------------------------------------------------- *)
(*        recursion f n-ary, g n+2-ary, n            *)
(* ------------------------------------------------- *)


(* example : sum as a recursive function *)
(* sum (x,0) = id (x)                    *)
(* sum (x,y) = succ (sum(x,y-1))         *)

(* identity function / projection        *)
let id  =
  [|Tran(1,1)|] ;;

let g = 
  compose [|Succ(1)|] [[|Tran(3,1)|]] 3 ;; 

let sumrec = recursion f g 1 ;; 
eval sumrec [2];;
(* 2 *)
eval sumrec [22;9];;
(* 31 *)

(* ----------------------------------------------- *)
(*              minimalization f n-ary, n          *)
(* ----------------------------------------------- *)

(* example : subtraction as minimalization    *)
(* subtraction (x,y) = min y : sub(x,y-1) = 0 *)

(* sub (x,y) defined if x >= y *)
let sub = 
[|
  Zero(3); 
  Jump (2,3,8); 
  Jump(1,2,7); 
  Succ(2); 
  Succ(3); 
  Jump(1,1,3);
 Tran(3,1)
|] ;; 

eval sub [3;0] ;;
eval sub [3;1] ;;
eval sub [3;2] ;;
eval sub [3;3] ;;
eval sub [3;4] ;; (* carefull: it does not terminate *)

(* preecedessor *)
pred ;;
eval pred 6;;

(* function f(x,y) = x - (y-1)) *)
let test = (compose sub [id; pred] 2) ;;

eval test [4;7] ;

(* projection U_3 *)
eval (proj 3) [4;6;3] ;;

(* pred (x,y) = y-1 *)
eval (compose pred [(proj 2)] 2) [4;5] ;;

(* subpred(x,y) = sub(x, y-1) *)
let subpred = (compose sub [id; (compose pred [(proj 2)] 2)] 2) ;;
eval subpred [4;1] ;;

(* example: min y such that sub(x,y-1) = 0 *)
let g = minimalization subpred 1 ;; 
print_program g ;;

eval g [3];;
(* 4 *)
eval g [5];;
(* 6 *) 