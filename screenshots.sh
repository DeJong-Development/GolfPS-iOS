#!/bin/sh

#  screenshots.sh
#  GolfPS
#
#  Created by Greg DeJong on 11/16/22.
#  Updated on 03/07/24
#
#  Reference:
#       https://benoitpasquier.com/automating-appstore-localized-screenshot-xctest/
#       https://blog.winsmith.de/english/ios/2020/04/14/xcuitest-screenshots.html

#  In order to run this, we need xcparse:
#  brew install chargepoint/xcparse/xcparse

#  New install of Xcode may not have command line tools linked correctly. Reselect command line tools to ensure Xcode is properly linked

# The Xcode project to create screenshots for
workspaceName="GolfPS.xcworkspace"

# The scheme to run tests for
schemeName="GolfPS Screenshots"

derivedDataPath="/tmp/GolfPSDerivedData"

# Save final screenshots into this folder (it will be created)
targetFolder="/Users/gadejong/Desktop/GolfPSScreenshots"

bundleName="com.dejongdevelopment.golfps"

# All the simulators we want to screenshot
# Copy/Paste new names from Xcode's
# "Devices and Simulators" window
# or from `xcrun simctl list`.
simulators=(
    "iPhone 8 Plus"
)
    
#    "iPhone 15 Pro Max" #6.7"
#    "iPhone 14 Plus" #6.5"
#    "iPhone 15" #5.8"
#    "iPhone 8 Plus (16.0)" #5.5"
#    "iPhone SE (3rd generation)" #4.7"
#    "iPad Pro (12.9-inch) (5th generation)"
#    "iPad Pro (11-inch) (3rd generation)"
    
# 16.0
#    "iPad (9th generation)"
#    "iPad Pro (12.9-inch) (5th generation)"
#    "iPad Pro (11-inch) (3rd generation)"
#    "iPad mini (6th generation)"
#    "iPhone 14"


os_version="16.0"  #16.0 is the most stable, it allows changes to system

# All the languages we want to screenshot (ISO 3166-1 codes)
languages=(
    "en"
)

# All the appearances we want to screenshot
# (options are "light" and "dark")
appearances=(
    "light"
    "dark"
)

#    "light"
#    "dark"


#read -p "Rebuild the workspace? [y/N]: " REBUILD_WORKSPACE
#REBUILD_WORKSPACE=${REBUILD_WORKSPACE:-N}
    
for simulator in "${simulators[@]}"
do
    # Boot up the new simulator
    if xcrun simctl list devices | grep "$simulator" | grep -q "Booted"; then
        echo "Simulator is already booted."
    else
        xcrun simctl boot "$simulator"
        echo "Simulator was not booted, booting now."
    fi

    # Build without testing
    xcodebuild -testLanguage $language -workspace "$workspaceName" -scheme "$schemeName" -sdk iphonesimulator -derivedDataPath $derivedDataPath -destination "platform=iOS Simulator,OS=$os_version,name=$simulator" build-for-testing
            
    for language in "${languages[@]}"
    do
        for appearance in "${appearances[@]}"
        do
            rm -rf "$derivedDataPath/Logs/Test"
            echo "📲  Building and Running for $simulator in $language"

            # Set the booted simulator to the correct appearance
            xcrun simctl status_bar "$simulator" override \
                --time "2024-01-01T013:41:00+0000" \
                --dataNetwork wifi \
                --wifiMode active \
                --wifiBars 3 \
                --cellularMode notSupported \
                --batteryState charged \
                --batteryLevel 100
            echo "Updating status bar..."
            xcrun simctl ui "$simulator" appearance $appearance
            echo "Updating display mode appearance ($appearance)..."
            xcrun simctl privacy "$simulator" grant all $bundleName
            echo "Granting all permissions..."
            
            # Test without building
            xcodebuild -testLanguage $language -workspace "$workspaceName" -scheme "$schemeName" -sdk iphonesimulator -derivedDataPath $derivedDataPath -destination "platform=iOS Simulator,OS=$os_version,name=$simulator" test-without-building

            # Build and Test
#            xcodebuild -testLanguage $language -workspace "$workspaceName" -scheme "$schemeName" -derivedDataPath "$derivedDataPath" -destination "platform=iOS Simulator,OS=$os_version,name=$simulator" build test
            
            echo "🖼  Collecting Results..."
            mkdir -p "$targetFolder/$simulator/$language/$appearance"

            xcResultFile="$(plutil -extract logs xml1 -o - "$derivedDataPath/Logs/Test/LogStoreManifest.plist" | xmllint --xpath 'string(//string[contains(text(),"xcresult")])' -)"
            
            echo "Found latest result"
            echo $xcResultFile
            xcparse screenshots "$derivedDataPath/Logs/Test/$xcResultFile" "$targetFolder/$simulator/$language/$appearance"
                                               
            echo "Reset status bar..."
            xcrun simctl status_bar "$simulator" clear
            
            echo "Reset privacy..."
            xcrun simctl privacy booted reset all $bundleName
        done
    done

    echo "✅  Done"
done
