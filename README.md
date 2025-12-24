# URM Interpreter
vv 1.0
August 2025

A command-line interpreter for Unlimited Register Machine (URM) programs, written in OCaml.

This implementation follows the theory described in Nigel Cutland's "Computability Theory: An introduction to recursive function theory" [1], providing both an OCaml library for URM computation and an interactive command-line interpreter.

## Features

- ✅ Full URM instruction set (Zero, Succ, Transfer, Jump)
- ✅ Program composition operators (substitution, recursion, minimalization)
- ✅ Encoding and decoding of URM programs into natural numbers
- ✅ Universal URM machine implementation
- ✅ Interactive REPL with readline support (arrow keys for editing, command history with ↑/↓)
- ✅ Load and save programs from/to files
- ✅ Bounded execution for non-terminating programs

## Requirements

- **OCaml** (version 4.08 or later)
- **opam** (OCaml package manager)
- **ocamlfind**
- **zarith** library: `opam install zarith`
- **ocamline** library: `opam install ocamline`

## Installation

1. Clone this repository:
```bash
git clone <your-repo-url>
cd <repository-name>
```

2. Install dependencies:
```bash
opam install zarith ocamline
```

## Compilation

To compile the interpreter:

```bash
make
```

This will:
- Generate the lexer and parser from `URMLEX.mll` and `URMParser.mly`
- Compile all OCaml modules
- Create the `urm` executable

To clean all compiled files:

```bash
make clean
```

## Running the Interpreter

Start the interpreter:

```bash
./urm
```

You'll see a `#` prompt where you can enter URM commands. All commands must end with `;;`

To see the list of available commands:
```
HELP;;
```

To exit the interpreter:
```
EXIT;;
```

## Quick Start Examples

### Define a simple program
```
PROG succ: S(1);;
```

### Define a program with multiple instructions
```
PROG add: 
Z(3)
J(2,3,7)
S(1)
S(3)
J(1,1,2)
;;
```

### Run a program
```
RUN add(4, 5);;
```

### Evaluate a program (returns R1 only)
```
EVAL add(4, 5);;
```

### Print a program's code
```
PRINT add;;
```

### Show all programs in memory
```
PRINTALL;;
```
---

# Detailed Documentation

This code has been written as part of the course Foundation of Computing, of the Master in Computer Science (MICS) of the University of Luxembourg.

## URM Theory and Implementation

This code implements URM machines as described in [1]. It is organized in two parts:

1. **OCaml implementation of URM**: Following the theory, it implements all URM instructions, operators to compose URMs (substitution, recursion, minimalization), and functions to encode/decode URMs into natural numbers, leading to a universal URM machine implementation.

2. **Command-line interpreter**: Refers to a simple language for writing URM programs, composing URMs, encoding/decoding URMs, and auxiliary operators to print, store, load, run, and evaluate URM programs.

## URM Instructions

After starting the interpreter, you can write URM programs using these instructions:

```
Z(n)        - Zero: Set register Rn to 0
S(n)        - Successor: Increment register Rn by 1
T(n,m)      - Transfer: Copy the value from Rn to Rm
J(n,m,q)    - Jump: If Rn = Rm, jump to instruction q
```

where `n`, `m`, and `q` are positive natural numbers.

### Program Definition

Programs are defined with the `PROG` keyword:

```
PROG <program_name>: 
<URM instructions>
;;
```

Instructions can optionally have line numbers:

```
PROG one: 
1: Z(1) 
2: S(1)
;;
```

Or without line numbers:

```
Prog succ: 
S(1)
;;
```

## Running Programs

There are three ways to execute programs:

### 1. EVAL - Evaluate and return R1
```
EVAL <program_name>(R1, R2, ..., Rn);;
```
Returns only the value of register R1 (the output).

### 2. RUN - Execute and show all registers
```
RUN <program_name>(R1, R2, ..., Rn);;
```
Returns the final configuration of all registers used by the computation.

### 3. RUNBOUND - Bounded execution
```
RUNBOUND <program_name>(R1, R2, ..., Rn) <max_steps>;;
```
Executes for at most `max_steps` and returns register configuration. Useful for non-terminating programs.

Example:
```
RUNBOUND add(4, 5) 20;;
```

## Program Composition

The interpreter supports several operators from partial recursive function theory:

### 1. Concatenation
Concatenate two programs sequentially:

```
PROG combined:
prog1;
prog2
;;
```

### 2. Relocation
Relocate a program's inputs and output to different registers:

```
PROG relocated:
add[4,5 -> 3]
;;
```

This takes inputs from R4 and R5, and puts the output in R3.

Syntax: `<program>[input_list -> output_register]`

### 3. Substitution
Compose f(g1,...,gk) where f is k-ary and each gi is n-ary:

```
PROG two:
succ(one):1
;;
```

The `:n` specifies the arity of the g functions.

Example building addition from basic functions:
```
% one = Succ(Zero):1

PROG two:
succ(one):1
;;

PROG three:
succ(two):1
;;

PROG two_alt:
add(one, one):1
;;
```

### 4. Recursion
Define programs by primitive recursion: `REC(f, g):n`

Where:
- f is n-ary (base case)
- g is (n+2)-ary (recursive case)
- Result is (n+1)-ary

Example - Addition defined by recursion:
```
% Add(x,0) = x 
% Add(x,y+1) = Succ(Add(x,y))

% Base: h(x,0) = f(x) = id(x)
PROG id:
T(1,1)
;;

% Recursive: h(x,y+1) = g(x,y,h(x,y)) = succ(h(x,y))
PROG proj3:
T(3,1)
;;

PROG g:
succ(proj3):1
;;

PROG add:
REC(id, g):1
;; 
```

### 5. Minimalization
Define programs by minimalization (μ-operator): `MIN(f == 0):n`

Searches for the minimal y such that f(x,y) = 0:

```
PROG search:
MIN(test_function == 0):n
;;
```

Where f has arity n+1.

## File Operations

### Save a program to disk
```
SAVE <program_name> <filename>;;
```

Example:
```
SAVE add myprogram;;
```
This creates `myprogram.txt`

### Load programs from disk
```
LOAD <filename>;;
```

Example:
```
LOAD myprogram;;
```
This loads from `myprogram.txt`

## Encoding and Decoding

### Encode a program to a number
```
ENCODE <program_name>;;
```

This returns the Gödel number (index) of the program.

### Decode a number to a program
```
DECODE #<number>;;
```

Example:
```
DECODE #12345;;
```

This displays the program encoded by that number.

### Simulate an encoded program
```
SIMULATE #<number>(inputs);;
```

Example:
```
SIMULATE #12345(4, 5);;
```

This decodes and runs the program with the given inputs.

## Using as an OCaml Library

You can also use the URM implementation directly in OCaml code:

### Load the library
```ocaml
#use "URM_machine.ml";;
#use "URM_counting_programs.ml";;
```

### Define and run programs in OCaml
```ocaml
let add_program = 
[|
  Zero(3);
  Jump(2,3,7);
  Succ(1);
  Succ(3);
  Jump(1,1,2)
|];;

(* Print the program *)
print_program add_program;;

(* Evaluate: returns R1 *)
eval add_program [4; 5];;

(* Run: returns all registers *)
run add_program [4; 5];;

(* Bounded run: execute for n steps *)
runbound add_program [4; 5] 100;;
```

### Compose programs in OCaml
```ocaml
(* Concatenation *)
let combined = concatenate prog1 prog2;;

(* Relocation *)
let relocated = relocate add_program [4; 5] 3;;

(* Substitution *)
let composed = compose f [g1; g2; g3] 2;;

(* Recursion *)
let recursive_add = recursion id_prog g_prog 1;;

(* Minimalization *)
let search = minimalization test_prog 2;;
```

## Comments in Programs

Use `%` or `//` for comments:

```
% This is a comment
// This is also a comment

PROG example:
S(1)  % Increment R1
;;
```

## References

[1] Nigel Cutland, "Computability Theory: An introduction to recursive function theory", Cambridge University Press, 1980. ISBN-10: 0521294657, ISBN-13: 978-0521294652

## License

MIT License

Copyright (c) 2025 glenzini

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Author

Prof. Gabriele LENZINI  
SnT/University of Luxembourg
gabriele.lenzini@uni.lu
