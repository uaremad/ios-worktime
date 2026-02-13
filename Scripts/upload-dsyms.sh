#!/usr/bin/env bash

set -euo pipefail

: "${APP_IDENTIFIER:?Environment variable missing}"
: "${BUILD_CONFIG:?Environment variable missing}"

SCRIPT_DIR=$(cd $(dirname $0) && pwd)
cd $SCRIPT_DIR/..

DSYMS=$(find . -regex "./$APP_IDENTIFIER.*.dSYM.zip")

if [[ -f $DSYMS ]]
then
    Pods/FirebaseCrashlytics/upload-symbols -gsp Credentials/$BUILD_CONFIG/GoogleService-Info.plist -p ios $DSYMS
    rm $DSYMS
else
    ls
    echo
    echo "File '$DSYMS' not found"
    exit 1
fi
