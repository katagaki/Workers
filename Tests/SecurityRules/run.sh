#!/bin/zsh
set -eu

projectDirectory="${0:A:h:h:h}"
derivedDataDirectory="${1:?Pass the derived data directory from a Workers build}"
testDirectory="$(mktemp -d /tmp/workers-security-tests.XXXXXX)"
cd "$projectDirectory"

xcrun swiftc -swift-version 6 -module-cache-path "$testDirectory/cache" \
    CloudflareKit/Core/APIEnvelope.swift \
    CloudflareKit/Core/APIMessage.swift \
    CloudflareKit/Core/ResultInfo.swift \
    CloudflareKit/Core/JSONCoding.swift \
    CloudflareKit/Core/JSONValue.swift \
    CloudflareKit/Core/CloudflareError.swift \
    CloudflareKit/Client/CloudflareClient.swift \
    CloudflareKit/Client/CloudflareClient+SecurityRules.swift \
    CloudflareKit/Models/SecurityRuleset.swift \
    "$derivedDataDirectory/Build/Intermediates.noindex/Workers.build/Debug-iphonesimulator/CloudflareKit.build/DerivedSources/GeneratedStringSymbols_Localizable.swift" \
    Tests/SecurityRules/RequestTests.swift \
    -o "$testDirectory/RequestTests"
"$testDirectory/RequestTests"
