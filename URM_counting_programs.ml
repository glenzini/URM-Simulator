(* ----------------------------- *)
(* Section 2: encoding programs *)
(* ----------------------------- *)

(* ====== encoding URM machines ======= *)

(* for Big int *)

(* 
#require "zarith" ;; 
#load "zarith.cma" ;;
*)

open Z ;;
open URM_types ;;
open URM_machine ;;

(* 2^i *)
let twoexp i =
  Big_int_Z.(power_big_int_positive_big_int (big_int_of_int 2) i) ;;


(* show *)
let show = fun n ->
  Big_int_Z.string_of_big_int n;; 

(* exponent of 2 in the (decimal) factorization of n *)
let findtwoexp n = 
  let rec findtwoexpaux n i =
    (* if n mod 2 <>  0 *)
    if  Big_int_Z.sign_big_int (Big_int_Z.mod_big_int n (Big_int_Z.big_int_of_int 2)) > 0
    then i
    else findtwoexpaux (Big_int_Z.div_big_int n (Big_int_Z.big_int_of_int 2)) (Big_int_Z.(add_big_int i (big_int_of_int 1)))
  in findtwoexpaux n (Big_int_Z.big_int_of_int 0) ;;


(* the largest k such that 2^k < n *)
let intlog n =
  let rec intlogaux n k =
    let twoatk = twoexp k in
      (* if n < 2^k *)
      if (Big_int_Z.compare_big_int n twoatk) < 0  then (Big_int_Z.pred_big_int k) 
      (* else *)
      else intlogaux n(Big_int_Z.succ_big_int k)
  in intlogaux n (Big_int_Z.big_int_of_int 0) ;;

(* encode pairs *)
let encodePair = fun m n ->
  (* 2^m * (2n + 1) - 1 ;; *)
  Big_int_Z.(
    pred_big_int 
      (mult_big_int
         (twoexp m)
         (add_big_int
            (mult_big_int (big_int_of_int 2) n)
            (big_int_of_int 1))) 
  );;


(* decode to pairs *)
let decodeFirstOfPair = fun n -> 
  findtwoexp (Big_int_Z.(add_big_int n (big_int_of_int 1))) ;;


let decodeSecondOfPair = fun n ->
  Big_int_Z.
    (div_big_int
       (pred_big_int
          (div_big_int
             (add_big_int n (big_int_of_int 1))
             (twoexp (decodeFirstOfPair n))
          )
       )(big_int_of_int 2)
    ) ;;

let decodePair n =
  [decodeFirstOfPair n; decodeSecondOfPair n] ;;

(* encode triple *)
let encodeTriple n m q =
  encodePair (encodePair (Big_int_Z.pred_big_int n) (Big_int_Z.pred_big_int m))
    (Big_int_Z.pred_big_int q) ;;


(* decode to triple *)
let decodeFirstOfTriple = fun n ->
  Big_int_Z.add_big_int (decodeFirstOfPair (decodeFirstOfPair n))
    (Big_int_Z.big_int_of_int 1);;


let decodeSecondOfTriple = fun n ->
  Big_int_Z.add_big_int (decodeSecondOfPair (decodeFirstOfPair n))
    (Big_int_Z.big_int_of_int 1);; 


let decodeThirdOfTriple = fun n ->
  Big_int_Z.add_big_int (decodeSecondOfPair n)
    (Big_int_Z.big_int_of_int 1);; 


let decodeTriple = fun n -> [decodeFirstOfTriple n; decodeSecondOfTriple n; decodeThirdOfTriple n] ;;

let encodeList ln =
  let rec encodeListAux lna encode exp c =
    if List.length lna = 1  then
      (* if lna = [a_k] then 2^(a_k+exp+c) - 1 assuming exp = a_1+..+a_k-1 and c = k-1*)
      let exp' = Big_int_Z.(add_big_int (add_big_int (List.hd lna) exp) c)
      (* encode + 2^(a_k+(a_1+..+a_k-1)+k-1) assuming encode all what preceeds (see page 74) *)
      in Big_int_Z.(pred_big_int (add_big_int encode (twoexp exp')))
    else
      let hlna = List.hd lna in
      (* a_(k-1) + exp *)
      let exp' = Big_int_Z.(add_big_int exp hlna)
      (* encode + 2^(a_(k-1) + exp + c)*)
      in let encode' = Big_int_Z.add_big_int encode (twoexp (Big_int_Z.add_big_int exp' c))
      in encodeListAux (List.tl lna) encode' exp' (Big_int_Z.succ_big_int c)
  in
    encodeListAux ln (Big_int_Z.big_int_of_int 0)
      (Big_int_Z.big_int_of_int 0)
      (Big_int_Z.big_int_of_int 0) ;;


let listofBs m =
  let rec decodeaux n =
    let k = intlog n in
    let twoatk = twoexp k in 
      if (Big_int_Z.compare_big_int twoatk  n) = 0 then [k]
      else k::(decodeaux (Big_int_Z.sub_big_int n twoatk)) 
  in decodeaux m ;;


let rec listofAs bs = 
  if ((List.length bs) = 1) then bs
  else let bk  = (List.hd bs) in 
    let bk' = (List.hd(List.tl bs)) in
      listofAs (List.tl bs)@
      [Big_int_Z.pred_big_int (Big_int_Z.sub_big_int bk bk')] ;;


let decodeList m = listofAs (listofBs (Big_int_Z.succ_big_int m)) ;;

let beta = fun i ->
  match i with
     Zero(n) -> Big_int_Z.(mult_big_int (big_int_of_int 4) (pred_big_int (big_int_of_int n))) ;
    |Succ(n) -> Big_int_Z.(add_big_int  (mult_big_int (big_int_of_int 4) (pred_big_int (big_int_of_int n))) (big_int_of_int 1)) ;
    |Tran (m, n) -> 
        let encodedpair = encodePair (Big_int_Z.(pred_big_int (big_int_of_int m))) (Big_int_Z.(pred_big_int (big_int_of_int n)))
        in Big_int_Z.(add_big_int  (mult_big_int (big_int_of_int 4) encodedpair) (big_int_of_int 2)) ;
    |Jump (m, n, q) -> 
        let encodedtriple = encodeTriple (Big_int_Z.big_int_of_int m) (Big_int_Z.big_int_of_int n) (Big_int_Z.big_int_of_int q)
        in Big_int_Z.(add_big_int  (mult_big_int (big_int_of_int 4) encodedtriple) (big_int_of_int 3)) ; ;;


let yotalist = fun li  ->
  let listofencoded = List.map beta li in
    encodeList listofencoded  ;;

let yota = fun p ->
  let instlist = Array.to_list p in 
    yotalist instlist ;;

  (* top level encode *)
let encode = fun p ->
  yota p
;;

let ubeta x =
  let u = (Big_int_Z.div_big_int x (Big_int_Z.big_int_of_int 4)) in
    match (Big_int_Z.int_of_big_int (Big_int_Z.mod_big_int x (Big_int_Z.big_int_of_int 4))) with
        0 -> Zero(Big_int_Z.int_of_big_int (Big_int_Z.succ_big_int u));
      | 1 -> Succ(Big_int_Z.int_of_big_int (Big_int_Z.succ_big_int u));
      | 2 -> let m = (decodeFirstOfPair u)
          and n = (decodeSecondOfPair u)
          in Tran(Big_int_Z.int_of_big_int (Big_int_Z.succ_big_int m), 
                  Big_int_Z.int_of_big_int (Big_int_Z.succ_big_int n));
      | 3 -> let m = Big_int_Z.int_of_big_int (decodeFirstOfTriple u)
          and n = Big_int_Z.int_of_big_int (decodeSecondOfTriple u)
          and q = Big_int_Z.int_of_big_int (decodeThirdOfTriple u)
          in Jump(m,n,q) ;;


let uyota n =
  let ns = decodeList n in
    Array.of_list (List.map ubeta ns) ;;

(* top level decode *)
let decode n = 
   uyota n
;;

(* conversion int --> big_int *)
let bi n = Big_int_Z.big_int_of_int n ;;

(* conversion string --> big_int *)
let bs n = Big_int_Z.big_int_of_string n ;;

(* the universal machine *)
let universal n = (uyota n) ;;
