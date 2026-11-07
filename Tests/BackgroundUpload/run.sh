#!/bin/zsh
set -eu

projectDirectory="${0:A:h:h:h}"
derivedDataDirectory="${1:?Pass the derived data directory from a Workers build}"
testDirectory="$(mktemp -d /tmp/workers-background-upload-tests.XXXXXX)"
port=$((20000 + RANDOM % 20000))
cd "$projectDirectory"

xcrun swiftc -parse-as-library -swift-version 6 -module-cache-path "$testDirectory/cache" \
    CloudflareKit/Core/*.swift \
    CloudflareKit/Client/R2BackgroundUploader.swift \
    CloudflareKit/Client/CloudflareClient.swift \
    CloudflareKit/Client/CloudflareClient+Accounts.swift \
    CloudflareKit/Models/Account.swift \
    CloudflareKit/Models/TokenVerification.swift \
    CloudflareKit/Models/UserProfile.swift \
    "$derivedDataDirectory/Build/Intermediates.noindex/Workers.build/Debug-iphonesimulator/CloudflareKit.build/DerivedSources/GeneratedStringSymbols_Localizable.swift" \
    Tests/BackgroundUpload/Harness.swift -o "$testDirectory/harness"

head -c 3000000 /dev/urandom > "$testDirectory/small.bin"
head -c 30000000 /dev/urandom > "$testDirectory/large.bin"
python3 Tests/BackgroundUpload/server.py "$port" > "$testDirectory/server.log" &
serverProcess=$!
trap 'kill $serverProcess' EXIT
sleep 1

"$testDirectory/harness" errors "$port" "$testDirectory/small.bin"
"$testDirectory/harness" start "$port" "$testDirectory/large.bin"
"$testDirectory/harness" resume "$port" "$testDirectory/large.bin"

for fileName in small large; do
    digest="$(shasum -a 256 "$testDirectory/$fileName.bin" | cut -d' ' -f1)"
    grep -q "$digest" "$testDirectory/server.log"
done
print "Background upload tests passed"
