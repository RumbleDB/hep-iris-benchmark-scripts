#!/usr/bin/env bash

if [ -d "/scripts/copy.d/" ]
then
    rsync -avh /scripts/copy.d/ /
fi

if [ -d "/scripts/run.d/" ]
then
    for script in $(echo /scripts/run.d/* | sort)
    do
        if [ -x "$script" ]
        then
            "$script"
        fi
    done
fi

"$@"
