import argparse

import pyspark.sql
from pyspark.sql.functions import *
from pyspark.sql import types

parser = argparse.ArgumentParser()
parser.add_argument('-i', '--input',  help='Input Parquet file (or path)')
parser.add_argument('-o', '--output', help='Output folder with Parquet file(s)')
parser.add_argument('-n', '--num-files', default=1,
                    help='Number of Parquet files')
args = parser.parse_args()

spark = pyspark.sql.SparkSession.builder.getOrCreate()
df = spark.read.load(args.input)

# Assign fields in input schema to fields in output schema
flat_struct_fields = {}
list_struct_fields = {}
list_size_fields = {}
atomic_fields = {}

for field in df.schema:
    # Field that stores the length of a list, e.g., nJet
    if isinstance(field.dataType, types.LongType) and \
        field.name.startswith('n'):
        struct_name = field.name[1:]
        assert struct_name not in list_size_fields
        list_size_fields[struct_name] = field
    # Field that is part of a struct
    elif '_' in field.name:
        struct_name = field.name.split('_')[0]
        # The struct is in a nested list, e.g., Muon_pt
        if isinstance(field.dataType, types.ArrayType):
            if struct_name not in list_struct_fields:
                list_struct_fields[struct_name] = []
            list_struct_fields[struct_name].append(field)
        # The struct is flat, e.g., MET_sumet
        else:
            if struct_name not in flat_struct_fields:
                flat_struct_fields[struct_name] = []
            flat_struct_fields[struct_name].append(field)
    # An atomic field, e.g., event
    else:
        assert isinstance(field.dataType, types.AtomicType)
        atomic_fields[field.name] = field

assert len(list_struct_fields) == len(list_size_fields)
assert len(set(list_struct_fields.keys()) &
           set(flat_struct_fields.keys())) == 0
assert len(set(list_struct_fields.keys()) &
           set(atomic_fields.keys())) == 0
assert len(set(flat_struct_fields.keys()) &
           set(atomic_fields.keys())) == 0

# Assemble list of expressions that compute the new fields
expressions = []

# Leave atomic fields as is
for field_name in atomic_fields:
    expressions.append(field_name)

# Create new struct with sub fields
for field_name in flat_struct_fields:
    sub_field_expr = []
    for field in flat_struct_fields[field_name]:
        sub_field_name = '_'.join(field.name.split('_')[1:])
        sub_field_expr.append(col(field.name).alias(sub_field_name))
    expressions.append(struct(sub_field_expr).alias(field_name))

# Create new list of structs with sub fields
for field_name in list_struct_fields:
    sub_field_expr = []
    sub_fields = []
    for field in list_struct_fields[field_name]:
        sub_field_name = '_'.join(field.name.split('_')[1:])
        field_type = field.dataType.elementType
        sub_field_expr.append(col(field.name))
        sub_fields.append(types.StructField(sub_field_name, field_type))
    field_type = types.ArrayType(types.StructType(sub_fields))
    expressions.append(
        arrays_zip(*sub_field_expr).cast(field_type).alias(field_name))

# Write to output file with computed expressions
df.select(*expressions).coalesce(args.num_files).write.parquet(args.output)
