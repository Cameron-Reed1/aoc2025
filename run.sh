#!/usr/bin/env bash


if [ "$#" -ne 1 ] && [ "$#" -ne 2 ]; then
    echo -e "Usage: $0 <day number> [<part>]\nExample: '$0 1 2' runs day 1 part 2"
    exit 1
fi


day="$1"
part="--part$2"
base_dir="$(dirname "$(realpath "$0")")"
dir="$base_dir/$(printf "day%02d" "$day")"

if [ "$part" = "--part" ]; then
    part="both"
fi

if [ "$part" != "--part1" ] && [ "$part" != "--part2" ] && [ "$part" != "both" ]; then
    echo "Part must be 1 or 2"
    exit 1
fi


if [ ! -d "$dir" ]; then
    echo "Directory for day $day does not exist"
    echo "Expected to find $dir"
    exit 2
fi


pushd "$dir" > /dev/null

if [ ! -f "./input" ]; then
    echo "Input file for day $day does not exist"
    echo "Expected to find $(pwd)/input"
    popd > /dev/null
    exit 2
fi

if [ "$part" = "both" ]; then
    echo -e "\x1b[1;4mPart 1\x1b[0m"
    zig build run -Doptimize=ReleaseFast -- --part1 < ./input

    echo -e "\n\x1b[1;4mPart 2\x1b[0m"
    zig build run -Doptimize=ReleaseFast -- --part2 < ./input
else
    zig build run -Doptimize=ReleaseFast -- "$part" < ./input
fi

popd > /dev/null
