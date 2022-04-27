from absl import app
from absl import flags
from pyspark.sql import SparkSession
from pyspark.sql.functions import udf
from pyspark.sql.types import ArrayType, StringType


FLAGS = flags.FLAGS
flags.DEFINE_string("source", None, "The path to the source Parquet file")
flags.DEFINE_string("target", None, "The path to the destination CSV file")


def array_to_string(my_list):
    return '{' + ','.join([str(elem) for elem in my_list]) + '}'
array_to_string_udf = udf(array_to_string, StringType())


def main(args):
  del args

  source = FLAGS.source
  target = FLAGS.target

  spark = SparkSession.builder.appName("Parquet_to_CSV").getOrCreate()

  # Relevant: https://www.postgresql.org/message-id/fe7e6d7b-00f8-3de6-8eec-231932277179%40aklaver.com
  # Relevant: https://github.com/EDS-APHP/spark-etl/tree/master/spark-postgres
  # Relevant: https://stackoverflow.com/questions/34948296/using-pyspark-to-connect-to-postgresql
  # spark \
  #   .read.format("parquet") \
  #   .load(source) \
  #   .write.format("postgres") \
  #   .option("host","localhost") \
  #   .option("partitions", 4) \
  #   .option("table","theTable") \
  #   .option("user","postgres") \
  #   .option("database","hep_data") \
  #   .option("schema","hep_schema") \
  #   .loada

  array_columns = []
  df = spark.read.parquet(source)
  for field in df.schema.fields:
    if isinstance(field.dataType, ArrayType):
      array_columns.append(field.name)

  for col in array_columns: 
    new_name = col + '_'
    df = df.withColumnRenamed(col, new_name)
    df = df.withColumn(col, array_to_string_udf(df[new_name]))
    df = df.drop(new_name)

  df.write.option("header", "true").option("encoding", "UTF-8").csv(target)
  spark.stop()


if __name__ == '__main__':
  flags.mark_flag_as_required('source')
  flags.mark_flag_as_required('target')
  app.run(main)
