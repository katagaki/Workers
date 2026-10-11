#!/bin/zsh
set -eu
projectDirectory="${0:A:h:h:h}"
derivedDataDirectory="${1:?Pass the derived data directory from a Workers build}"
testDirectory="$(mktemp -d /tmp/workers-operation-tests.XXXXXX)"
cd "$projectDirectory"
xcrun swiftc -swift-version 6 -module-cache-path "$testDirectory/cache" \
    CloudflareKit/Core/*.swift CloudflareKit/Models/*.swift CloudflareKit/Client/*.swift \
    CloudflareKit/Analytics/*.swift CloudflareKit/Demo/*.swift CloudflareKit/Tail/*.swift \
    "$derivedDataDirectory/Build/Intermediates.noindex/Workers.build/Debug-iphonesimulator/CloudflareKit.build/DerivedSources/GeneratedStringSymbols_Localizable.swift" \
    Tests/Operations/RequestTests.swift -o "$testDirectory/RequestTests"
"$testDirectory/RequestTests"
