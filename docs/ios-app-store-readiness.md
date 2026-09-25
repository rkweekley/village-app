# Village iOS — App Store Readiness Record (CYB-21)

Status: current as of 2026-09-25 (production/v1 @ 22c161e, 1.0.1+6) — version 1.0.1
build 6 submitted for App Review 2026-09-24T19:29:44Z and still WAITING_FOR_REVIEW;
ASC checklist verified complete (§3); all open verification items have now been
checked against live App Store Connect and closed (§7.1).
One known open defect: no iOS introductory offers (§7.2).
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
| Signing (Distribution) | Verify on Mini | Release = Manual, iPhone Distribution, team R9U8JNTV28, profile "Village App Store". `exportOptions.plist` references profile UUID `b40b64ca-3769-4110-9ee6-3d0b73046aa0` — that exact profile must be installed on the Mac Mini (GH-99). |
| Privacy manifests | OK — verify in build | All native plugins in pubspec.lock ship `PrivacyInfo.xcprivacy` (shared_preferences_foundation 2.5.6, url_launcher_ios 6.4.1, in_app_purchase_storekit 0.4.11+1; flutter_secure_storage 9.2.4 uses only Keychain, not a required-reason API). Flutter engine ships its own. Verify no ITMS-91053 in the uploaded build. |
| Info.plist usage strings | Not required | No camera/photo/mic/location/contacts APIs in the app → no usage-description keys needed. ATS: API is https://api.villagefamily.app, no exceptions declared. |
| IAP / StoreKit | Verify in ASC | App expects iOS product IDs `village.monthly` / `village.annual` (lib/core/config.dart). MUST match App Store Connect products + backend `Apple:MonthlyProductId` / `Apple:AnnualProductId`, incl. 30-day intro offers and subscription group (GH-98). Restore Purchases button exists on the subscription page. No external (Stripe) payments are reachable on iOS — Stripe checkout is web-only (GH-98). |
| Terms of Use / Privacy Policy in-app | FIXED | Added Terms of Use + Privacy Policy links on the subscription page and Terms of Use on the About/Legal page (both `villagefamily.app/terms` and `/privacy`). Required by Guideline 3.1.2 / 5.1.1 for auto-renewable subscriptions. |
| Versioning | OK | `1.0.1+6` in pubspec → CFBundleShortVersionString 1.0.1, CFBundleVersion 6. Legal/About page hardcodes "Version 1.0.0" (cosmetic — fold into GH-98 follow-up). |
| App icon | OK | 1024×1024, RGB, no alpha channel. Full AppIcon set present. |
| Screenshots | Verify on Mini | Screenshot harness committed (integration_test + driver). Must capture on a 6.9"/6.7" iPhone sim + iPad sim on the Mini and upload in ASC (GH-100). |
| Deployment target | OK | IPHONEOS_DEPLOYMENT_TARGET 15.0 (Xcode 26 supports; not a rejection risk). |
| Background modes / iCloud | Not used | No UIBackgroundModes, no iCloud entitlements — nothing to declare. |
| Symbols | FIXED | `exportOptions.plist` `uploadSymbols` flipped true so dSYMs upload with the IPA (crash symbolication). |
| Beta-macOS guard | FIXED | New preflight script `ios/scripts/check_build_macos.sh` (GH-96). |
| CI | OK for web | deploy.yml only builds web/Docker; iOS is built manually on the Mac Mini (no iOS CI currently). |

## 3. Verification items — status as of 2026-09-24 (CYB-28)

All three items were verified live against App Store Connect (asc CLI 4.11.0, API
key T8SMTUY74K, on the Mac Mini) on 2026-09-24. The version was submitted and is
with Apple as of 2026-09-24T19:29:44Z.

1. **GH-99 (IAP products)** — VERIFIED: subscription group `22349177` "Village"
   exists; review submission `4d62cd5b-17a5-4e14-bf6f-5b411d4a4b70` carries 4 items
   (appStoreVersion + 2 subscriptionVersions + subscriptionGroupVersion), all
   `READY_FOR_REVIEW`. App pricing: Free download tier (isFree=true, USD) — IAP
   carries monetization.
2. **GH-100 (Mini signing/build)** — VERIFIED: build 6 (1.0.1+6) is in ASC,
   `processingState VALID`, `buildAudienceType APP_STORE_ELIGIBLE`, uploaded
   2026-09-01 from the Mac Mini (stable macOS 26.7). A successful upload+ingest
   proves the Distribution cert + "Village App Store" profile (UUID
   b40b64ca-3769-4110-9ee6-3d0b73046aa0) + `exportOptions.plist` are correct.
   Guard script present at `ios/scripts/check_build_macos.sh`. WSL/Mini clones on
   `production/v1`; build machine `sw_vers` = 26.7 (25G229, no beta suffix).
3. **GH-101 (ASC submission checklist)** — VERIFIED complete:
   - Screenshots: `APP_IPHONE_61` ×9 (1206x2622), `APP_IPHONE_65` ×9 (1284x2778 —
     the set Apple requires at submit), `APP_IPAD_PRO_3GEN_129` ×9 (2064x2752), all
     `assetDeliveryState COMPLETE`.
   - App icon: 1024×1024 RGB no-alpha in Assets.xcassets (repo-verified); ASC icon
     derives from the uploaded build.
   - Privacy labels: published (the 09-24 `asc review submit` passed the
     appDataUsages gate that blocked 08-31; declaration unchanged since). Spot-check
     in ASC web UI remains Ryan's (legal attestation).
   - Metadata: description (309 chars), keywords, supportUrl, subtitle "Family
     organizer", privacy policy URL — all set on en-US.
   - Review details (id 860e4e7c…): contact Ryan Weekley / support@villagefamily.app
     / 7405383553; demo account `parent@village.app` (`demoAccountRequired=true`);
     notes guide reviewer to the subscription page + IAP.
   - Export Compliance: build 6 `usesNonExemptEncryption=false` → HTTPS-only,
     exempt, no ERN.
   - Version: 1.0.1 (build 6) attached, appStoreState `WAITING_FOR_REVIEW`.
   - Privacy manifests (ITMS-91053): all plugins in pubspec.lock ship
     PrivacyInfo.xcprivacy (`shared_preferences_foundation` 2.5.6,
     `url_launcher_ios` 6.4.1, `in_app_purchase_storekit` 0.4.11+1;
     `flutter_secure_storage` 9.2.4 = Keychain only) — no ingestion/review flag on
     build 6.
   - Non-blocking gap: "What's New" (release notes) is empty — a warning, not a
     blocker; not editable while WAITING_FOR_REVIEW. Fill on the next release.
4. Submission (external mutation) was executed 2026-09-24 from the Mini; outcome
   monitoring is Ryan's (Resolution Center / ASC web UI). Nothing further is
   uploaded or edited from this environment while the review is in flight.

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

- GH-96 Beta-macOS build guard (fixed: preflight script + docs; closed 2026-09-25)
- GH-97 In-app Terms of Use + Privacy Policy links (fixed: subscription page + About page; closed)
- GH-98 Verify ASC IAP products match app (verified against live ASC; closed — see §7.1)
- GH-99 Verify Mac Mini signing + export 1.0.1+6 (verified against live ASC; closed — see §7.1)
- GH-100 ASC submission checklist: screenshots, privacy labels, metadata (verified; closed)
- GH-101 Export dSYMs via uploadSymbols (fixed: exportOptions.plist; closed)
- GH-102 No iOS introductory offers — 30-day free trial promised but not configured (OPEN — see §7.2)

Correction: revisions of this document before 2026-09-25 listed the issue numbers
above off by one (the beta-macOS guard is GH-96, not GH-97) and credited GH-102
with the dSYM fix, which was GH-101. Fixed here.

## 6. Reference

- Apple: ITMS-90111 invalid build / beta macOS stamping
- Apple Guideline 3.1.1/3.1.2 (In-App Purchase, subscriptions), 5.1.1 (privacy),
  ITMS-91053 (privacy manifest)
- Repo: github.com/rkweekley/village-app, branch production/v1

## 7. Verification record — 2026-09-25 (live App Store Connect)

### 7.1 Closed-out verification items

Checked directly against App Store Connect with `asc` 5.5.0 on the Mac Mini
(API key `VillageKey` / `T8SMTUY74K`) plus a cached Apple web session:

- App `6803645374`; version `1.0.1` `WAITING_FOR_REVIEW`; submission `4d62cd5b`
  `WAITING_FOR_REVIEW`, submitted 2026-09-24T19:29:44Z; **no blocking issues**.
- Build 6: `processingState VALID`, `buildAudienceType APP_STORE_ELIGIBLE`,
  uploaded 2026-09-01.
- Group `22349177` "Village": `village.monthly` (`6807153048`) and
  `village.annual` (`6807153583`), both `WAITING_FOR_REVIEW`,
  `isAppStoreReviewInProgress: true`.
- Apple Developer agreements: `pending: false`, no contract alert messages;
  Program License Agreement active (v5031, accepted 2026-08-20,
  `dateAgreeBy` 2026-10-01 — already satisfied, but re-check before Oct 1, since
  an unaccepted agreement silently holds reviews).
- EULA: none custom, so Apple's standard EULA governs.
- App Privacy: published; EMAIL_ADDRESS, NAME, OTHER_USER_CONTENT,
  PURCHASE_HISTORY — all APP_FUNCTIONALITY / DATA_LINKED_TO_YOU;
  `unrepresentableCount: 0`.

### 7.2 Open defect — no introductory offers on iOS

`asc subscriptions offers introductory list` returns **0** for both products.
The paywall advertises a free trial and Android/Play has active 30-day
`monthly-freetrial` / `annual-freetrial` offers, but the iOS trial is granted
server-side only (`Family.TrialEndsAt`). Guideline 3.1.2 risk.

Tracked as GH-102 and Paperclip CYB-31. Deliberately deferred until the current
submission resolves or the next release cycle, so the in-flight review is not
disturbed.

### 7.3 Tooling note — why these items sat open

`asc` on the Mac Mini was 4.11.0, whose entire `asc web` family was broken:
Apple moved the App Store Connect web-session config endpoint and 4.x hard-coded
`olympus/v1/app/config`, so `asc web auth login` died with
`failed to fetch auth service key (status 404)`. Upgraded to 5.5.0
(checksum-verified; old binary backed up at `~/.local/bin/asc-4.11.0.bak`).
This is why the ASC verification items looked "blocked on Ryan's credentials"
through 2026-09-24 — no credential would have made the old tool work.