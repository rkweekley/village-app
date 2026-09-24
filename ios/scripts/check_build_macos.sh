#!/usr/bin/env bash
# check_build_macos.sh — preflight guard for iOS App Store archives.
#
# Why: Build 5 of Village (1.0.1+3-candidate) was rejected by Apple with
# ITMS-90111 because it was compiled on a Mac running beta macOS 27.0
# (BuildMachineOSBuild 26A5421a). Apple's App Store ingestion rejects
# beta-macOS-stamped builds regardless of Xcode.
#
# Usage:  ./ios/scripts/check_build_macos.sh   (exit 1 = do NOT archive here)
# Run from the repo root on the Mac build machine before `flutter build ipa`.

set -u

fail() { echo "FAIL: $*" >&2; exit 1; }
warn() { echo "WARN: $*" >&2; }

# --- macOS ---
[ "$(uname -s)" = "Darwin" ] || fail "This guard must run on macOS."

OS_VERSION=$(sw_vers -productVersion 2>/dev/null || echo "")
OS_BUILD=$(sw_vers -buildVersion 2>/dev/null || echo "")
echo "macOS: $OS_VERSION (build $OS_BUILD)"

# Stable macOS builds end in digits (e.g. 24A335, 26A1234). A trailing
# lowercase letter marks a beta/seed build (e.g. 26A5421a).
if [[ "$OS_BUILD" =~ ^[0-9]+[A-Z][0-9]+[a-z]$ ]]; then
  fail "This macOS build ($OS_BUILD) is a BETA/seed build. Apple rejects beta-stamped binaries (ITMS-90111). Archive on stable macOS only."
fi

# --- Xcode ---
if command -v xcodebuild >/dev/null 2>&1; then
  XCODE_VERSION=$(xcodebuild -version 2>/dev/null | head -1 || echo "")
  echo "Xcode: $XCODE_VERSION"
  case "$XCODE_VERSION" in
    *beta*|*Beta*|*RC*) fail "Xcode looks like a beta/RC release ($XCODE_VERSION). Use a stable Xcode." ;;
  esac
else
  warn "xcodebuild not found on PATH — cannot verify Xcode version."
fi

# --- Version sanity (Village-specific) ---
PUBSPEC=$(grep '^version:' pubspec.yaml 2>/dev/null | awk '{print $2}')
echo "pubspec version: ${PUBSPEC:-unknown}"
[ -n "$PUBSPEC" ] || warn "pubspec.yaml not found in cwd — run from the repo root."

echo "OK: environment looks safe to archive for App Store."
exit 0