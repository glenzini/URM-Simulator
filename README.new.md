# URM Interpreter

A command-line interpreter for Unlimited Register Machine (URM) programs, written in OCaml.

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

You'll see a `#` prompt where you can enter URM commands.

## Basic Usage

The interpreter supports various commands (all commands must end with `;;`):

- **Define a program:**
  ```
  PROG add: S(1); T(1,2);;
  ```

- **Run a program:**
  ```
  RUN add(5);;
  ```

- **Evaluate a program:**
  ```
  EVAL add(3);;
  ```

- **Print a program:**
  ```
  PRINT add;;
  ```

- **Show all programs:**
  ```
  PRINTALL;;
  ```

- **Get help:**
  ```
  HELP;;
  ```

- **Exit the interpreter:**
  ```
  EXIT;;
  ```

## Features

- ✅ Readline support (arrow keys for editing, command history with ↑/↓)
- ✅ Load and save programs from/to files
- ✅ Program composition and manipulation
- ✅ Encoding and decoding of programs
- ✅ Bounded execution

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

Gabriele LENZINI
SnT/University of Luxembourg