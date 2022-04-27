import argparse

import pyspark.sql

parser = argparse.ArgumentParser()
parser.add_argument('-i', '--input',  help='Input ROOT file (or path)')
parser.add_argument('-o', '--output', help='Output folder with Parquet file(s)')
parser.add_argument('-n', '--num-files', default=1,
                    help='Number of Parquet files')
parser.add_argument('-t', '--tree',      default='Events',
                    help='Name of tree to open')
args = parser.parse_args()

spark = pyspark.sql.SparkSession.builder \
    .config('spark.jars.packages', 'edu.vanderbilt.accre:laurelin:1.1.1') \
    .getOrCreate()
df = spark.read.format('root') \
               .option('tree', args.tree) \
               .load(args.input)
df.coalesce(args.num_files).write.parquet(args.output)
