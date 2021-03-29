import argparse
import json
import os
import requests


parser = argparse.ArgumentParser(description='Gather the Spark metrics.')
parser.add_argument("app_id", help="The id of the Spark application", type=str)
parser.add_argument("entry_count", help="The number of job entries", type=int)
parser.add_argument("sql_entry_count", help="The number of sql execution entries", type=int)
parser.add_argument("experiment_dir", help="The experiment directory", type=str)
parser.add_argument("-p", "--port", help="The port offset to use", type=int, default=4040)



def main(args):
	jsons = []
	base_url = f"http://localhost:{args.port}/api/v1/applications/{args.app_id}"

	# Get the jobs
	try: 
		jobs = sorted(json.loads(requests.get(f"{base_url}/jobs").text), 
			key=lambda job: job["jobId"])[-args.entry_count:] \
			if args.entry_count != 0 else []
		jsons.append(("jobs.json", jobs))
	except Exception as e:
		print("(JOBS) Error: ", e)

	# Get the stages
	try:
		valid_stage_ids = set([sid for job in jobs for sid in job['stageIds']])
		stages = [json.loads(requests.get(f"{base_url}/stages/{sid}").text)[0] 
			for sid in valid_stage_ids]
		jsons.append(("stages.json", stages))
	except Exception as e:
		print("(STAGES) Error: ", e)

	# Get the SQL executions
	try: 
		sql_jobs = sorted(json.loads(
			requests.get(f"{base_url}/sql?length=100000000").text), 
			key=lambda job: job["id"])[-args.sql_entry_count:] \
			if args.sql_entry_count != 0 else []
		jsons.append(("sql_jobs.json", sql_jobs))
	except Exception as e:
		print("(SQL_JOBS) Error: ", e)

	# Write the stats
	for i in jsons:
		with open(os.path.join(args.experiment_dir, i[0]), "w") as f:
			json.dump(i[1], f, indent=2)

if __name__ == '__main__':
	main(parser.parse_args())
