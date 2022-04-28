SCRIPTPATH:=$(dir $(realpath $(lastword $(MAKEFILE_LIST))))

RUN_DIRS=$(sort $(patsubst %/,%,$(dir $(wildcard run_*/run.log))))
RESULT_FILES=$(RUN_DIRS:%=%/result.json)
ANALYSIS_FILES=$(RUN_DIRS:%=%/analysis.json)
PARSE:=../../parse.sh

.DELETE_ON_ERROR:
.SECONDARY: $(RESULT_FILES) $(ANALYSIS_FILES)

all: result.jsonl

result.jsonl: $(RESULT_FILES)
	cat $^ > $@

%/result.json: %/config.json %/analysis.json
	jq -cs ".[0] * .[1]" $^ > $@

%/analysis.json: %/run.log #$(PARSE)
	cat $< | $(PARSE) > $@

clean:
	rm -f $(RESULT_FILES) $(ANALYSIS_FILES) result.jsonl
