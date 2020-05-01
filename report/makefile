# Define the tex compiler to use
TEX = pdflatex

# Define inuput soruce
SRCS = edge.tex

# Define output title
OUT = FeatureDetection_VHDL


.PHONY: depend clean


# Generate the PDF report. Run twice to get the references straight
pdf: clean $(SRCS)
	$(TEX) -halt-on-error -jobname=$(OUT) $(SRCS) && $(TEX) -halt-on-error -jobname=$(OUT) $(SRCS) && make clean


# Clean the directory of the logging files
clean:
	rm -f *.aux *.log


depend: $(SRCS)
	makedepend $^
