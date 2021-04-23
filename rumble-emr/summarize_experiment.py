#!/usr/bin/env python3

import argparse
from datetime import datetime
import json
import os
import sys

CONFIG = "config.json"
JOBS = "jobs.json"
STAGES = "stages.json"
SQL_JOBS = "sql_jobs.json"

parser = argparse.ArgumentParser(description='Summarize the Rumble experiment.')
parser.add_argument("experiment_dir", help="The experiment directory", type=str)

def aggregate_run(path, save_file_name="metrics.json"):
	# Read all the statistics dumps
	with open(os.path.join(path, CONFIG), "r") as f:
		summary = json.load(f)

	with open(os.path.join(path, JOBS), "r") as f:
		jobs = json.load(f)

	with open(os.path.join(path, STAGES), "r") as f:
		stages = json.load(f)
	
	# with open(os.path.join(path, SQL_JOBS), "r") as f:
	# 	sql_jobs = json.load(f)

	# Get the elapsed time
	start_time = min([datetime.strptime(job["submissionTime"], 
		"%Y-%m-%dT%H:%M:%S.%f%Z").timestamp() for job in jobs])
	end_time = max([datetime.strptime(job["completionTime"], 
		"%Y-%m-%dT%H:%M:%S.%f%Z").timestamp() for job in jobs])
	summary["runtime"] = end_time - start_time

	# Get the stage metrics
	metrics = [
		"executorDeserializeTime", 
		"executorDeserializeCpuTime",
		"executorRunTime",
		"executorCpuTime",
		"inputBytes",
		"inputRecords",
		"outputBytes",
		"outputRecords"
	]

	deep_metrics = [
		"bytesRead",
		"recordsRead",
		"bytesWritten",
		"recordsWritten",
		"maxInputRecords",
		"maxInputRecordsBytes"
	]

	for metric in metrics + deep_metrics:
		summary[metric] = 0

	for stage in stages:
		for metric in metrics:
			summary[metric] += stage[metric]

		if summary["maxInputRecords"] < stage["inputRecords"] or \
			(summary["maxInputRecords"] == stage["inputRecords"] and 
			summary["maxInputRecordsBytes"] < stage["inputBytes"]):
			summary["maxInputRecords"] = stage["inputRecords"]
			summary["maxInputRecordsBytes"] = stage["inputBytes"]

		for _, task in stage["tasks"].items():
			summary["bytesRead"] += task.get("taskMetrics", {}).get("inputMetrics", {}).get("bytesRead", 0)
			summary["recordsRead"] += task.get("taskMetrics", {}).get("inputMetrics", {}).get("recordsRead", 0)
			summary["bytesWritten"] += task.get("taskMetrics", {}).get("outputMetrics", {}).get("bytesWritten", 0)
			summary["recordsWritten"] += task.get("taskMetrics", {}).get("outputMetrics", {}).get("recordsWritten", 0)

	# Write and return 
	with open(os.path.join(path, save_file_name), "w") as f:
		json.dump(summary, f)
		f.write("\n")

	return summary


def main(args):
	summary = []
	top_dir = args.experiment_dir

	for subdir in [os.path.join(top_dir, o) for o in os.listdir(top_dir) 
		if os.path.isdir(os.path.join(top_dir, o))]:
			try:
				summary.append(aggregate_run(subdir))
			except Exception as e:
				print(f"Encountered an error at {subdir}", file=sys.stderr)
				print(f" > Error: {e}", file=sys.stderr)

	with open(os.path.join(top_dir, "summary.json"), "w") as f:
		for j in summary:
			json.dump(j, f)
			f.write("\n")


if __name__ == '__main__':
	main(parser.parse_args())
