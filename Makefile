OCAMLC=ocamlc
OCAMLOPT=ocamlopt
PACKAGES=-package zarith -package ocamline
OCAML_FLAGS=-I +zarith
OCAML_LIBS=zarith.cma ocamline.cma
LEX=ocamllex
YACC=ocamlyacc

OBJS = \
  URM_types.cmo \
  URM_machine.cmo \
  URM_counting_programs.cmo \
  URMParser.cmo \
  URMLEX.cmo \
  URM_input_output.cmo \
  URMinterpret.cmo \
  URMREPL.cmo

# build all (= the urm interpreter)
all: urm

# Generate parser from .mly
# $(YACC) -v URMParser.mly 
URMParser.ml URMParser.mli: URMParser.mly
	$(YACC) -v URMParser.mly

# Generate lexer from .mll
# $(LEX) -v URMLEX.mll 
URMLEX.ml: URMLEX.mll URMParser.ml
	$(LEX) URMLEX.mll

# Compile .mli interface 
URMParser.cmi: URMParser.mli URM_types.cmi
	$(OCAMLC) -c URMParser.mli

# Compile lexer, making sure parser interface is available
URMLEX.cmo: URMLEX.ml URMParser.cmi URM_types.cmi
	$(OCAMLC) -c URMLEX.ml

# Compile .ml files (automatically compiles corresponding .mli first if it exists)

# Compile .ml files
%.cmo: %.ml
	@if test -f "$*.mli"; then ocamlfind $(OCAMLC) $(PACKAGES) -c $*.mli; fi
	ocamlfind $(OCAMLC) $(PACKAGES) -c $<

# Build final executable
urm: $(OBJS)
	ocamlfind $(OCAMLC) $(PACKAGES) -linkpkg -o urm $(OBJS)

# Clean all build artifacts
clean:
	rm -f *.cmo *.cmi *.o *.out urml URMParser.ml URMParser.mli URMParser.output URMLEX.ml
