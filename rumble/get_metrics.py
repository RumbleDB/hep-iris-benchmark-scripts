import argparse
import json
import os
import requests


parser = argparse.ArgumentParser(description='Gather the Spark metrics.')
parser.add_argument("app_id", help="The id of the Spark application", type=str)
parser.add_argument("entry_count", help="The number of job entries", type=int)
parser.add_argument("sql_entry_count", 
					help="The number of sql execution entries", type=int)
parser.add_argument("experiment_dir", help="The experiment directory", type=str)


def main(args):
	base_url = f"http://localhost:4040/api/v1/applications/{args.app_id}"

	# Get the jobs
	jobs = sorted(json.loads(requests.get(f"{base_url}/jobs").text), 
		key=lambda job: job["jobId"])[-args.entry_count:] \
		if args.entry_count != 0 else []

	# Get the stages
	valid_stage_ids = set([sid for job in jobs for sid in job['stageIds']])
	stages = [json.loads(requests.get(f"{base_url}/stages/{sid}").text)[0] 
		for sid in valid_stage_ids]

	# Get the SQL executions
	sql_jobs = sorted(json.loads(
		requests.get(f"{base_url}/sql?length=100000000").text), 
		key=lambda job: job["id"])[-args.sql_entry_count:] \
		if args.sql_entry_count != 0 else []

	# Write the stats
	for i in [("jobs.json", jobs), ("stages.json", stages), 
		("sql_jobs.json", sql_jobs)]:
		with open(os.path.join(args.experiment_dir, i[0]), "w") as f:
			json.dump(i[1], f, indent=2)

if __name__ == '__main__':
	main(parser.parse_args())
