#!/bin/zsh

 # fail if any command fails

 echo "🔷 Stage: Post-clone is activated .... "

 set -e
 # debug log
 set -x

  echo "💙 Brief-App is installing Hombrew Kegs .... "

 # Install dependencies using Homebrew
 brew install swiftlint swiftformat

 # Jump to correct folder
 ls && cd ..

  echo "💙 Brief-App is starting TUIST .... "

 # Generate project with tuist
 # Note: You've to enable "tuist bundle" in "MakeFile"
 # and push the ".tuist-bundle" folder to your repo,
 # see also ".gitignore"
 .tuist-bin/tuist cache
 .tuist-bin/tuist generate --no-open

 echo "💙 Brief-App workspace generation is done by TUIST "

 echo "🔷 Stage: Post-clone is done .... "

 exit 0
