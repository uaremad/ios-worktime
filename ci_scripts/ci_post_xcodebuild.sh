#!/bin/zsh

 echo "🔷 Stage: POST-Xcode Build is activated .... "

 if [ "$CI_BUNDLE_ID" = "com.jandamerau.Brief-App" ];
 then
  #   echo "💙 Uploading Symbols To Firebase Release Version"
  #   $CI_PRIMARY_REPOSITORY_PATH/Scripts/upload-symbols -gsp $CI_PRIMARY_REPOSITORY_PATH/App/Resources/Google/GoogleService-Info.plist -p ios $CI_ARCHIVE_PATH/dSYMs/Brief-App.app.dSYM
fi

 echo "🔷 Stage: POST-Xcode Build is DONE .... "

 exit 0
