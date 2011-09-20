SHELL=bash
INC_TEX_FILES:=$(wildcard *.inc.tex)
IMAGE_FILES:=$(wildcard images/*)
INTERMEDIATE_FILES:= *.ac[nr] *.alg *.gl[gos] *.idx *.ilg *.ind *.ist *.aux *.lof *.out *.toc *.log *.dvi *.4ct *.4tc *.haux *.hind *.htoc *.idv *.lg *.nlo *.nls *.tmp *.xref html/* 
TARGET_FILES:= main.ps.[0-9][0-9][0-9] main.ps.gz main.dvi main.pdf
DOCTYPE:=graphics
#DOCVERSION:=$(shell git show --format="%h" HEAD | awk 'NR==1{print $1}')
DOCVERSION:=$(shell git rev-parse --short --verify HEAD)
DOCVERSION_LONG:=$(shell git rev-parse --verify HEAD)
DOCDATE:=$(shell date "+%m/%Y")
DOCVERSION_DATE:=$(shell date -u --date="`git show --format='%ai' HEAD | sed -n '1p'`" "+%Y-%m-%dT%H:%M:%SZ")

.PHONY: dvi ps pdf vdvi vps vpdf fax html txt ftp distclean clean all

dvi: main.dvi
ps: main.ps.gz
pdf: main.pdf

distclean:	
	rm -f $(INTERMEDIATE_FILES)
	rm -f $(TARGET_FILES)

clean:
	rm -f $(INTERMEDIATE_FILES)
	rm -f main.dvi

main.dvi: clean main.tex $(INC_TEX_FILES) $(IMAGE_FILES)
	echo -e "$(DOCTYPE)\n$(DOCVERSION)\n$(DOCDATE)" | latex main.tex
	echo -e "$(DOCTYPE)\n$(DOCVERSION)\n$(DOCDATE)" | latex main.tex
	makeindex main.idx
	makeindex main.nlo -s nomencl.ist -o main.nls
	echo -e "$(DOCTYPE)\n$(DOCVERSION)\n$(DOCDATE)" | latex main.tex

main.ps.gz: dvi
	dvips -t a4 -o main.ps main.dvi
	gzip -f main.ps
	#rm -f $(INTERMEDIATE_FILES)

main.pdf: ps
	gunzip -f main.ps.gz
	ps2pdf main.ps main.pdf
	gzip -f main.ps
	rm -f main.ps

vdvi: dvi
	xdvi main.dvi&

vps: ps
	gunzip -f main.ps.gz
	gv main.ps
	gzip -f main.ps
	rm -f main.ps

vpdf: pdf
	xpdf main.pdf&

fax: main.ps.gz
	gunzip -f main.ps.gz
	fax make main.ps
	gzip -f main.ps
	rm -f main.ps

html: dvi
	echo "$(DOCTYPE) $(DOCVERSION) $(DOCDATE)" | ./htlatex main.tex "main,graphics-130" "" "-dhtml/"
	cp html/* ../html
	mv ../html/main.html ../html/index.html

txt: DOCTYPE:=text
txt: dvi
	echo "$(DOCTYPE) $(DOCVERSION) $(DOCDATE)" | ./htlatex main.tex "main,graphics-130" "" "-dhtml/"
	links -dump  html/main.html > main.txt

all: pdf html txt

ftp: all
	cp main.txt ../txt/$(DOCVERSION_LONG).txt
	(cd ../html ; for i in *; do ncftpput -m -f ~/.ncftp/prosite.dat -C $$i /htdocs/documents/ecsa/$$i ; done)
	ncftpput -m -f ~/.ncftp/prosite.dat -C main.pdf /htdocs/documents/ecsa/ecsa.pdf
	ncftpput -m -f ~/.ncftp/prosite.dat -C main.txt /htdocs/documents/ecsa/ecsa.txt
