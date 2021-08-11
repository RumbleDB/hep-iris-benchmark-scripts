import argparse
import glob
import json
import os

BLOCK_SIZE_BYTES = 8 * 2 ** 10  # 8kB


parser = argparse.ArgumentParser(description='Postprocess experiments for PostgreSQL.')
parser.add_argument('exp_dir', type=str, help='The path to the experiment directory.')
parser.add_argument("--log_filename", type=str, default="query_stats.log",
                    help="The standard name of the file to which the query stats are dumped.")
parser.add_argument("--summary_filename", type=str, default="summary.jsonl",
                    help="The name of the file to which the summary in JSONL format is dumped.")


def main(exp_dir, log_filename, summary_filename):
  # Delete previous summary file if exists
  summary_file = os.path.join(exp_dir, summary_filename)
  try:
    os.remove(summary_file)
  except OSError:
      pass

  # Post-process experiment data and gather into jsonl file
  files = glob.glob(exp_dir + f'/**/{log_filename}', recursive=True)
  for file in files:
    with open(file, "r") as f:
      res = json.load(f)

    # Find out the number of bytes read and written for this query
    res["bytes_read"] = (res["shared_blks_hit"] + res["shared_blks_read"] \
      + res["local_blks_hit"] + res["local_blks_read"] + res["temp_blks_read"]) \
      * BLOCK_SIZE_BYTES
    res["bytes_written"] = (res["shared_blks_written"] 
      + res["local_blks_written"] + res["temp_blks_written"]) * BLOCK_SIZE_BYTES

    # Write the summary to the jsonl file
    with open(summary_file, "a") as f:
      json.dump(res, f)
      f.write('\n')


if __name__ == '__main__':
  args = parser.parse_args()
  main(args.exp_dir, args.log_filename, args.summary_filename)
