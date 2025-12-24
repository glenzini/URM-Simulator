# Introduction

This code is to compose and simulate URM machines as describeded in [1]. It is organized in two parts:

1) an Ocaml implementation of URM, following the theory. It implements all the URM instructions, the operator to compose URMs (substitution, recursion, minimalization), and the functions that encode and decode URM into natural numbers, and this lead to an Ocaml implementation of a URM universal machine.

2) an command line interpreter. It refers to a simple language I have defined to write URM's programs, compose URMs, code and decode a URM, and some auxiliary operator to print (on the screen) a URM's set of instruction, store them into a .txt file, to read from a .txt file and to run and eval a URM. It semantics is based on the Ocaml functions above.

The way to play with URMs is by using [2], but one can play with the Ocaml code to see how example the theory has been implemented in practice.

There is no GUI. This is future work. Let me know describe the Ocaml implementation and the command line interface to use for playing with URMs.

-----

# References

[1] Nigel Cutland "Computability Theory: An introduction to recursive function theory", Cambridge University Press, 1980 ISBN-10 0521294657, ISBN-13 978-0521294652

-----

# URM

An Ocaml implementation of a URM machine, the theory behind it, and a few libraries of programs. You can use this code, either in your own Ocaml interpreter, or Jupyter, or calling it as command [line interpreter](#the-inline-interpreter): I have defined the lexer, the parser, and compiled the code into a full interpreter.

How to use the Ocaml code:

### Load the .ml "library"

```ocaml
#use "URM-machine-2021.ml" ;;
```

### Writing URM programs

After having loaded "URM-machine-2021.ml" you can "Ocaml" write and build URM programs.

A program, with a name here 'program_name' is an array of URM instruction

```ocaml
let <program_name<> = 
[|
<(URM instructions;)*>
|]
```
where each URM instruction is of the following command

```ocaml
Zero(n)
Succ(n)
Tran(n,m)
Jump(n,m,q)
```
where n, m, and q are positive natural number. Examples are found in this file. 

```ocaml
print_program <program_name> ;;
```
will pretty printing the program

*Note*: a URM program does not have parameters. Input will be what the program finds in the registers when it runs. The way to run the program, given an arrays of values which represent the values in R1, R2, etc. will be as follows:

```
eval <program_name> [R1;...;Rn] ;;

run  <program_name> [R1;...;Rn] ;;

runbounded <program_name> [R1;...;Rn] n ;;
```
The first (eval) return the value of the R1, that is the output of the computation. The second (run) returns the final configuaration of all the registers that have been used by the computation. The third (runbounded), returns the configuration of all the registers that have been used by the computation *AFTER n steps*.

There is function 'standardize' that returns a program in standard form. You do not need to use it, but it will be used when compositing programs which is what it is explained next. 

### Composing URM programs

There are a few operators that you can to "compose" programs in addition to list the instructions. The operators comes from the partial recursive functions theory: substitution, recursion, and minimalization.

#### 1. concatenate

```ocaml
(* ====================== *)
(*  concatenation: P; P'  *)
(* =======================*)

// concatenate <p> and <p'>, two URM programs

concatenate <p> <p'> ;;

// If you with to name the program, you have to:

let <program_name> = concatenate <p> <p'> ;;
```

#### 2. Relocation

The following command, given a program <p>, returns a program that run by taking as input a list of registers, other then R1, R2, .., Rn and that returns the output into another register than R1

```ocaml
(* =================================== *)
(* relocation: P[i1,..,ik --> i_{k+1}] *)
(* =================================== *)

// relocate <p>: returns a URM programs
// that takes in input registers  $R_i1, ..., R_ik$
// and returns the output in $R_j$

relocate <p> [i_1; ...;i_k] j ;;

// If you wish to name the new program, you have to:

let <program_name> = relocate <p> [i_1; ...;i_k] j ;;
```

#### 3. Substitution

The following command takes a program <f> (as k-ary function) and a *list* of programs 
[<g1>; ..;<gk>] (all as n-ary functions) and returns a program is the substitution f(g1,...,gk). The commands need to know $n$ the arity of the <g>'s

```ocaml
(* ========================== *)
(* compose f(g1(x),.., gk(x)) *)
(* f k-ary, g's n-ary         *) 
(*----------------------------*)
(* output: h, k-ary           *)
(* ========================== *)

compose <p1> [<g1>; ...; <gk>] n

// If you wish to name the new program, you have to:

let <program_name> = compose <f> [<g1>;...;<gk>] n ;;
```

#### 4. Recursion

The following command takes a program <f> (as n-ary function) and a program 
<g> (n+2-ary functions) and returns a program is defined by recursion from <f> and <g>.
The commands need to know $n$ the arity of the <f>s

```ocaml
(* ========================= *)
(* recursion f g n           *)
(* assumptions:              *)
(* f n-ary, g n+2-ary        *) 
(*---------------------------*)
(* output: h,  n+1-ary       *)
(* ========================= *)

recursion <f> <g> n ;;

// If you wish to name the new program, you have to:
Oc
let <program_name> = recursion <f> <g> n;;
```

#### 5. Minimalization

The following command takes a program <f>, a n+1-ary functin, and returns a program that implement minimalization, that is a search from the minimal y, such that f(x,y) == 0, if that y exists. The commands need to know $n$.

```ocaml
(* ========================= *)
(* minimalization f n        *)
(* assumptions:              *)
(* f n+1-ary,                *) 
(* ------------------------- *)
(* output: h,  n-ary         *)
(* ========================= *)

minimalization <f> n ;;

// If you wish to name the new program, you have to:

let <program_name> = minimalization <f> n ;;
```

## Codding, Decoding, Universal URM 

### Load the .ml "library"

```ocaml
#use "URM_counting_programs.ml" ;;
```
Note: if you use the code with an Ocaml top, you must uncomment the following lines. I have commented because I am compiting the code and loading libraries create conflicts.

```ocaml 
(* 
#require "zarith" ;; 
#load "zarith.cma" ;;
*)
```

It implements all the function to encode instructions, and programs into natural numbers and the corresponding decoding. Using them, there a universal machine that give a number n, simulate the URM number n, on a given input.

<todo: description of the coding and decoding functions>

-----

## Inline interpreter 

Program *urmrepl* is an URM interpreter. You can compile your self by calling

```sh
> make clean
> make all
```

You call the interpreter by running

```
./urmrepl
```

To see the list of command open the file /help.me/ or call the command 

```
HELP;;
```

### Examples Technical Notes

* Programs defined directly by list of URM instruction (with or without line numbers). 

Keyword are PROG or Prog. Programs end with a ;;

```
PROG one: 
1: Z(1) 
2: S(1)
;;

Prog succ: 
S(1)
;;

Prog add: 
Z(3)
J(2,3,7)
S(1)
S(3)
J(1,1,2)
;;
```

* Print the code of a program (or all the program in the environment)

```
PRINT add
;;

Printall
;;
```

* Save a program in a file (e.g., test.txt)

```
Save add test
;;
```

Programs are automatically stored in standard form.
You can write our programs in a file (e.g., *text.txt*) and then 

* Load programs from disk into memory (LOAD or Load)

```
LOAD test 
;;
```

* You can define program by relocation (need a program to exist already)

```
PROG addr:
add[4,5 -> 3]
;;
```

* Compose programs

```
PROG onestill:
one ;
one 
;;
```

* Define programs by substitution f(g1,...,gk):n where n is the arity of the gi's

```
% comments
% one = Succ(Zero):1

PROG two:
succ(one):1
;;

Prog Three:
succ(two):1
;;

Prog two':
add(one,one):1 
;;
```


* Define programs by recursion: rec(f,g,n), where n is the arity of f (g has n+2 arity)

```
% Add(x,0) = x 
% Add(x,y+1) = Succ(Add(x,y))

that is:

// $h(x,0) = f(x)$
// $h(x,y+1) = g(x,y,h(x,y))$

thus:

// $h(x,0) = f(x) = id(x) = U^1_1(x)$
// $h(x, y+1) = g(x,y,z) = succ(z) = succ(U^3_3(x,y,z))$

Prog id:
T(1,1)
;;

Prog proj3:
T(3,1)
;;

Prog g:
succ(proj3)
;;

PROG add:
REC(id, g, 1)  
;; 
``` 

* Programs defined by minimization: min(f, n), where n+1 is f's arity.

```
% mu_y (f(x,y) == 0), f n+1 arity, the least y : f(x,z) > 0 forall z < y and f(x,y) = 0

PROGRAM testmu
Min (f == 0):n
;;
```

* Run the programm on a give input (also bound the # executions) 

```
RUN add (4, 5) 
;; 

// run for 20 steps
Runbounded  add (4, 5) 20
;; 
```

* Evaluate the program as a function on a given input

```
//(return the content of register R1)
EVAL add (4, 5) 
;; 
```