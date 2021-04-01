SCRIPTPATH:=$(dir $(realpath $(lastword $(MAKEFILE_LIST))))

RUN_DIRS=$(sort $(patsubst %/,%,$(dir $(wildcard run_*/run.log))))
QUERY_FILES=$(RUN_DIRS:%=%/query.json)
RESULT_FILES=$(RUN_DIRS:%=%/result.json)

SUMMARIZE_RUN=$(SCRIPTPATH)/summarize_run.py

.DELETE_ON_ERROR:
.SECONDARY: $(QUERY_FILES) $(RESULT_FILES)

all: result.json

result.json: $(RESULT_FILES)
	cat $^ > $@

%/result.json: %/query.json %/config.json
	$(SUMMARIZE_RUN) $(dir $<) > $@

%/query.json: %/run.log
	(aws athena get-query-execution --query-execution-id \
		$$(grep "Query ID:" $^ | head -n1 | sed 's/.*Query ID: \(.*\)$$/\1/') || \
	 echo "{}") > $@

clean:
	rm -f $(QUERY_FILES) $(RESULT_FILES)
