SCRIPTPATH:=$(dir $(realpath $(lastword $(MAKEFILE_LIST))))

RUN_DIRS=$(sort $(patsubst %/,%,$(dir $(wildcard run_*/run.log))))
RESULT_FILES=$(RUN_DIRS:%=%/result.json)

SUMMARIZE_RUN=$(SCRIPTPATH)/summarize_run.py

.DELETE_ON_ERROR:
.SECONDARY: $(RESULT_FILES)

all: result.json

result.json: $(RESULT_FILES)
	cat $^ > $@

%/result.json: %/query.json %/config.json
	$(SUMMARIZE_RUN) $(dir $<) > $@

clean:
	rm -f $(RESULT_FILES)
