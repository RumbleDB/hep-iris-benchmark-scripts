#!/bin/bash

if ! /opt/hive/bin/schematool -dbType mysql -info
then
    /opt/hive/bin/schematool -dbType mysql -initSchema
fi

/opt/hive/bin/hive --service metastore
