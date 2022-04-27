#!/usr/bin/env python3

import argparse
from os.path import dirname, join

import pyathena

parser = argparse.ArgumentParser()
parser.add_argument('-S', '--staging-dir',
                    help='Directory on S3 used as output location by Athena.')
parser.add_argument('-D', '--database',
                    help='Name of the schema ("database") where the table '
                         'should be created.')
parser.add_argument('-T', '--table-name',
                    help='Name of the table that should be created.')
parser.add_argument('-L', '--location',
                    help='Location of the external files (on S3).')
parser.add_argument('-V', '--view-name',
                    help='Name of the view that should be created.')
parser.add_argument('--variant', default='native',
                    help='Variant of the tables to create (native or shredded).')
args = parser.parse_args()

# Assemble paths to SQL files
base_dir = dirname(__file__)
create_table_file = join(base_dir, 'create_table_{}.sql'.format(args.variant))
create_view_file = join(base_dir, 'create_view_{}.sql'.format(args.variant))

# Set up connection to Athena
connection = pyathena.connect(
    s3_staging_dir=args.staging_dir,
    schema_name=args.database,
)
cursor = connection.cursor()

# Delete table if exists
cursor.execute('DROP TABLE IF EXISTS `{}`'.format(args.table_name))

# Create new table
with open(create_table_file, 'r') as f:
    query = f.read()
query = query.format(
    tablename=args.table_name,
    location=args.location,
)
cursor.execute(query)

# Create view
if args.variant in ['shredded']:
    # Delete view if exists
    cursor.execute('DROP VIEW IF EXISTS {}'.format(args.view_name))

    # Create new view
    with open(create_view_file, 'r') as f:
        query = f.read()
    query = query.format(
        table_name=args.table_name,
        view_name=args.view_name,
    )
    cursor.execute(query)
