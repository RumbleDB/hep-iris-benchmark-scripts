SCRIPTPATH:=$(dir $(realpath $(lastword $(MAKEFILE_LIST))))

# Setup
TEXFILE=plots.tex
PDFFILE=plots.pdf

DEPENDENCIES=$(wildcard *.tex) $(wildcard *.pdf) $(wildcard *.bib)

DOCKERIMAGE=texlive/texlive:TL2020-historic
DOCKERCMD=docker run --rm -it -v$(SCRIPTPATH):$(SCRIPTPATH) --workdir $(SCRIPTPATH) $(DOCKERIMAGE)
LATEXMK=$(DOCKERCMD) latexmk -pdf $(LATEXMKFLAGS) -outdir=build --interaction=nonstopmode --halt-on-error
RM=$(DOCKERCMD) rm

# Targets
all: $(PDFFILE)

$(PDFFILE): $(TEXFILE) $(DEPENDENCIES)
	${LATEXMK} $<
	cat build/$(TEXFILE:%.tex=%).pdf > $@

clean:
	${LATEXMK} -C
	$(RM) $(PDFFILE)

clean-temps:
	${LATEXMK} -c
