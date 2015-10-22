#!/bin/bash

cat << EOF > ~/.netrc
machine trunk.cocoapods.org
  login $COCOAPODS_USERNAME
  password $COCOAPODS_PASSWORD
EOF

chmod 0600 ~/.netrc

pod spec lint --allow-warnings
pod trunk push --allow-warnings KalturaPlayerSDK.podspec

rm ~/.netrc
