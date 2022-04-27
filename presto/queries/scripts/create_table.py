#!/usr/bin/env python3

import argparse
from os.path import dirname, join
from socket import getfqdn

from presto import PrestoCliProxy

parser = argparse.ArgumentParser()
parser.add_argument('-P', '--presto-cmd', action='store',
                    default=join(dirname(__file__), 'presto.sh'),
                    help='Path to the script that runs the Presto CLI.')
parser.add_argument('-S', '--presto-server', action='store',
                    default=getfqdn() + ':8080',
                    help='URL as <host>:<port> of the Presto server.')
parser.add_argument('-C', '--presto-catalogue', action='store', default='hive',
                    help='Default catalogue to use in Presto.')
parser.add_argument('--presto-schema', action='store', default='default',
                    help='Default schema to use in Presto.')
parser.add_argument('-T', '--table-name',
                    help='Name of the table that should be created.')
parser.add_argument('-L', '--location',
                    help='Location of the external files (on HDFS or S3).')
parser.add_argument('-V', '--view-name',
                    help='Name of the view that should be created.')
parser.add_argument('--variant', default='native',
                    help='Variant of the tables to create (native or shredded).')
args = parser.parse_args()

# Assemble paths to SQL files
base_dir = dirname(__file__)
create_table_file = join(base_dir, 'create_table_{}.sql'.format(args.variant))
create_view_file = join(base_dir, 'create_view_{}.sql'.format(args.variant))

# Create Presto client
presto = PrestoCliProxy(args.presto_cmd, args.presto_server,
                        args.presto_catalogue, args.presto_schema)

# Delete table if exists
presto.run('DROP TABLE IF EXISTS {};'.format(args.table_name))

# Create new table
with open(create_table_file, 'r') as f:
    query = f.read()
query = query.format(
    table_name=args.table_name,
    location=args.location,
)
presto.run(query)

# Create view
if args.variant in ['shredded']:
    # Create or replace view
    with open(create_view_file, 'r') as f:
        query = f.read()
    query = query.format(
        table_name=args.table_name,
        view_name=args.view_name,
    )
    presto.run(query)
