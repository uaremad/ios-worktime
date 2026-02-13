#!/bin/bash

# This script takes the Snapshots and the Simulator screenshots if the Snapshot tests have failed
# and copies them to a FailedSnapshots directory with actual/expected.png
# and uses image magick to compare and create a diff.png

# EXAMPLE output from xcodebuild, ... are omitted parts of the filepath
# the lines after @− and @+ are used by this script
# 
# Newly-taken snapshot does not match reference.
# ...RoadsideAssistanceViewTests.swift:18: error: -[SnapshotTests.ExampleViewTests example_view] : failed - Snapshot does not match reference.
# @−
# "...__Snapshots__/Example/example_view.3.png"
# @+
# ".../Library/Developer/CoreSimulator/Devices/...Example/example_view.3.png"

set -euo pipefail

# file names, path and regex
ACTUAL_NAME=actual.png
EXPECTED_NAME=expected.png
DIFF_NAME=diff.png
OUTPUT_DIR=FailedSnapshots

# find a line with __Snapshots__ and .png
REGEX_SNAPSHOT='__Snapshots__.*\.png'

# find a line with Library/Developer/CoreSimulator/Devices/ and .png
REGEX_SIMULATOR='Library\/Developer\/CoreSimulator\/Devices.*\.png'

# function which copies the screenshots and compares it
process_files() {
    # passed arguments and striped the " " from it - otherwise copy has problems
    ORIGINAL_FILEPATH=$(echo $1 | tr -d '"')
    # expected or actual file name
    FILENAME=$(echo $2 | tr -d '"')

    # keeps last 2 parts e.g. RoadsideAssistanceViewTests/test_roadside_assistance_view.1.png
    SIGNIFICANT_PATH=$(echo $ORIGINAL_FILEPATH | rev | cut -d'/' -f-2 | rev)

    # removes .png from RoadsideAssistanceViewTests/test_roadside_assistance_view.1.png
    # -> RoadsideAssistanceViewTests/test_roadside_assistance_view.1
    NOEXTENSTION_PATH=${SIGNIFICANT_PATH%.*}

    # copies from Snapshot or Simulator directory to the FailedSnapshots directory with
    # the corresponding name (actual/expected).png
    TARGET_DIRECTORY="./$OUTPUT_DIR/$NOEXTENSTION_PATH"
    TARGET_FILEPATH="$TARGET_DIRECTORY/$FILENAME"

    mkdir -p $TARGET_DIRECTORY
    cp $ORIGINAL_FILEPATH $TARGET_FILEPATH

    # function was called with a third parameter -> perform image magick
    if [[ "$#" -eq "3" ]]; then
        ACTUAL="$TARGET_DIRECTORY/$ACTUAL_NAME"
        EXPECTED="$TARGET_DIRECTORY/$EXPECTED_NAME"
        DIFF="$TARGET_DIRECTORY/$DIFF_NAME"
        /usr/local/bin/magick compare $ACTUAL $EXPECTED $DIFF &
    fi
}

# reading the console log and checking for the messages about
# the Snapshot files (expected) and the Simulator files (actual)
while IFS= read -r LINE; do
    # echo line again to stdout for build log and xcbeautify
    echo "$LINE"

    if [[ $LINE =~ $REGEX_SNAPSHOT ]]; then
        process_files $LINE $EXPECTED_NAME
    fi

    if [[ $LINE =~ $REGEX_SIMULATOR ]]; then
        process_files $LINE $ACTUAL_NAME "magick"
    fi
done

# wait is needed for image magick to do it's magic
wait