SCRIPTPATH:=$(dir $(realpath $(lastword $(MAKEFILE_LIST))))

RUN_DIRS=$(sort $(patsubst %/,%,$(dir $(wildcard run_*/run.log))))
JOB_FILES=$(RUN_DIRS:%=%/job.json)
RESULT_FILES=$(RUN_DIRS:%=%/result.json)

SUMMARIZE_RUN=$(SCRIPTPATH)/summarize_run.py

.DELETE_ON_ERROR:
.SECONDARY: $(JOB_FILES) $(RESULT_FILES)

all: result.json

result.json: $(RESULT_FILES)
	cat $^ > $@

%/result.json: %/job.json %/config.json
	$(SUMMARIZE_RUN) $(dir $<) > $@

%/job.json: %/run.log
	bq show --format prettyjson -j \
		$$(grep "Job ID:" $^ | head -n1 | sed 's/.*Job ID: \(.*\)$$/\1/') > $@

clean:
	rm -f $(JOB_FILES) $(RESULT_FILES) result.json
