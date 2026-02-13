#!/usr/bin/env bash

set -euo pipefail

appstore_version=`curl -s https://itunes.apple.com/de/lookup\?bundleId\=de.sunrise | egrep -o '"version":"[^"]*' | cut -d'"' -f4` || exit -1
echo "Current app version on AppStore is $appstore_version"
echo $appstore_version > .app-version
