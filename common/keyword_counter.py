import argparse
import json
import pandas
from pathlib import Path
import re


# Set up the input parameters
parser = argparse.ArgumentParser(
    description='Get the soft metrics for the JSONiq queries.',
)
parser.add_argument('path', help='Path to the queries.')
parser.add_argument('--extension', type=str, default="jq",
                    help='The extension of the query files')
parser.add_argument('--csv', action="store_true")
args = parser.parse_args()


# The dictionary which stores the counts
if args.extension == "jq":
  dict_counter = {
    "FUNCTION": 0,
    "LET": 0,
    "FOR": 0,
    "IF": 0,
    "GROUP": 0,
    "ORDER": 0,
    "WHERE": 0,
    "COUNT": 0,
    "EXISTS": 0,
    "EMPTY": 0
  }
else:
  dict_counter = {
    "SELECT": 0,
    "CAST": 0,
    "CASE": 0,
    "WHEN": 0,
    "WHERE": 0,
    "GROUP": 0,
    "COUNT": 0,
    "ORDER": 0,
    "JOIN": 0,
    "CARDINALITY": 0,
    "FILTER": 0,
    "WITH": 0,
    "AND": 0,
    "HAVING": 0,
    "DROP": 0,
    "CREATE": 0,
    "COALESCE": 0,
    "TRANSFORM": 0,
    "UNNEST": 0,
    "FUNCTION": 0,
    "LIMIT": 0,
    "EXISTS": 0,
    "UNION": 0,
    "MAX_BY": 0,
    "MIN_BY": 0,
    "ARRAY_MAX": 0,
    "SUM": 0 
  }


# Parse a query
def eval_query(path):
  metrics = {
    "type": args.extension,
    "name": str(path),
    "lines": 0,
    "characters": 0,
    "unique_clauses": 0,
    "total_clauses": 0,
    "tokens": dict_counter.copy()
  }

  with open(path, "r") as f:
    for line in f.readlines():
      if line.strip() != "":
        metrics["lines"] += 1

        tokens = line.split()
        for token in tokens:
          metrics["characters"] += len(token)
          split_tokens = re.split("[^A-Z]", token.upper())
          for split_token in split_tokens:
            if split_token in metrics["tokens"]:
              metrics["tokens"][split_token] += 1

  metrics["unique_clauses"] = sum([1 for _, v in metrics["tokens"].items() if v > 0])
  metrics["total_clauses"] = sum(metrics["tokens"].values())

  return metrics


def main():
  summary = []
  for path in Path(args.path).rglob(f'*.{args.extension}'):
    summary.append(eval_query(path))

  with open("summary.json", "w") as f:
    for j in summary:
      json.dump(j, f)
      f.write("\n")

  if args.csv:
    pandas.json_normalize(summary).to_csv("summary.csv")


if __name__ == '__main__':
  main()