# Village iOS — App Store Readiness Record (CYB-21)

Status: current as of 2026-10-01 — version 1.0.1 build 6, submitted for App Review
2026-09-24T19:29:44Z, is now **IN_REVIEW** (advanced from WAITING_FOR_REVIEW; Apple
is actively reviewing). ASC checklist verified complete (§3); all open verification
items checked against live App Store Connect (§7.1). Latest live verification: §9.
One known open defect: no iOS introductory offers (§7.2).
Companion GitHub issues: see the iOS-ready labels on rkweekley/village-app.

## 1. Ingestion rejection root cause (ITMS-90111) — confirmed

> Scope note: this section covers the **ingestion** rejection of build 5, which never
> reached review. The app was later **rejected in review** for Guideline 2.1(a) and
> 2.3.2 — see §8. Do not read this section as the whole rejection story.

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

## 8. Apple rejection history — Resolution Center (read 2026-09-25)

Two distinct rejections. Only the first was known when this record was written.

### 8.1 Build 5 — ingestion (ITMS-90111), never reached review
Covered in §1. Beta-macOS stamp. Fixed by rebuilding on the Mac Mini.

### 8.2 Build 6 — rejected IN REVIEW, 2026-09-16
Review thread `8c531ec1-dffc-3d80-af54-edb05ef0306f` (`REJECTION_REVIEW_SUBMISSION`,
created 2026-09-16T10:03:41Z), rejection `31ba5108`, on submission `4d62cd5b`.
Reviewed on **iPhone 17 Pro Max and iPad Air 11-inch (M3), iOS/iPadOS 27.0**,
version reviewed `1.0.1 (6)`.

- **Guideline 2.1(a) — Performance / App Completeness.** *"We were unable to access
  the app because the app displayed an error message during login."*
- **Guideline 2.3.2 — Performance / Accurate Metadata.** The promotional image for the
  promoted In-App Purchase was the same as the app icon. Apple's remedy: revise it or
  delete the associated promotional image.

### 8.3 Remediation state (verified 2026-09-25)
- **2.3.2:** `asc subscriptions promoted-purchases list --app 6803645374` returns
  **0** promoted purchases, so no promotional image remains. VERIFIED resolved at the
  ASC API level 2026-09-25 (the same backend the ASC UI reads); no promotional image on
  any IAP/subscription.
- **2.1(a):** the login failure lines up with the demo account not existing when the
  reviewer tested. `parent@village.app` was created **2026-09-16T14:39:07Z** —
  roughly 4.5 hours *after* the rejection message. The account now sits in family
  "Smith Family" (`cd708117-4917-4b2d-95a0-0dee69fdfdff`) with
  `SubscriptionStatus: active` and `SubscriptionExpiresAt: 2030-01-01`, so
  entitlement can no longer be the failure mode (the guard admits `active`).
- Review details `860e4e7c` are configured with `demoAccountRequired: true` and name
  `parent@village.app` plus usage notes. **Credentials live in the ASC review details
  only — never copy them into this repo or into an issue tracker.**

### 8.4 Resubmission
Resubmitted **2026-09-24T19:29:44Z** as the *same* submission `4d62cd5b` carrying the
*same* build 6 — no new build number. That is consistent with both rejection causes
being demo-account/metadata rather than code (Apple permits resubmitting the same
build when no code changed), but it also means **no code fix exists for the login
failure**. If the 2.1(a) error was a genuine bug — rather than missing demo
credentials — the current review will fail the same way. This is the single largest
open risk on the app and is tracked in Paperclip (see §7.2 note and CYB-32/CYB-33).

### 8.5 VERIFIED 2026-09-25 — clean first-run login reproduces on iOS 27.0 (CYB-33)

Ran the committed screenshot/login harness (`integration_test/screenshots_test.dart`,
`test_driver/screenshots.dart`) against the LIVE API (`api.villagefamily.app`, health
200) on the Mac Air, on the production/v1 code that shipped as build 6 (Air clone synced
to `79d4cab`). Each run: fresh-installed the app, reset the simulator keychain
(`xcrun simctl keychain reset` — no pre-existing state/cached session), then logged in
with the ASC review-details demo account and asserted the Hub's `NavigationBar` appears.
Both runs finished **"All tests passed"** and captured 9 byte-distinct screenshots
(md5-verified) walking Login → Hub → Chores → Rewards → Tasks → Meals → Family →
Calendar → Shopping.

- **iPhone 17 Pro Max, iOS 27.0** (sim `AD694C9A-…`) — first-run login reaches Home,
  Hub shows Smith Family / "Welcome back, Mom", 500 pts, all quick actions + bottom nav.
  **No login error, no blocked state.**
- **iPad Air 11-inch (M4), iOS 27.0** (sim `DC210B98-…`) — same clean result,
  reaches Home, no error/blocked UI. Known iPad layout polish issues remain (uneven
  Quick Actions grid, wide margins, FAB overlap — the GH-83/GH-95 line) but these are
  cosmetic and were not the basis of the 2.1(a) rejection.
- **Runtime note:** builds used the Air's iOS 27.0 simulator runtime, which matches the
  reviewer's OS exactly. The Mac Mini (stable 26.7, the shipping host) only has the
  iOS 26.5 runtime installable, so iOS 27.0 coverage came from the Air sim, not the Mini.

Conclusion: the 2.1(a) login error the reviewer hit is consistent with the demo account
not existing at review time (created 2026-09-16T14:39:07Z ≈ 4.5h AFTER the rejection).
With the demo account now present + active, first-run login reproduces cleanly on the
reviewer's device family and OS. No code change was needed. The current in-flight
WAITING_FOR_REVIEW submission is cleared against this specific risk.

Escalation remains: if Apple still rejects with 2.1(a), capture the message verbatim and
require a new build number + documented fix before resubmitting — do not resubmit
unchanged a second time.

## 9. Verification record — 2026-10-01 (live App Store Connect)

Read-only check via `asc` 5.5.0 on the Mac Mini (API-key path), 2026-10-01T14:00Z.
No mutations were made. This supersedes §7 as the latest live state.

- **Version advanced into active review.** `asc status` now reports app version
  `1.0.1` `appstore.state = **IN_REVIEW**` — it moved forward from
  `WAITING_FOR_REVIEW` (the state recorded through 2026-09-30). Apple has picked the
  submission up and is reviewing it now.
- Submission `4d62cd5b-17a5-4e14-bf6f-5b411d4a4b70`: `inFlight=true`,
  `blockingIssues=[]`, submitted 2026-09-24T19:29:44Z (~7 days in flight).
- Build 6 `ff8f51f2`: `processingState VALID`, `expired=false` (uploaded 2026-09-01).
  Phased release configured.
- Subscriptions `village.monthly` (`6807153048`) and `village.annual` (`6807153583`):
  both `WAITING_FOR_REVIEW` (expected while attached to the in-flight submission).
- `asc review history`: latest submission still in flight; **all prior submissions
  `COMPLETE`/`REMOVED`**; no new rejection. The only review thread remains the
  historical 2026-09-16 2.1(a)+2.3.2 rejection (§8.2) — already remediated (§8.3–§8.5).
- `asc review doctor`: the single "blocking" check is `version.state.editable`
  ("version is in non-editable state IN_REVIEW") — expected and benign while under
  review, not a defect. Warnings unchanged: keywords overlap app-name/subtitle,
  `whatsNew` empty (carried from CYB-28; fill on the next release).

### 9.1 Blocking gap — `asc web` session expired (needs Ryan)

`asc web auth status` → `authenticated:false, passwordStored:false`. The web session
cached on 2026-09-25 has expired, so two web-only reads could **not** be performed:

1. **Resolution Center message text** — the only place a fresh reviewer message appears.
   Rejection *detection* itself needs no web session (API state is sufficient), but the
   reviewer's verbatim text does.
2. **Apple Developer agreements** — `asc web agreements status`. The Program License
   Agreement carried `dateAgreeBy: 2026-10-01` (i.e. **today**); an unaccepted agreement
   silently holds reviews. This is worth re-checking now.

Unblock action (one click, on the Mac Mini): the staging tooling is already installed —
run **`~/Desktop/Apple-Sign-In.command`** (a `screen`-backed login that pops a 2FA
dialog and waits). No password is ever typed by an agent.

### 9.2 Monitoring gap — Paperclip CYB-32 (recorded, not yet fixed)

The CYB-32 review monitor did not fire for this cycle and its writes are contained:
the issue carries an **active board-owned recovery action**
(`configuration_validation` / `configuration_incomplete`) created after run
`c50f3545` failed on 2026-09-30T17:02Z with
`OpenCode Go … HTTP 403: Model access is disabled` (provider rejected the model, exit 1).
The monitor's `nextCheckAt` is therefore `null` and the issue was sitting `blocked`
(a monitor on a blocked issue never fires). Provider access has since recovered
(2026-10-01 runs execute on the same model), but the recovery action is owned by the
board and must be resolved before the monitor can be re-armed. The manual check in §9
above closes the observation gap for today regardless.

## 10. Apple rejection #2 — build 6 rejected in review, 2026-10-01 (CYB-32 / CYB-48 / CYB-49)

Read live 2026-10-01T17:18–17:25Z via `asc` 5.5.0 on the Mac Mini — API-key path **and** a
live `asc web` session (Ryan re-authenticated 2026-10-01T16:21Z). This supersedes §9 as the
latest live state. No mutations were made.

Resolution Center thread `8c531ec1-dffc-3d80-af54-edb05ef0306f`, **new** rejection
`d07de555-c5eb-464b-bcc3-a8764c039521`, message posted **2026-10-01T17:18:30.992Z** on the
same submission `4d62cd5b` — reviewed as `1.0.1 (6)` on iPhone 17 Pro Max and iPad Air
11-inch (M3), iOS/iPadOS 27.0.

Apple opens with: *"The issues we previously identified still need your attention."*

### 10.1 Guideline 2.1(b) — Performance / App Completeness (NEW — this is the blocker)
> The In-App Purchase products in the app exhibited one or more bugs which create a poor
> user experience. Specifically, an error message appeared stating "subscription product
> unavailable" after tapping the purchase button.

**2.1(a) did NOT repeat.** The login error is absent from this rejection, and the reviewer
reached the paywall — which requires a successful login. §8.5's analysis is supported.

Reviewer attachment `Screenshot-1001-101752.png` (retrieved, OCR'd): the paywall in its
"First month free" state, both plan cards **enabled** ("Choose Monthly" $5.99/month,
"Choose Annual" $49.99/year), toast **"Subscription product unavailable. Please try again
shortly."**

Cause, traced in the shipped code: that string is `subscription_page.dart:109`, raised by
`_buyViaStore()` **only** when `_findProduct(tier)` returns null — i.e. when
`BillingService.fetchProducts()` -> `InAppPurchase.queryProductDetails()` returned **no**
product for `village.monthly` / `village.annual`. Two shipped defects compound it:
`fetchProducts()` discards `ProductDetailsResponse.error` / `.notFoundIDs` and
`_loadProducts()` swallows every exception (so the StoreKit failure is undiagnosable from
the field); and the `_PlanCard`s render hardcoded prices with a live `onTap` regardless of
whether `_products` loaded, so an unloadable product still presents as purchasable.

### 10.2 Guideline 2.3.2 — Performance / Accurate Metadata (repeat of §8.2)
> Your promotional image is the same as the app's icon. You submitted duplicate or
> identical promotional images for different promoted In-App Purchase products and/or win
> back offers.

Re-read live: `asc subscriptions promoted-purchases list --app 6803645374` -> **total 0**.
No promoted purchase carries a promotional image today, so there is no API-visible object
to fix; this needs a web-UI confirmation (tracked in CYB-49).

### 10.3 State after the rejection
- `appstore.state` = **REJECTED**; `review.state` = **UNRESOLVED_ISSUES**; version `1.0.1`
  (`f6ba0c4c-bc37-4ae7-842f-f2273d0cb7d7`), `submission.blockingIssues` = "submission
  `4d62cd5b…` has unresolved issues".
- `asc review history`: this submission `outcome: rejected`; the `appStoreVersion` item is
  `REJECTED`, both `subscriptionVersion`s and the `subscriptionGroupVersion` sit
  `READY_FOR_REVIEW`.
- Both subscriptions are back to **`READY_TO_SUBMIT`** — no longer attached to any
  submission. Prices read back monthly `5.99 USD`, annual `49.99 USD`.
- `asc review doctor`: error `review.submission.unresolved_issues`; new remediation
  warning *"first-time subscriptions must be submitted via the app version page in App
  Store Connect (not the API)"* — re-attaching the subscriptions is a **web-UI** step.
- Introductory offers **0** on both products; promoted purchases **0**.
- **Agreement watchdog CLEAR:** Apple Developer Program License Agreement `XG8DNV4HYY`
  v5031 `active`, `pending:false`, accepted 2026-08-20T20:10:14Z (its `dateAgreeBy`
  2026-10-01 has now passed with the agreement already accepted). Apple Developer
  Agreement v4 `active`. `contractMessages: []`. No silent review hold.
- Declarations: one `MEDICAL_DEVICE` requirement `PENDING_COLLECTION`, `required:false` —
  non-blocking.

### 10.4 Consequence — same-build resubmission is CLOSED
Build 6 was resubmitted **unchanged** after the 2026-09-16 rejection and has now been
rejected again, on a **runtime** defect (the IAP does not load). §8.4's warning was
correct. The next submission requires a **new build number** and a documented fix. Do not
resubmit unchanged a third time.

### 10.5 Monitor correction
§9.2 recorded the CYB-32 monitor as unfixed. That is now stale: the board armed
`executionPolicy.monitor` on 2026-10-01 (`nextCheckAt` 2026-10-02T02:10:04Z, `timeoutAt`
2026-10-08T14:10:04Z, `maxAttempts` 12, `recoveryPolicy` `escalate_to_board`), it fired
(attempt 8), and the 2026-10-01T17:18Z re-check **caught this rejection** — the monitor did
its job. CYB-32 is closed with the outcome recorded; CYB-50 carries the watch for the next
submission.

### 10.6 Follow-up issues
- **CYB-48** (critical) — fix 2.1(b): new build + sandbox proof + the two code defects.
- **CYB-49** (high) — clear 2.3.2, re-attach both subscriptions to the next submission,
  fill `whatsNew`.
- **CYB-50** (high, blocked by 48/49) — monitor the next submission's review.
- **CYB-31** — promoted to `todo`: the intro-offer work's "do not disturb the in-flight
  review" constraint is void and its gate condition #2 (next release cycle) is met. Create
  the intro offers **before** the next submission.

## 11. CYB-48 — Guideline 2.1(b) "subscription product unavailable" (build 6)

### 11.1 What Apple hit
Rejection `d07de555-c5eb-464b-bcc3-a8764c039521` (2026-10-01T17:18:30Z, thread
`8c531ec1-dffc-3d80-af54-edb05ef0306f`) on iPad Air 11-inch (M3) / iPadOS 27.0 and
iPhone 17 Pro Max / iOS 27.0: tapping a plan card produced the toast
"Subscription product unavailable. Please try again shortly."

The string is `subscription_page.dart:109` and is raised **only** when
`_findProduct(tier)` returns null, i.e. `queryProductDetails` resolved neither
`village.monthly` nor `village.annual`.

### 11.2 Store environment ruled OUT (live App Store Connect, asc 5.5.0)
| Check | Command | Result |
|---|---|---|
| Product IDs | `asc subscriptions list --app 6803645374` | `village.monthly` (6807153048), `village.annual` (6807153583) — **exact match** with `lib/core/config.dart` |
| Prices | `asc subscriptions pricing summary --app 6803645374` | 5.99 USD / 49.99 USD, `planType UPFRONT` |
| Localizations (version-scoped) | `asc subscriptions versions localizations list --version-id <ver>` | en-US "Village Monthly" / "Village Annual" + description, **present** |
| Group localization | `asc subscriptions groups versions localizations list --version-id af642536…` | en-US "Village", **present** |
| Review screenshots | `asc subscriptions review app-store-screenshot view` | present, `assetDeliveryState COMPLETE`, 1206×2622 |
| Subscription versions | `asc subscriptions versions list` | v1 `READY_FOR_REVIEW` |
| Bundle-ID capability | `asc bundle-ids capabilities list --bundle MKBKBKA6Q7` | `IN_APP_PURCHASE` **enabled** |
| Paid Apps Agreement | `asc web agreements status` | active (v5031, `pending:false`) — not the cause |
| Intro offers | `asc subscriptions offers introductory list` | **0** (separate defect — CYB-31) |

### 11.3 The one configuration asymmetry — subscription availability
```
asc subscriptions pricing availability available-territories --availability-id 6807153048
  -> total 1: [USA]
asc subscriptions pricing availability view --subscription-id 6807153048
  -> availableInNewTerritories: false
asc subscriptions pricing plan-availability show --subscription-id 6807153048
  -> planType UPFRONT, availableTerritories: [USA]  (total 1)
asc pricing availability view --app 6803645374
  -> availableInNewTerritories: true   (app itself is broadly available: 175 territories)
```
Both subscriptions are sold in **exactly one territory (USA)** while the app is
available in all 175. A client whose storefront is outside a product's
availability gets that product back in `invalidProductIdentifiers` — an **empty
product list with no error**, which is byte-for-byte the observed symptom
(Apple TN3186, "Troubleshooting In-App Purchases availability in the sandbox").

Not yet provable from here: the App Review sandbox account's storefront. That is
now instrumented — see §11.5.

### 11.4 StoreKit 1 vs StoreKit 2 — ruled out
`pubspec.lock` resolves `in_app_purchase 3.3.0` + `in_app_purchase_storekit 0.4.11+1`.
In that version `InAppPurchaseStoreKitPlatform._useStoreKit2 = true` is the
**default** (`lib/src/in_app_purchase_storekit_platform.dart:34`;
`enableStoreKit2()` is deprecated with the note "StoreKit 2 is now the default").
The app therefore queries via StoreKit 2 `Product.products(for:)`, not the
StoreKit 1 `SKProductsRequest` path. `enableStoreKit1()` exists but is never
called. Source-verified, not assumed.

### 11.5 Fixes shipped (build 7)
1. **`BillingService.fetchProducts()` no longer discards the diagnosis.** It
   returns a `ProductFetchResult` carrying `products`, `notFoundIDs`,
   `errorCode`/`errorMessage` (`IAPError`) and the **device storefront country
   code**; it never throws; every query is logged with a `[StoreKit]` prefix.
   Added `fetchProductsWithRetry()` — StoreKit can legitimately return an empty
   list on a cold launch, so a single empty response is no longer conclusive.
2. **An unloadable product is never presented as purchasable.**
   `BillingService.productForTier()` is the single purchasable gate; when it
   returns null the plan card's `FilledButton` is `onPressed: null` ("Currently
   unavailable" / "Checking…"). `planPriceLabel()` renders the store's own
   `ProductDetails.price` and an em dash before it resolves — no hardcoded
   `$5.99` / `$49.99` anywhere in the purchase UI.
3. **The failure is visible.** When the fetch fails the paywall shows the
   StoreKit diagnostic line (error code, notFoundIDs, storefront) and a Retry
   button, so the next failure is reportable from a screenshot.
4. **Version bumped `1.0.1+6` → `1.0.1+7`.** Build 6 must not be resubmitted.
5. Regression tests: `test/billing_service_test.dart` (13 tests) pin the exact
   product IDs, the purchasable gate, the no-hardcoded-price rule and the
   diagnostic payload.

### 11.6 Open items before resubmission
- **CYB-49 / web UI:** re-attach both subscriptions to the next app version and
  clear 2.3.2 (a web-UI step; `asc review doctor` warns first-time subscriptions
  must be submitted via the app version page, not the API).
- **Territory availability (§11.3):** widen both subscriptions beyond USA, or
  confirm the reviewing storefront is US. Decision owner: Ryan.
- **CYB-31:** create the iOS 30-day introductory offer — the paywall still
  advertises "First month free" with 0 intro offers configured.
- Sandbox proof on an iOS 27.0 simulator/device requires a sandbox tester
  account; `asc sandbox list` currently returns **total 0** (none configured).

### 11.7 Build 7 archived, uploaded and VERIFIED (2026-10-01)

```
$ asc builds list --app 6803645374
1.0.1  build 7   VALID   2026-10-01T11:10:25-07:00   expired:false
1.0.1  build 6   VALID   2026-09-01T08:44:20-07:00

$ asc builds uploads list --app 6803645374
{id: 335733d2-ced2-4f68-9513-1899557e7e3e, cfBundleShortVersionString:"1.0.1",
 cfBundleVersion:"7", platform:"IOS", createdDate:"2026-10-01T11:09:36-07:00",
 state:{state:"COMPLETE"}}
```

Local artifact: `~/projects/village-app-ios/build/ios/ipa/Village.ipa`, 22,873,316 bytes,
sha256 `2a5504122cedc5960f84e51a65978d3529528b75f39aa8c08f4e176050729033`;
`CFBundleIdentifier app.villagefamily.app`, `CFBundleShortVersionString 1.0.1`,
`CFBundleVersion 7`, `MinimumOSVersion 15.0`. Source commit `fbd2ff9` on `production/v1`.
Uploaded with `asc builds upload --app 6803645374 --ipa build/ios/ipa/Village.ipa`.

**Build 7 is a draft build — it is NOT attached to a submission and nothing was
submitted for review.** Attaching it and resubmitting is CYB-49 (+ the territory
and intro-offer decisions in §11.6) once the interaction on CYB-48 is answered.

#### Mac Mini build-environment repairs required before this build
The build machine had degraded since build 6 (2026-09-24) and two repairs were needed:
1. **Xcode 27.0 licence was unaccepted** — `xcrun simctl` refused every call.
   Fixed: `sudo xcodebuild -license accept`.
2. **Ruby + CocoaPods were gone.** Homebrew's Cellar had been cleaned down to four
   formulae, so `~/.local/bin/pod` failed with `can't find gem cocoapods`.
   The gems survived in `~/.gem/ruby/4.0.0` (cocoapods 1.17.0) so restoring the matching
   Ruby ABI 4.0.0 was enough: `brew update && brew install ruby` (4.0.7), then
   `gem install --user-install bigdecimal drb mutex_m base64 logger ostruct benchmark ffi nkf`
   for the default gems Ruby 4 no longer bundles. Build with
   `GEM_HOME=GEM_PATH=$HOME/.gem/ruby/4.0.0` and that binstub on `PATH`.
3. **Codesign failed with `errSecInternalComponent`** from the SSH session. The login
   keychain must be unlocked *in the same session that runs the build*, plus the key
   partition list extended to `codesign`:
   ```bash
   security default-keychain -s "$HOME/Library/Keychains/login.keychain-db"
   security unlock-keychain -p "<login password>" "$HOME/Library/Keychains/login.keychain-db"
   security set-key-partition-list -S apple-tool:,apple:,codesign -s -k "<login password>" \
     "$HOME/Library/Keychains/login.keychain-db"
   ```
   Unlocking in a *previous* SSH session is not enough — the build script must do it itself.

Note: the Mini's `CoreSimulator` is still stale (`CoreSimulator is out of date. Current
version (1051.55.0) is older than build version (1171.7.0)`, Xcode reports
`DVTCoreDeviceCore` plug-in load failures and the iOS 27 runtime install fails with
"Authorization is required to install the packages"). Device archives are unaffected,
but simulator work needs the Xcode first-launch components installed. This is why the
iOS 27.0 sandbox proof in §11.6 is still outstanding.

## 12. CYB-49 — the 2.3.2 promotional image has a LIVE cause (2026-10-01)

§10.2 concluded "promoted purchases -> total 0, so no API-visible object carries a
promotional image". **That conclusion was wrong.** `promoted-purchases list` only
covers the *Promoted Purchase* object. The promotional image itself hangs off the
**subscription version**: `subscriptionImages`, read with
`asc subscriptions versions images list --version-id <VER>`. Apple:
*"Subscription images — Create, modify, and delete promotion images for auto-renewable
subscriptions"*, and the image is **1024x1024**.

### 12.1 Proven cause — both images ARE the app icon

```
$ asc subscriptions versions images list --version-id cabac1de-7482-4fde-9f83-5bd696f3e034  # village.monthly v1
  id cbac7921-d737-4f49-a302-dffdaf3e4265  fileName sub_icon.png  fileSize 134624
                                           1024x1024  assetDeliveryState COMPLETE
$ asc subscriptions versions images list --version-id 38f315ce-5125-4726-8fbd-1d3172aa4532  # village.annual v1
  id 107a87a6-89a6-4af9-9c9b-44d9cfb04fd9  fileName sub_icon.png  fileSize 134624
                                           1024x1024  assetDeliveryState COMPLETE
```

The app's own icon `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png`
is **134624 bytes**. Downloading both ASC images from Apple's CDN and hashing raw pixels:

| image | pixel sha256 |
|---|---|
| app icon (repo) | `307a99d73193ca0c8b0244016ff04aa8ab82e1d930e3980fa7ef6902c864b8ce` |
| village.monthly promotional image | `307a99d73193ca0c8b0244016ff04aa8ab82e1d930e3980fa7ef6902c864b8ce` |
| village.annual promotional image | `307a99d73193ca0c8b0244016ff04aa8ab82e1d930e3980fa7ef6902c864b8ce` |

All three are **pixel-identical**. That reproduces Apple's 2.3.2 bullet for bullet —
*"Your promotional image is the same as the app's icon"* **and** *"duplicate or identical
promotional images for different ... products"*. Left unchanged this is a third rejection.

### 12.2 Why it cannot be fixed while the rejected submission stands

```
$ asc subscriptions versions images upload --version-id cabac1de-... --file promo-monthly.png
Error: failed to reserve: Version is not in modifiable state.

$ asc subscriptions versions create --subscription-id 6807153048
Error: There is already an inflight version with id 'cabac1de-...' for subscription 6807153048

$ asc subscriptions versions list --subscription-id 6807153048 --state PREPARE_FOR_SUBMISSION
  total 0
```

Both subscription versions are still **inflight on the rejected submission**
`4d62cd5b`. `asc review items list --submission 4d62cd5b-...` returns four
`reviewSubmissionItems`: the `appStoreVersion` item `REJECTED`, and the two
`subscriptionVersion`s (`38f315ce`, `cabac1de`) plus the `subscriptionGroupVersion`
(`af642536`) still `READY_FOR_REVIEW`. Apple will not modify or supersede an inflight
version, so there is no modifiable version to carry the next submission's metadata.

Release path (**needs a decision — Ryan owns it**, see §12.6):

```
asc review items-remove --id <subscriptionVersionItemId> --confirm     # x2
   (or) asc review submissions-update --id 4d62cd5b-... --canceled=true --confirm
```

### 12.3 The replacement images are BUILT and Apple-compliant

`docs/appstore/promotional-images/promo-monthly.png` and `promo-annual.png` —
1024x1024, RGB, flattened, no rounded corners, 72 dpi, distinct from the app icon
**and from each other** (mirrored band layout plus a different label), teal `#0D7C66`
taken from the real icon. Generated reproducibly by
`docs/appstore/promotional-images/gen_promo.py`.

| | pixel sha256 |
|---|---|
| `promo-monthly.png` | `cd12ae3dac66d45bac233b39ddd9fb6142fc0064458cd7f71009d1098da6a370` |
| `promo-annual.png`  | `75ede247d65024bcd9aefd028a63f5c0b84560c5883bdd555b80932830a7e39b` |

Upload once §12.2 is unwound:
`asc subscriptions versions images upload --version-id <VER> --file <png>`

### 12.4 Attach is refused too — `MISSING_METADATA`

```
$ asc web review subscriptions list --app 6803645374
  village.annual  6807153583  MISSING_METADATA  submitWithNextAppStoreVersion=false
  village.monthly 6807153048  MISSING_METADATA  submitWithNextAppStoreVersion=false
$ asc web review subscriptions attach --app 6803645374 --subscription-id 6807153048 --confirm
Attach preflight: subscription "Village Monthly" (6807153048) is MISSING_METADATA, so
Apple will not attach it to the next app version review yet.
```

Apple's **web** view says `MISSING_METADATA` while the public API says
`READY_TO_SUBMIT` and `asc validate subscriptions --app 6803645374` returns
**0 errors / 0 blocking**. The web value is the one Apple's attach endpoint enforces.
Root cause is the same inflight-version lock as §12.2.

### 12.5 `whatsNew` CANNOT be populated — Apple's first-release rule

```
$ asc localizations update --id 9887a44e-43a8-483e-8385-ebfeb78cbba9 --whats-new "$(cat whatsnew.txt)"
Error: ... Attribute 'whatsNew' cannot be edited at this time
```

Control experiment: the **same** localization accepted a `--description` PATCH carrying
its existing value (HTTP 200), so the version localization is editable and the lock is
`whatsNew`-specific. `whatsNew` is the "What's New in This Version" field shown on
*updates*; for an app's **first** version there is nothing to describe, so Apple makes it
read-only until the next version (HTTP 409 `STATE_ERROR`). This matches the fastlane
maintainer note ("only for updates — not first versions") and is a known operator pattern
(OP-16). **The `metadata.required.whats_new` warning from `asc review doctor` is a false
positive for a first release** — no work item can satisfy it.

Prepared text is kept at
`docs/appstore/promotional-images/whatsnew-1.0.1.txt` (828 chars) for the first update.

### 12.6 Consequence for the next submission

In order:

1. **release both subscription versions from submission `4d62cd5b`** (§12.2) — decision;
2. upload the two distinct promotional images (§12.3);
3. attach both subscriptions (via the app version page — §12.4);
4. attach **build 7** to version 1.0.1 (currently build **6** is attached) and submit.

Skipping 1–2 will very likely repeat 2.3.2 a third time.

## 13. 2026-10-01 — CYB-48 verification round (build 7, live ASC re-check, proof status)

Ryan's decisions on the CYB-48 interaction `da7069b4` (idempotency key
`cyb48-unblock-2026-10-01`, answered 2026-10-01T19:0xZ):

- **territories → `keep_usa`.** Both subscriptions stay USA-only. The reviewer's
  storefront is treated as US, so the availability asymmetry in §11.3 is accepted
  rather than changed. No App Store Connect write was made.
- **sandbox_proof → `ios265`.** Accept a *client-side* proof on the iOS 26.5
  simulator (StoreKit configuration file) instead of a live sandbox-tester proof
  on iOS 27.0. `asc sandbox list` still returns **total 0** (only the account
  holder can create a sandbox tester) and the Mini cannot install the iOS 27
  runtime (§11.7 note).

### 13.1 Live App Store Connect re-verification (read-only, 2026-10-01T19:20Z)

```
$ asc status --app 6803645374
appstore.version 1.0.1  state REJECTED
submission 4d62cd5b-...  inFlight true  blockingIssues ["unresolved issues"]
review.state UNRESOLVED_ISSUES   builds.latest 1.0.1 buildNumber 7  VALID  expired false

$ asc subscriptions versions list --subscription-id <each>
village.monthly 6807153048  version cabac1de-7482-4fde-9f83-5bd696f3e034  READY_FOR_REVIEW
village.annual  6807153583  version 38f315ce-5125-4726-8fbd-1d3172aa4532  READY_FOR_REVIEW

$ asc subscriptions review app-store-screenshot view --subscription-id <each>
village.monthly  fileName SOURCE  assetDeliveryState COMPLETE  1206x2622
village.annual   fileName SOURCE  assetDeliveryState COMPLETE  1206x2622
$ asc subscriptions pricing availability available-territories --availability-id <each>
["USA"]   (total 1)          availableInNewTerritories false     (both products)
$ asc subscriptions offers introductory list --subscription-id <each>
total 0                                                            (both products)
```

So every TN3186 "empty product list" cause is verified good on the store side —
two products, exact identifiers, prices, localizations, **review screenshots
present for both** (the annual one was not previously checked), IAP capability,
active Paid Apps Agreement — with territory availability (§11.3) as the single
asymmetry, and that one Ryan has now accepted.

### 13.2 Build 7 is uploaded and VALID (draft, unattached)

`asc builds list --app 6803645374` → `1.0.1 build 7 VALID 2026-10-01T11:10:25-07:00
expired:false`; `asc builds uploads list` → `cfBundleVersion "7"`,
`state COMPLETE`. The IPA sha256 is recorded in §11.7. Build 7 is **not** attached to
a submission and nothing was submitted — attaching it plus the §12.6 sequence is CYB-49.
Build 6 is never resubmitted.

### 13.3 The client-side runtime proof is BUILT but BLOCKED by the host

Deliverables that landed (committed, see §13.4):

- `ios/Runner/Village.storekit` — local StoreKit configuration carrying the two
  production identifiers/prices (5.99 P1M / 49.99 P1Y) in one subscription group.
- `Runner.xcscheme` — `<StoreKitConfigurationFileReference
  identifier="../../../Runner/Village.storekit">` in **both** the Test and Launch
  actions (the identifier is a path relative to the scheme file, per Apple's own
  scheme model — the file needs no target membership).
- `ios/RunnerTests/RunnerTests.swift` — `VillageStoreKitTests`: both production
  identifiers resolve, the store's own prices arrive, a monthly purchase completes,
  and test04 holds the out-of-process StoreKit purchase sheet on screen for 40 s so
  the host can `xcrun simctl io booted screenshot` it.

Two build-host problems were found and one was fixed:

1. **`-project` cannot build this app; `-workspace` can.** `in_app_purchase_storekit`,
   `url_launcher_ios` and `shared_preferences_foundation` are linked through **Swift
   Package Manager** (`ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage`),
   while `flutter_secure_storage` is still a CocoaPod. `xcodebuild test -project
   ios/Runner.xcodeproj` never builds that pod, so `GeneratedPluginRegistrant.m` fails
   with `Module 'flutter_secure_storage' not found`. `-workspace ios/Runner.xcworkspace`
   builds clean. (Repairing the pod state also needs the Ruby 4.0.0 gem binstub,
   `$HOME/.gem/ruby/4.0.0/bin`, on `PATH` — plain `/opt/homebrew/bin` gives
   `pod: command not found`.)
2. **No StoreKit environment can be made active on the Mini's iOS 26.5 simulator.**
   With the suite running (build green, app hosting the tests — `Bundle.main` =
   `app.villagefamily.app`), every path returns an empty product list:

   ```
   xcodebuild test -workspace ios/Runner.xcworkspace -scheme Runner
     -destination 'platform=iOS Simulator,id=DA36D93F-…'   (iPhone 17 Pro Max, 26.5)

   scheme TestAction StoreKitConfigurationFileReference present   -> products []
   SKTestSession(contentsOf:)  variant A full doc, version 4/0     -> products []  tx 0  storefrontEcho ""
   SKTestSession(contentsOf:)  variant B Xcode-shaped, version 2/0 -> products []  tx 0  storefrontEcho ""
   SKTestSession(contentsOf:)  variant C Xcode-shaped, version 4/0 -> products []  tx 0  storefrontEcho ""
   SKTestSession(contentsOf:)  variant D full doc, version 2/0     -> products []  tx 0  storefrontEcho ""
   bogus id "village.nonexistent"                                  -> 0
   ```

   The file *parses* (no `SKTestSession` init error, 2302 bytes read back) but the
   session is inert: `session.storefront` does not even round-trip ("GBR" reads back
   as ""), and `Storefront.current` reports the real store rather than the
   configuration's storefront. Variant B is byte-shaped like Xcode's own generated
   files (verified against checked-in `*.storekit` files), so this is not a schema
   defect — no StoreKit test environment is being installed for the process on this
   host, which is consistent with the stale `CoreSimulator` / missing Xcode
   first-launch components recorded in §11.7.

   Consequence: `VillageStoreKitTests` **skips** (it does not fail) when the product
   list is empty, with the reason above, so a red-looking run cannot be mistaken for
   an app regression.

Unblock action (owner: **Ryan**, one of):
- install the iOS 27.0 simulator runtime and the Xcode first-launch components on the
  Mac Mini (the `CoreSimulator is out of date` state in §11.7) and run the suite from
  the Xcode GUI with the scheme's StoreKit configuration selected; **or**
- create a sandbox tester in App Store Connect (the `create_tester` option that was
  declined for this round) and run the paywall against the live sandbox products.

### 13.4 What makes the 2.1(b) symptom impossible in build 7 regardless

`fbd2ff9` removed the two code defects that turned an empty StoreKit response into
Apple's rejection:

1. `BillingService.fetchProducts()` returns a `ProductFetchResult` carrying
   `products`, `notFoundIDs`, the `IAPError` code/message and the device storefront,
   logs every query under `[StoreKit]`, and never throws;
   `fetchProductsWithRetry()` absorbs a legitimately empty cold-launch response.
2. `productForTier()` is the single purchasable gate. When the store returns nothing
   the plan card's button is **disabled** and reads "Currently unavailable" /
   "Checking…", `planPriceLabel()` renders the store's own price (never the hardcoded
   `$5.99`/`$49.99`), and the paywall prints the StoreKit diagnostic line plus Retry.

Verified locally in the WSL workspace: `flutter test test/billing_service_test.dart`
→ **13/13 pass** (product IDs, the purchasable gate, the no-hardcoded-price rule, the
diagnostic payload). `flutter analyze` → 0 errors (90 issues, unchanged baseline).

So with `keep_usa` accepted, the residual risk is bounded and *legible*: if the
reviewing storefront were non-US the products would still come back empty, but the
app would then show a disabled button, the storefront/notFoundIDs diagnostic and a
Retry — no dead purchase button, no "subscription product unavailable" toast, and the
next report of it would carry the storefront code that proves it.

### 13.5 File set for this round

| Path | Purpose |
|---|---|
| `ios/Runner/Village.storekit` | Local StoreKit configuration (production IDs/prices) |
| `ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme` | StoreKit config on Test + Launch actions |
| `ios/RunnerTests/RunnerTests.swift` | `VillageStoreKitTests` (self-skipping when no environment) |

