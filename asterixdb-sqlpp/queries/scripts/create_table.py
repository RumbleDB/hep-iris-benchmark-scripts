#!/usr/bin/env python3

import argparse
from os.path import dirname, join
from socket import getfqdn

from argparse_logging import add_log_level_argument

from asterixdb import AsterixDB

parser = argparse.ArgumentParser()
parser.add_argument('-s', '--asterixdb-server', action='store',
                    default=getfqdn() + ':19002',
                    help='URL as <host>:<port> of the AsterixDB REST '
                         'interface.')
parser.add_argument('-B', '--bucket-name',
                    help='(S3) bucket name of the external file path.')
parser.add_argument('-R', '--bucket-region',
                    help='Region of the S3 bucket.')
parser.add_argument('-A', '--access-key-id',
                    help='Access key ID for with read permission to S3.')
parser.add_argument('-S', '--secret-access-key',
                    help='Secret access key for with read permission to S3.')
parser.add_argument('-H', '--hdfs-server',
                    help='URI of the HDFS storage server (e.g., '
                         '"hdfs://namenode:8020")')
parser.add_argument('-P', '--external-path',
                    help='Path of the external files on HDFS.')
parser.add_argument('-F', '--file-format', default='json',
                    help='Format of the external files ("json" or "parquet").')
parser.add_argument('-D', '--asterixdb-dataverse', action='store',
                    help='Default dataverse to use.')
parser.add_argument('-d', '--dataset-name',
                    help='Name of the dataset that should be created.')
parser.add_argument('-t', '--datatype', default='anyType',
                    help='Name of the data type to use for the table '
                         '("anyType" or "eventType").')
parser.add_argument('-l', '--storage-location', default='external',
                    help='Storage location of the date ("internal" or'
                         '"external"), i.e., whether or not to load the data')
add_log_level_argument(parser)
args = parser.parse_args()

conf = {
    'access_key_id': args.access_key_id,
    'bucket_name': args.bucket_name,
    'bucket_region': args.bucket_region,
    'dataset_name': args.dataset_name,
    'external_path': args.external_path,
    'hdfs_server': args.hdfs_server,
    'secret_access_key': args.secret_access_key,
    'type_name': args.datatype + 'Type' +
        ('Indexed' if args.storage_location == 'internal' else ''),
}

if args.bucket_name:
    if args.hdfs_server:
        argparse.ArgumentError(
            'Cannot set --hdfs-server and --bucket-name at the same time.')
    if not args.bucket_region:
        argparse.ArgumentError(
            'Need --bucket-region when --bucket-name is set.')
    storage_system = 's3'
else:
    storage_system = 'hdfs'
    if args.external_path.startswith('file://'):
        storage_system = 'local'
    elif not args.hdfs_server:
        argparse.ArgumentError(
            'One of --hdfs-server and --bucket-name is needed, '
            'or --external-path must be "file://...".')

# Assemble paths to SQL files
base_dir = dirname(__file__)

create_table_file = \
    join(base_dir, 'create_{}_table_{}_{}.sqlpp'
                   .format(args.storage_location,
                           args.file_format,
                           storage_system))

type_suffix = 'indexed' if args.storage_location == 'internal' else 'plain'
create_type_file = \
    join(base_dir, 'create_{}_type_{}.sqlpp'\
                   .format(args.datatype, type_suffix))

# Set up client
asterixdb = AsterixDB(args.asterixdb_server, args.asterixdb_dataverse)

# Create type
with open(create_type_file, 'r') as f:
    query = f.read()
query = query % conf
asterixdb.run(query)

# Create new table
with open(create_table_file, 'r') as f:
    query = f.read()
query = query % conf
asterixdb.run(query)
