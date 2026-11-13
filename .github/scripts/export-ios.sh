#!/usr/bin/env bash
set -euo pipefail
umask 077

: "${IOS_CERTIFICATE_BASE64:?Set the IOS_CERTIFICATE_BASE64 Actions secret}"
: "${IOS_CERTIFICATE_PASSWORD:?Set the IOS_CERTIFICATE_PASSWORD Actions secret}"
: "${IOS_PROFILE_BASE64:?Set the IOS_PROFILE_BASE64 Actions secret}"
: "${IOS_AGE_RECIPIENT:?Set the IOS_AGE_RECIPIENT Actions variable}"
case "$IOS_AGE_RECIPIENT" in
  age1*) ;;
  *) echo "IOS_AGE_RECIPIENT must contain an age public key" >&2; exit 1 ;;
esac
age -r "$IOS_AGE_RECIPIENT" </dev/null >/dev/null

signing_dir=$(mktemp -d "$RUNNER_TEMP/ios-signing.XXXXXX")
keychain="$signing_dir/signing.keychain-db"
profile_path=
cleanup() {
  security delete-keychain "$keychain" >/dev/null 2>&1 || true
  if [[ -n "$profile_path" ]]; then
    rm -f "$profile_path"
  fi
  rm -f "$signing_dir/distribution.p12" "$signing_dir/profile.mobileprovision" "$signing_dir/profile.plist"
}
trap cleanup EXIT

printf '%s' "$IOS_CERTIFICATE_BASE64" | base64 -D > "$signing_dir/distribution.p12"
printf '%s' "$IOS_PROFILE_BASE64" | base64 -D > "$signing_dir/profile.mobileprovision"
security cms -D -i "$signing_dir/profile.mobileprovision" > "$signing_dir/profile.plist"

bundle_id=com.scenestudio.tiktokpreview
profile_uuid=$(python3 - "$signing_dir" "$bundle_id" <<'PY'
import datetime
import pathlib
import plistlib
import re
import sys
import uuid

directory = pathlib.Path(sys.argv[1])
bundle_id = sys.argv[2]
with (directory / "profile.plist").open("rb") as file:
    profile = plistlib.load(file)
entitlements = profile["Entitlements"]
expiration = profile["ExpirationDate"]
if expiration <= datetime.datetime.now(expiration.tzinfo):
    sys.exit("The Apple provisioning profile has expired.")
if not profile.get("ProvisionedDevices") or entitlements.get("get-task-allow", True):
    sys.exit("An Ad Hoc distribution profile with registered devices is required.")
team_id = profile["TeamIdentifier"][0]
prefix = profile["ApplicationIdentifierPrefix"][0]
if (
    not re.fullmatch(r"[A-Z0-9]{10}", team_id)
    or entitlements.get("application-identifier") != f"{prefix}.{bundle_id}"
):
    sys.exit("The provisioning profile does not match the Runner bundle ID.")
profile_uuid = str(uuid.UUID(profile["UUID"])).upper()

# Apply signing only to Runner Release, without passing profile settings to Swift packages.
project = pathlib.Path("ios/Runner.xcodeproj/project.pbxproj")
contents = project.read_text(encoding="utf-8")
pattern = r"(97C147071CF9000F007C117D /\* Release \*/ = \{.*?\n\t\t\};)"
match = re.search(pattern, contents, re.S)
if not match or f"PRODUCT_BUNDLE_IDENTIFIER = {bundle_id};" not in match[0]:
    sys.exit("Runner Release settings changed. Update the CI signing script.")
settings = '''CODE_SIGN_STYLE = Manual;
				"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "Apple Distribution";
				DEVELOPMENT_TEAM = %s;
				PROVISIONING_PROFILE_SPECIFIER = "%s";''' % (team_id, profile_uuid)
block = match[0].replace("CODE_SIGN_STYLE = Automatic;", settings)
if block == match[0]:
    sys.exit("Could not configure manual signing for Runner Release.")
project.write_text(contents[:match.start()] + block + contents[match.end():], encoding="utf-8")

with (directory / "export.plist").open("wb") as file:
    plistlib.dump({
        "destination": "export",
        "method": "release-testing",
        "signingStyle": "manual",
        "signingCertificate": "Apple Distribution",
        "teamID": team_id,
        "provisioningProfiles": {bundle_id: profile_uuid},
    }, file)
print(profile_uuid)
PY
)

keychain_password=$(openssl rand -hex 32)
security create-keychain -p "$keychain_password" "$keychain"
security set-keychain-settings -lut 3600 "$keychain"
security unlock-keychain -p "$keychain_password" "$keychain"
security import "$signing_dir/distribution.p12" -P "$IOS_CERTIFICATE_PASSWORD" \
  -t cert -f pkcs12 -k "$keychain" -T /usr/bin/codesign -T /usr/bin/security
security set-key-partition-list -S apple-tool:,apple: -k "$keychain_password" "$keychain" >/dev/null
security list-keychains -d user -s "$keychain" "$HOME/Library/Keychains/login.keychain-db"
unset IOS_CERTIFICATE_BASE64 IOS_CERTIFICATE_PASSWORD IOS_PROFILE_BASE64
rm -f "$signing_dir/distribution.p12"

profile_dir="$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"
mkdir -p "$profile_dir"
profile_path="$profile_dir/$profile_uuid.mobileprovision"
cp "$signing_dir/profile.mobileprovision" "$profile_path"

xcodebuild -quiet -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$signing_dir/Runner.xcarchive" archive
xcodebuild -quiet -exportArchive -archivePath "$signing_dir/Runner.xcarchive" \
  -exportOptionsPlist "$signing_dir/export.plist" -exportPath "$signing_dir/export"

shopt -s nullglob
ipa_files=("$signing_dir/export/"*.ipa)
if [[ ${#ipa_files[@]} -ne 1 ]]; then
  echo "Expected one IPA from Xcode export" >&2
  exit 1
fi
unzip -q "${ipa_files[0]}" -d "$signing_dir/verified"
app="$signing_dir/verified/Payload/Runner.app"
test -f "$app/embedded.mobileprovision"
test "$(/usr/libexec/PlistBuddy -c 'Print :MinimumOSVersion' "$app/Info.plist")" = "15.0"
xcrun lipo "$app/Runner" -verify_arch arm64
codesign --verify --deep --strict "$app"
age -r "$IOS_AGE_RECIPIENT" -o "$RUNNER_TEMP/Scene-Studio-iOS.ipa.age" "${ipa_files[0]}"
