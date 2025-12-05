#!/usr/bin/env bash


if [ -z "$1" ]; then
    echo "Usage: $0 [day number]"
    exit 1
fi


basedir=$(dirname "$(realpath "$0")")
name=$(printf "day%02d" "$1")


if [ ! -d "$basedir" ]; then
    echo "Failed to get base directory"
    exit 2
fi

if [ -d "$basedir/$name" ]; then
    echo "Project directory for $name already exists"
    exit 0
fi

cp -r "$basedir/base" "$basedir/$name"
sed -i "s/PROJECT_NAME/$name/" "$basedir/$name/build.zig"
