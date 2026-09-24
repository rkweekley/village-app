# Village iOS — App Store Readiness Record (CYB-21)

Status: current as of 2026-09-24 (production/v1 @ 1.0.1+6).
Companion GitHub issues: see the iOS-ready labels on rkweekley/village-app.

## 1. Rejection root cause (ITMS-90111) — confirmed

- Build 5 (`1.0.1+3-candidate`) was rejected by Apple App Store ingestion with
  **ITMS-90111** ("Invalid Build … your build is not an acceptable build" family).
- Confirmed root cause (commit `7aa03ba`): the IPAB was compiled on the **Mac Air
  running beta macOS 27.0** — the binary's `BuildMachineOSBuild` stamp is
  `26A5421a`, a beta build ID. Apple's App Store ingestion rejects builds stamped
  by beta macOS, regardless of the Xcode version used.
- Fix direction (commits `3de5f0a`, `36c5815`): manual Distribution signing for the
  App Store profile + `ios/exportOptions.plist` for headless `exportArchive`, and a
  version bump to **1.0.1+6** so the rebuild (on the Mac Mini, stable macOS 26.7)
  uploads as build 6, above the rejected build 5.
- Guard: `ios/scripts/check_build_macos.sh` fails the build if the machine is on a
  beta macOS/Xcode. Run it before every archive (see §6).

## 2. Full readiness review — findings

| Area | Verdict | Notes / issue |
|---|---|---|
| Signing (Distribution) | Verify on Mini | Release = Manual, iPhone Distribution, team R9U8JNTV28, profile "Village App Store". `exportOptions.plist` references profile UUID `b40b64ca-3769-4110-9ee6-3d0b73046aa0` — that exact profile must be installed on the Mac Mini (GH-100). |
| Privacy manifests | OK — verify in build | All native plugins in pubspec.lock ship `PrivacyInfo.xcprivacy` (shared_preferences_foundation 2.5.6, url_launcher_ios 6.4.1, in_app_purchase_storekit 0.4.11+1; flutter_secure_storage 9.2.4 uses only Keychain, not a required-reason API). Flutter engine ships its own. Verify no ITMS-91053 in the uploaded build. |
| Info.plist usage strings | Not required | No camera/photo/mic/location/contacts APIs in the app → no usage-description keys needed. ATS: API is https://api.villagefamily.app, no exceptions declared. |
| IAP / StoreKit | Verify in ASC | App expects iOS product IDs `village.monthly` / `village.annual` (lib/core/config.dart). MUST match App Store Connect products + backend `Apple:MonthlyProductId` / `Apple:AnnualProductId`, incl. 30-day intro offers and subscription group (GH-99). Restore Purchases button exists on the subscription page. No external (Stripe) payments are reachable on iOS — Stripe checkout is web-only (GH-99). |
| Terms of Use / Privacy Policy in-app | FIXED | Added Terms of Use + Privacy Policy links on the subscription page and Terms of Use on the About/Legal page (both `villagefamily.app/terms` and `/privacy`). Required by Guideline 3.1.2 / 5.1.1 for auto-renewable subscriptions. |
| Versioning | OK | `1.0.1+6` in pubspec → CFBundleShortVersionString 1.0.1, CFBundleVersion 6. Legal/About page hardcodes "Version 1.0.0" (cosmetic — fold into GH-98 follow-up). |
| App icon | OK | 1024×1024, RGB, no alpha channel. Full AppIcon set present. |
| Screenshots | Verify on Mini | Screenshot harness committed (integration_test + driver). Must capture on a 6.9"/6.7" iPhone sim + iPad sim on the Mini and upload in ASC (GH-101). |
| Deployment target | OK | IPHONEOS_DEPLOYMENT_TARGET 15.0 (Xcode 26 supports; not a rejection risk). |
| Background modes / iCloud | Not used | No UIBackgroundModes, no iCloud entitlements — nothing to declare. |
| Symbols | FIXED | `exportOptions.plist` `uploadSymbols` flipped true so dSYMs upload with the IPA (crash symbolication). |
| Beta-macOS guard | FIXED | New preflight script `ios/scripts/check_build_macos.sh` (GH-97). |
| CI | OK for web | deploy.yml only builds web/Docker; iOS is built manually on the Mac Mini (no iOS CI currently). |

## 3. Open verification items (human / Mini) — hand-off

1. (GH-99) Confirm ASC products `village.monthly` ($5.99/mo) and `village.annual`
   ($49.99/yr) exist, are Ready to Submit, with intro offers, in one subscription
   group; confirm backend Apple product-id settings match.
2. (GH-100) On the Mac Mini (stable macOS 26.7, NOT the Mac Air):
   `ios/scripts/check_build_macos.sh` must pass; Distribution certificate for team
   R9U8JNTV28 + the "Village App Store" profile (UUID b40b64ca-…) must be installed;
   run `flutter build ipa --release --export-options-plist=ios/exportOptions.plist`.
3. (GH-101) Upload the IPA via Transporter or `xcrun altool --upload-app` with a
   user with App Manager role; complete ASC metadata: screenshots (6.9" iPhone +
   iPad), privacy labels, review contact, version 1.0.1 build 6, "Export Compliance"
   and "App Privacy" answers.
4. Approval: live upload to App Store Connect is an external mutation — requires
   Ryan's Apple Developer credentials/2FA. No credentials are stored in this
   environment; nothing is uploaded from here.

## 4. Build sequence for the next successful submission (Mini, stable macOS)

```bash
# 0) On the Mac Mini only (stable macOS 26.7). Never archive on the Mac Air (beta 27.0).
cd ~/village-app            # or wherever the working copy lives

# 1) Guard: block beta OS/Xcode before wasting a build
./ios/scripts/check_build_macos.sh

# 2) Version must be 1.0.1+6 (next build above rejected build 5)
grep '^version:' pubspec.yaml

# 3) Fetch deps + archive + export via the committed export options
flutter pub get
flutter build ipa --release --export-options-plist=ios/exportOptions.plist

# 4) Result: build/ios/ipa/*.ipa — upload via Transporter or altool
```

## 5. GitHub issues created from this review

- GH-97 Beta-macOS guard (fixed: preflight script + docs)
- GH-98 IAP Terms of Use / Privacy links in-app (fixed: subscription page + About page)
- GH-99 Verify ASC IAP product IDs, offers, group, backend match (verify)
- GH-100 Verify Mac Mini signing: cert, profile UUID, export 1.0.1+6 (verify)
- GH-101 ASC submission checklist: screenshots, privacy labels, metadata (verify)
- GH-102 Export dSYMs via uploadSymbols (fixed: exportOptions.plist)

## 6. Reference

- Apple: ITMS-90111 invalid build / beta macOS stamping
- Apple Guideline 3.1.1/3.1.2 (In-App Purchase, subscriptions), 5.1.1 (privacy),
  ITMS-91053 (privacy manifest)
- Repo: github.com/rkweekley/village-app, branch production/v1