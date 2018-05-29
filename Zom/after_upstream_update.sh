#!/bin/sh

projectfile="../ChatSecure/ChatSecure.xcodeproj/project.pbxproj"
oldTeam=$(awk -F '=|;' '/DevelopmentTeam/ {print $2; exit}' "$projectfile")
newTeam="9SV9LPRC42"
sed -i '' "s/$oldTeam/ $newTeam/g" "$projectfile"
echo "Changed team from $oldTeam to $newTeam"
sed -i '' "s/ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES = YES;/ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES = NO;/g" "$projectfile"
echo "Changed ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES to NO"
sed -i '' "s/SWIFT_VERSION = 3.0;/SWIFT_VERSION = 4.0;/g" "$projectfile"
echo "Changed SWIFT_VERSION to 4.0"
