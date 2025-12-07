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


start_time=$(date -d "2025-12-${1}T0:00 UTC-5" +'%s')
current_time=$(date +'%s')
if [ -f "$basedir/cookies.env" ] && [ "$current_time" -gt "$start_time" ]; then
    source "$basedir/cookies.env"
    if [ -n "$AOC_COOKIE" ]; then
        wget --no-cookies --header "Cookie: session=$AOC_COOKIE" "https://adventofcode.com/2025/day/$1/input" -O "$basedir/$name/input"
    fi
fi
