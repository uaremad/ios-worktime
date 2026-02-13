#!/bin/bash

DIR=`dirname $0`

rm -rf Resources/Localizations
mkdir -p Resources/Localizations

phrase pull || exit 1

$DIR/StringsFilesPostProcessing.swift

swiftgen || ./Pods/SwiftGen/bin/swiftgen
