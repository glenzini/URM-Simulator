OCAMLC=ocamlc
OCAMLOPT=ocamlopt
PACKAGES=-package zarith -package ocamline
PACKAGES_SERVER=-package zarith,dream,yojson -thread
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

# Server object list (no URMREPL — replaced by URM_server)
OBJS_SERVER = \
  URM_types.cmo \
  URM_machine.cmo \
  URM_counting_programs.cmo \
  URMParser.cmo \
  URMLEX.cmo \
  URM_input_output.cmo \
  URMinterpret.cmo \
  URM_server.cmo

# build all (= the urm interpreter + the web server)
all: urm urm_server

# Convenience: build + run the web server
server: urm_server
	./_build/default/URM_server.exe

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

# Build final executable (CLI interpreter)
urm: $(OBJS)
	ocamlfind $(OCAMLC) $(PACKAGES) -linkpkg -o urm $(OBJS)

# Compile server module (needs dream + yojson, no ocamline)
URM_server.cmo: URM_server.ml URMinterpret.cmo
	ocamlfind $(OCAMLC) $(PACKAGES_SERVER) -c URM_server.ml

# Build web server executable (via dune — resolves Dream's transitive deps)
urm_server:
	dune build && cp _build/default/URM_server.exe urm_server

# Clean all build artifacts
clean:
	rm -f *.cmo *.cmi *.o *.out urm urm_server URMParser.ml URMParser.mli URMParser.output URMLEX.ml
