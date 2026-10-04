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

### 7.2 CLOSED 2026-10-01 — the introductory offers now exist on iOS

Originally an open defect: `asc subscriptions offers introductory list` returned
**0** for both products while the paywall advertised a free trial and
Android/Play carried active 30-day `monthly-freetrial` / `annual-freetrial`
offers (the iOS trial was granted server-side only via `Family.TrialEndsAt`) —
a Guideline 3.1.2 risk.

**Both offers were created on 2026-10-01 under CYB-31** (board approval
`69676df3-b33c-4842-a155-f1a9a585d3fc`, accepted). `list` now returns
`total: 1` for each product. Full evidence, the exact commands, the territory
finding, and the rollback path are in **§15** below. Nothing else was mutated.

Tracked as GH-102 and Paperclip CYB-31. The original deferral (don't disturb the
in-flight submission `4d62cd5b`) ended when Apple rejected build 6 on
2026-10-01: the submission became `UNRESOLVED_ISSUES`/`REJECTED`, no review was
in flight, and gate condition 2 (next release cycle — build 7, a new build
number) was met.

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
- **CYB-31 — DONE 2026-10-01:** both iOS 30-day introductory offers were
  created (USA, `ONE_MONTH`, `FREE_TRIAL`, 1 period) on subscriptions
  `6807153048` + `6807153583`. `list` returns `total: 1` for each — see §15.
  Removed from the open list.
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

## 14. 2026-10-01 (round 2) — the client-side proof is blocked by an Apple platform bug, not by the app or the config

The `ios265` interaction answer (interaction `da7069b4`) asked for a client-side
proof on the iOS 26.5 simulator using a StoreKit configuration file. This round
built that proof, ran it on the reviewer's device family, and **characterised**
why it cannot report a live environment on this host. The verdict is now
machine-recorded on every run instead of inferred.

### 14.1 What was measured (Mac Mini, Xcode 27.0 27A266a, iOS 26.5)

`RunnerTests/VillageStoreKitTests.test00` writes its verdict into the app
container so the host can read it as plain text:

```
[CYB48-DIAG] bundle=app.villagefamily.app
[CYB48-DIAG] config_path=/Users/cyberal/projects/village-app-ios/ios/Runner/Village.storekit
[CYB48-DIAG] config_exists=true
[CYB48-DIAG] storefront_before=USA
[CYB48-DIAG] sktestsession=OK storefront_echo= transactions=0
[CYB48-DIAG] storefront_roundtrip=FAIL
[CYB48-DIAG] products_resolved=0 of 2 ids=
[CYB48-DIAG] storefront_after=USA
[CYB48-DIAG] verdict=NO_STOREKIT_ENVIRONMENT
```

Reading it:

- The app under test is the **real** app (`app.villagefamily.app`) on the
  reviewer's device family (iPhone 17 Pro Max, iOS 26.5) — the suite is hosted,
  not simulated at the Dart layer.
- `ios/Runner/Village.storekit` exists and **loads**: `SKTestSession(contentsOf:)`
  constructs with **no error**.
- But the session is **inert**: its declared storefront (`"USA"` in the config)
  does **not** round-trip (echo is empty, `allTransactions()` = 0).
- `Product.products(for:)` returns **0 of 2** identifiers while
  `Storefront.current` reports the device's *real* store. No StoreKit test
  environment was installed for the process — which is exactly the empty product
  list shape that produced build 6's rejection, and it is reproducible with the
  fixed code, proving it is environmental.

Run result: **1 passed, 4 skipped, 0 failed** — the four product/purchase tests
skip (never fail) when no environment is live, so a red-looking run cannot be
mistaken for an app regression.

### 14.2 Root cause of the blocker — an upstream StoreKit regression on iOS simulators

- **Published regression:** RevenueCat `purchases-ios` PR #6897 —
  *"StoreKit unit tests can't fetch products on iOS simulators with Xcode 26.4+
  due to a StoreKit bug"*. Their workaround is to run the same suite on **Mac
  Catalyst** on Xcode 26.5, *"where the bug doesn't reproduce"*.
- **Corroborated at file level on this host:** the installed Xcode ships a
  *runnable* `StoreKitTest.framework` binary for iPhoneOS, AppleTVOS, WatchOS,
  XROS and MacOSX, but **only an SDK `.tbd` link stub for the four simulator
  platforms**:

  ```
  $ ls …/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks/
  AppIntentsTesting.framework  Evaluations.framework  Testing.framework
  XCTest.framework  XCUIAutomation.framework  _Testing_CoreGraphics.framework
  _Testing_CoreImage.framework  _Testing_CoreTransferable.framework
  _Testing_Foundation.framework  _Testing_UIKit.framework
  # no StoreKitTest.framework
  $ file …/Platforms/MacOSX.platform/Developer/Library/Frameworks/StoreKitTest.framework/StoreKitTest
  Mach-O universal binary with 3 architectures: [x86_64] [arm64] [arm64e]
  ```

- **The previous round's attribution was wrong.** §13.3 blamed "stale
  CoreSimulator / missing Xcode first-launch components". Measured this round:
  the Xcode licence is **accepted** (`xcodebuild -checkFirstLaunchStatus` → 0),
  `CoreSimulatorService` is running from `/Library/Developer/PrivateFrameworks`,
  11 iOS 26.5 simulators exist, and the Runner target builds and hosts the suite
  cleanly. There is nothing left to repair on the host for this path.

### 14.3 Harness changes this round

- `test00_storeKitTestEnvironmentDiagnostic` — records the environment verdict
  (bundle id, config path/existence, session outcome, storefront round-trip,
  resolved product count) and writes it to
  `Documents/cyb48-storekit-diagnostic.txt` inside the app container. XCTest
  swallows `print` into the `.xcresult` and `xcresulttool` will not hand it back,
  so the file is the quotable artifact.
- Corrected the cross-reference in the test header and skip reason
  (`§11.8` → `§13.3`/`§14`).
- The suite must be run with **`-parallel-testing-enabled NO`**: xcodebuild
  otherwise tests on a *cloned* simulator (`Clone 1 of iPhone 17 Pro Max`) and
  deletes it afterwards, taking the diagnostic artifact with it.

### 14.4 Consequence for the acceptance criterion

*"New build uploaded; 2.1(b) not reproducible in sandbox on iOS 27.0"* cannot be
satisfied on this build host. Remaining options, best first:

1. **Sandbox tester + physical device** — the gold standard, but
   `asc sandbox list` is still `total 0` and only the Account Holder can create a
   tester (an App Store Connect write). Owner: **Ryan**.
2. **Mac Catalyst / macOS run of the same assertions** — where the regression
   does not reproduce. Requires a native harness; the Village app has no
   macOS/Catalyst target, so this proves the configuration and the StoreKit 2
   path, not the Flutter paywall.
3. **An Xcode/iOS runtime train where the regression is fixed** — re-run the
   committed suite unchanged; it becomes the proof automatically because it is
   already wired to the scheme's StoreKit configuration.

### 14.5 New store-side fact (extends §12.4)

Live read-only check this round, `asc` 5.5.0:

```
$ asc subscriptions list --app 6803645374
  village.annual   6807153583  state READY_TO_SUBMIT
  village.monthly  6807153048  state READY_TO_SUBMIT
$ asc web review subscriptions list --app 6803645374
  attachedCount 0
  village.annual   6807153583  state MISSING_METADATA  submitWithNextAppStoreVersion false
  village.monthly  6807153048  state MISSING_METADATA  submitWithNextAppStoreVersion false
```

The public API and Apple's own web view **disagree**. On cause: RevenueCat's
App Store troubleshooting codelab states that products with *Missing Metadata*
*"are still available for testing in the sandbox environment and with StoreKit
Configuration files"*, so this is **not** a proven cause of build 6's empty
product list and must not be reported as one. What it *is* is a hard,
command-verified blocker for the next submission: `attachedCount 0` /
`submitWithNextAppStoreVersion false` means neither subscription is attached to
the next app version, which is CYB-49's unwind (release the inflight versions
from submission `4d62cd5b`).

## 15. CYB-31 — iOS 30-day free-trial introductory offers CREATED (2026-10-01)

Closes §7.2. Executed only after the board approval card
(`request_confirmation` `69676df3-b33c-4842-a155-f1a9a585d3fc`) returned
**accepted**. Read-only re-verification immediately before the mutation, two
additive creates, read-back after.

### 15.1 State immediately before the mutation (Mac Mini, asc 5.5.0, read-only)

```
$ asc status --app 6803645374
  appstore  version 1.0.1  state REJECTED
  review    state UNRESOLVED_ISSUES  submission 4d62cd5b…
  builds.latest 1.0.1 (7)  processingState VALID  uploaded 2026-10-01T11:10:25-07:00
$ asc subscriptions list --app 6803645374
  village.monthly  6807153048  READY_TO_SUBMIT  (ONE_MONTH, groupLevel 1)
  village.annual   6807153583  READY_TO_SUBMIT  (ONE_YEAR,  groupLevel 2)
$ asc subscriptions offers introductory list --subscription-id 6807153048  -> meta.paging.total 0
$ asc subscriptions offers introductory list --subscription-id 6807153583  -> meta.paging.total 0
$ asc auth status       -> VillageKey / T8SMTUY74K (default)
$ asc web auth status   -> authenticated  rweekley@gmail.com  team R9U8JNTV28
```

No review in flight (the submission is `UNRESOLVED_ISSUES`), both subscriptions
back to `READY_TO_SUBMIT`, so the §7.2 hard constraint is void and gate
condition 2 (next release cycle — build 7, a new build number) is met.

### 15.2 The mutation — exactly the two approved commands

```bash
asc subscriptions offers introductory create \
  --subscription-id 6807153048 --territory USA \
  --offer-duration ONE_MONTH --offer-mode FREE_TRIAL --number-of-periods 1

asc subscriptions offers introductory create \
  --subscription-id 6807153583 --territory USA \
  --offer-duration ONE_MONTH --offer-mode FREE_TRIAL --number-of-periods 1
```

Both returned exit 0 with a `subscriptionIntroductoryOffers` resource:

```json
{"data":{"type":"subscriptionIntroductoryOffers","id":"<offer-id>",
 "attributes":{"startDate":"2026-10-01","duration":"ONE_MONTH",
 "offerMode":"FREE_TRIAL","numberOfPeriods":1,
 "targetSubscriptionPlanType":"UPFRONT"}}}
```

### 15.3 Read-back evidence (acceptance criterion 1)

```
$ asc subscriptions offers introductory list --subscription-id 6807153048
{"data":[{"type":"subscriptionIntroductoryOffers","attributes":{"startDate":"2026-10-01",
 "duration":"ONE_MONTH","offerMode":"FREE_TRIAL","numberOfPeriods":1,
 "targetSubscriptionPlanType":"UPFRONT"}}],"meta":{"paging":{"total":1,"limit":50}}}

$ asc subscriptions offers introductory list --subscription-id 6807153583
{"data":[{…same shape…}],"meta":{"paging":{"total":1,"limit":50}}}
```

`total` is **1** for each product (was 0). Read directly from
`GET /v1/subscriptions/<id>/introductoryOffers`; unexpired, no end date.

> Tooling note: `asc` renders long resource ids truncated in its JSON output
> (`"eyJzIj...MCJ9"`). That is a display artifact of the CLI — the underlying
> ids are full 76-char strings. Read them from the public API directly if you
> need them verbatim (a stdlib-only ES256 JWT helper is enough; no extra deps).

### 15.4 Offer identity and rollback

Both offer ids are base64url of
`{"s":"<subscription-id>","d":1790838000,"i":"US","t":"","p":"0"}` — i.e.
subscription + US storefront + start date `2026-10-01`:

```
village.monthly  eyJzIjoiNjgwNzE1MzA0OCIsImQiOjE3OTA4MzgwMDAsImkiOiJVUyIsInQiOiIiLCJwIjoiMCJ9
village.annual   eyJzIjoiNjgwNzE1MzU4MyIsImQiOjE3OTA4MzgwMDAsImkiOiJVUyIsInQiOiIiLCJwIjoiMCJ9
```

Rollback (removes the offer; touches nothing else):

```bash
asc subscriptions offers introductory delete --id "<offer-id>" --confirm
```

### 15.5 Territory parity — resolved from live Android, not assumed

Read live from Google Play (`androidpublisher` v3, read-only):

```
monthly-freetrial  ACTIVE  phases[{P1M ×1, regionalConfigs[{US, free{}}]}]
                           otherRegionsConfig{otherRegionsNewSubscriberAvailability:false}
annual-freetrial   ACTIVE  (identical shape)
```

**Android's trial is USA-only.** iOS subscription availability is also USA-only
(1 of the app's 175 territories, §11.3), so parity = **USA only** — there is no
wider set to copy. The approved commands therefore carry `--territory USA`
exactly as written.

### 15.6 Acceptance criterion 3 — paywall copy vs. the delivered StoreKit object

`lib/features/family/pages/subscription_page.dart`:

- L419–423: `'First month free'` / `'Cancel anytime during your trial — you
  won\'t be charged.'`
- L463–468: `'…The free trial is for new subscribers only.'`

A `ONE_MONTH` / `FREE_TRIAL` / 1-period introductory offer **is** "first month
free", and StoreKit grants an introductory offer to new subscribers only.
**Copy and the delivered StoreKit object agree — no code change required.** The
offer is applied by StoreKit automatically at purchase; the app still needs no
code change to receive it.

### 15.7 Ordering constraint for the next submission (unchanged, now unblocked)

These offers had to exist **before** the next app version is submitted: CYB-49
re-attaches both subscriptions *via the app version page*, so a missing offer
would have gone to Apple with the subscriptions. That prerequisite is now
satisfied. Blast radius of this change: two new offer objects — no price,
product, version, submission, localization, image or availability flag was
touched, and nothing was submitted to Apple.

### 15.8 Not done by this issue (deliberate)

- No territory widening of the subscriptions themselves (§11.3, decision owner
  Ryan) — the offers match today's USA-only availability.
- No sandbox purchase proof: `asc sandbox list` still returns **total 0**
  (no sandbox tester), so the offer cannot be exercised end-to-end here.
- The 2.3.2 promotional-image work stays with CYB-49.



## 16. 2026-10-01 (round 3) — the proof RUNS: both reviewer device families, iOS 27.0

Closes the §14 blocker. §14 concluded that "2.1(b) not reproducible in sandbox on
iOS 27.0" could not be satisfied on this build host because the iOS 26.5
simulator could not host a StoreKit test environment. The approved next step was
to install the **iOS 27.0** simulator runtime and re-run the committed suite
unchanged. Done — and the verdict flips.

### 16.1 Host and devices (Mac Mini, Xcode 27.0 `27A266a`, macOS 26.7 `25G229`)

| | |
|---|---|
| Runtime installed | `iOS 27.0 (27.0 - 24A434)`, state `Ready` (8.07 GB, `xcrun simctl runtime list -j`) |
| Reviewer device 1 | `CYB48-iPhone17ProMax` `1DC06248-4D3A-4BD5-8ADE-A2F5367AEE09` — iPhone 17 Pro Max |
| Reviewer device 2 | `CYB48-iPadAir11M3` `DDF84A50-3FA4-4C2E-A37A-8EC2CFFA88B1` — iPad Air 11-inch (M3) |

Both are the two device families Apple's rejection names, on the reviewer's OS
version (27.0), running the **real** app (`app.villagefamily.app` bundle, hosted
XCTest target `RunnerTests`), not a Dart-layer simulation.

### 16.2 The §14 blocker was RUNTIME-specific — §14.1/§14.2 over-generalised

| Runtime | `SKTestSession(contentsOf:)` | storefront round-trip | `Product.products(for:)` |
|---|---|---|---|
| iOS 26.5 (`23F77`) | constructs, **inert** | `FAIL` (echo empty) | 0 of 2 |
| **iOS 27.0 (`24A434`)** | constructs, **live** | **`PASS` (`USA`)** | **2 of 2** |

So the upstream StoreKit regression (RevenueCat `purchases-ios` PR #6897) is
real but is a property of the **iOS 26.5 simulator runtime on Xcode 27.0**, not
of simulators in general — the same Xcode hosts a working StoreKit test
environment on iOS 27.0. §14.1/§14.2 stand as measurements of the 26.5 runtime;
the sentence "an iOS simulator cannot activate a StoreKit test environment on
Xcode 26.4+" is corrected to name that runtime.

### 16.3 Harness defects found and fixed in this round (the reason round 2 measured 0 of 2)

1. **The test session did not outlive the test that created it.** A `SKTestSession`'s
   environment lives only as long as the session object, and XCTest builds a fresh
   `XCTestCase` per test method — so a session held in a local scope (round 2's
   shape) was torn down before the next query reached StoreKit. The session is now
   `static` and created once per process.
2. **Cold start is real, and was being read as a defect.** The first-ever StoreKit
   test session on a device can answer the first product query with an empty list.
   The harness now retries (3 attempts, matching the shipped
   `fetchProductsWithRetry()` in the app) **and** refuses to decide on a device that
   has never completed a run: it reports
   `verdict=FIRST_RUN_ON_DEVICE_INCONCLUSIVE` and skips instead of failing. An empty
   list on a device that *has* run before is the build-6 shape and still **fails**.
3. `tearDown` disables dialogs and clears transactions, so test04's purchase sheet
   cannot leave the test host resident after the suite reports.

### 16.4 Measured results on the reviewer's device families (iOS 27.0)

```
xcodebuild test -workspace ios/Runner.xcworkspace -scheme Runner -configuration Debug \
  -destination 'platform=iOS Simulator,id=<UDID>' -derivedDataPath ~/DerivedData-cyb48 \
  -resultBundlePath ~/cyb48-<tag>.xcresult -parallel-testing-enabled NO \
  -only-testing:RunnerTests/VillageStoreKitTests
```

**iPhone 17 Pro Max — 5/5 passed, `** TEST SUCCEEDED **`**

```
[CYB48-DIAG] sktestsession=OK created=true storefront_echo=USA transactions=0
[CYB48-DIAG] storefront_roundtrip=PASS
[CYB48-DIAG] products_while_session_alive=2 of 2 ids=village.annual,village.monthly
[CYB48-DIAG] products_resolved=2 of 2 ids=village.annual,village.monthly
[CYB48-DIAG] verdict=ENVIRONMENT_LIVE
[CYB48] bundle=app.villagefamily.app storefront=USA resolved=village.monthly [$5.99], village.annual [$49.99]
[CYB48] paywall would render monthly=$5.99 annual=$49.99
[CYB48] purchase OK id=village.monthly date=2026-10-01 20:28:37 +0000 jws=eyJhbG...IkFw…
[CYB48] STOREKIT_SHEET_OPENING id=village.monthly price=$5.99
[CYB48] STOREKIT_SHEET_WAS_ON_SCREEN_FOR_40s
```

**iPad Air 11-inch (M3) — first run `FIRST_RUN_ON_DEVICE_INCONCLUSIVE` (by
design), immediate second run 5/5 passed, `** TEST SUCCEEDED **`**

```
[CYB48-DIAG] device_first_run=false
[CYB48-DIAG] storefront_roundtrip=PASS
[CYB48-DIAG] products_while_session_alive=2 of 2 ids=village.annual,village.monthly
[CYB48-DIAG] verdict=ENVIRONMENT_LIVE
[CYB48] attempt 1/3 resolved=2 ids=village.annual,village.monthly
[CYB48] purchase OK id=village.monthly date=2026-10-01 20:49:48 +0000
[CYB48] STOREKIT_SHEET_WAS_ON_SCREEN_FOR_40s
```

The sheet itself is captured as a PNG on each device and OCR'd so it is quotable
as text rather than "trust the screenshot" (`docs/appstore/cyb48-evidence/`):

```
[ocr] Xcode | Village Monthly | Village | Subscription
[ocr] $5.99 per month | Starting today
[ocr] For testing purposes only. You will not be charged for confirming this purchase.
[ocr] Subscribe
```

That is Apple's **StoreKit purchase sheet** (the `Xcode`-labelled test-environment
sheet), presented for `village.monthly` at the store's own `$5.99` — which is
precisely the interaction the build-6 reviewer could not reach: 2.1(b) is not
reproducible on iOS 27.0 in the sandbox path with build 7's code.

### 16.5 What this proves — and what it still does not

**Proves.** With build 7's `BillingService`, on both reviewer device families on
the reviewer's OS 27.0: both production product IDs resolve to `ProductDetails`,
they carry the store's own prices, a purchase completes, and the StoreKit
purchase sheet is presented. The empty-product-list shape of build 6 does not
occur. The paywall's unloadable-product path is now dead code in practice: an
unresolved product renders a disabled button plus a diagnostic line, never the
build-6 toast over a live button.

**Does not prove (unchanged, and still the one open candidate).** This is the
**StoreKit test environment**, not a live App Store sandbox with a tester
account — `asc sandbox list` is still `total 0` and only the Account Holder can
create one. So the reviewer's real storefront remains unmeasured, and the
USA-only territory availability of both subscriptions (§11.3, Ryan's `keep_usa`)
remains the single store-side asymmetry that could produce an empty list for a
reviewer outside the USA.

### 16.6 Evidence files

- `docs/appstore/cyb48-evidence/iphone17promax-ios27-storekit-sheet.png`
- `docs/appstore/cyb48-evidence/ipadair11m3-ios27-storekit-sheet.png`
- `docs/appstore/cyb48-evidence/iphone17promax-ios27-diagnostic.txt`
- `docs/appstore/cyb48-evidence/ipadair11m3-ios27-diagnostic.txt`
- Run logs and `.xcresult` bundles remain on the Mac Mini as
  `~/cyb48-ios27-test.log` / `~/cyb48-ios27.xcresult` (iPhone) and
  `~/cyb48-ipad27b-run.log` / `~/cyb48-ipad27b.xcresult` (iPad).

### 16.7 Submission posture (unchanged)

Nothing was submitted to Apple by this round. Build 7 stays the current
candidate; the resubmission still waits on CYB-49 (`attachedCount 0` —
neither subscription is attached to the next app version).

## 17. 2026-10-01 — CYB-48 round 4: the rejection is unwound and **build 7 is IN REVIEW**

Ryan's wake comment `still rejected` (2026-10-01T22:55Z) on CYB-48.
Diagnosis before acting: the app was still `REJECTED` for the simplest possible
reason — **nothing had ever been submitted.** Rounds 1–3 ended at "asking for a
decision" while App Store Connect still held the 2026-09-24 submission
`4d62cd5b` in `UNRESOLVED_ISSUES` carrying build 6. The §12.6 sequence had never
been run.

### 17.1 The inflight lock (§12.2) is now actually cleared

`asc review items remove` is refused on a submission that was already submitted:

```
$ asc review items remove --id <subscriptionVersionItemId> --confirm
Error: review items remove: Resource state is invalid.: Item was already submitted
```

Cancelling the dead submission releases its items (the §12.2 alternative):

```
$ asc review submissions-update --id 4d62cd5b-17a5-4e14-bf6f-5b411d4a4b70 --canceled=true --confirm
{"attributes":{"state":"CANCELING", ...}}          # -> COMPLETE
$ asc subscriptions versions list --subscription-id 6807153048
  cabac1de-7482-4fde-9f83-5bd696f3e034  state DEVELOPER_REJECTED   (was READY_FOR_REVIEW)
$ asc subscriptions versions list --subscription-id 6807153583
  38f315ce-5125-4726-8fbd-1d3172aa4532  state DEVELOPER_REJECTED   (was READY_FOR_REVIEW)
```

A `DEVELOPER_REJECTED` subscription version **still counts as inflight** — a
replacement version cannot be created:

```
$ asc subscriptions versions create --subscription-id 6807153048
Error: failed to create: Version already exists.: There is already an inflight
       version with id 'cabac1de-...'
```

The existing version *is* modifiable, which is what the 2.3.2 image fix needs.

### 17.2 2.3.2 fixed — both promotional images replaced

Only one image is allowed per subscription version, so the app-icon image has to
be deleted first:

```
$ asc subscriptions versions images delete --id cbac7921-d737-4f49-a302-dffdaf3e4265 --confirm
  -> {"deleted":true}
$ asc subscriptions versions images upload --version-id cabac1de-... --file docs/appstore/promotional-images/promo-monthly.png
  -> promo-monthly.png 36466  assetDeliveryState COMPLETE
$ asc subscriptions versions images upload --version-id 38f315ce-... --file docs/appstore/promotional-images/promo-annual.png
  -> promo-annual.png  33604  assetDeliveryState UPLOAD_COMPLETE -> COMPLETE
```

Pre-upload verification by decoding the PNG and hashing raw pixels (no image
viewer needed): pixel sha256 `cd12ae3d…` (monthly) and `75ede247…` (annual) —
**exactly** the values §12.3 recorded, and both differ from the app icon
`307a99d7…`. 1024×1024, 8-bit RGB, no alpha, no rounded corners.

### 17.3 Build 7 export compliance set

Build 7 carried no `usesNonExemptEncryption` (§16.5) — the "Missing Compliance"
state that stops a build being selected for a version submission. Answered the
same way as build 6 (standard HTTPS only):

```
$ asc builds update --build-id 335733d2-ced2-4f68-9513-1899557e7e3e --uses-non-exempt-encryption=false
  -> usesNonExemptEncryption false
```

### 17.4 `MISSING_METADATA` is real but NOT blocking — use the API item route

The web attach flow is a dead end on this account, both **before** and **after**
the images were replaced:

```
$ asc web review subscriptions list --app 6803645374
  attachedCount 0
  village.monthly  6807153048  MISSING_METADATA  submitWithNextAppStoreVersion false
  village.annual   6807153583  MISSING_METADATA  submitWithNextAppStoreVersion false
$ asc web review subscriptions attach --app 6803645374 --subscription-id 6807153048 --confirm
Attach preflight: subscription "Village Monthly" (6807153048) is MISSING_METADATA,
so Apple will not attach it to the next app version review yet.
```

…while the public API disagrees and `asc validate subscriptions` returns
**0 errors / 0 blocking** (§12.4's discrepancy, still unexplained). Creating the
draft submission first does not change it either.

The **API item route accepts them without complaint** — which is how the rejected
submission `4d62cd5b` carried them in the first place:

```
$ asc review items add --submission 9f8ed584-... --item-type subscriptionVersions --item-id cabac1de-...
  -> reviewSubmissionItems state READY_FOR_REVIEW        # both products
$ asc review items add --submission 9f8ed584-... --item-type subscriptionGroupVersions --item-id af642536-...
  -> reviewSubmissionItems state READY_FOR_REVIEW
```

So `asc review doctor`'s "first-time subscriptions must be submitted via the app
version page, not the API" is a caution about Apple's *UI*, not an API
enforcement: the item route works and is what §12.6 step 3 actually needed.

### 17.5 SUBMITTED — build 7, new submission `9f8ed584`

```
$ asc versions attach-build --version-id f6ba0c4c-... --build-id 335733d2-...
  -> {"versionId":"f6ba0c4c-...","buildId":"335733d2-...","attached":true}
$ asc versions view --version-id f6ba0c4c-...
  -> versionString 1.0.1  state READY_FOR_REVIEW  buildVersion 7
$ asc review submissions-create --app 6803645374 --platform IOS
  -> 9f8ed584-ac0f-4df8-9432-97e2f3b05a3e
$ asc review submissions-submit --id 9f8ed584-... --confirm
  -> state WAITING_FOR_REVIEW  submittedDate 2026-10-01T23:04:50.439Z
$ asc review doctor --app 6803645374
  -> summary {errors: 0, warnings: 5, blocking: 0}       # was errors:1 blocking:1
$ asc status --app 6803645374
  -> appstore.version 1.0.1  state WAITING_FOR_REVIEW    # was REJECTED
  -> submission {inFlight: true, blockingIssues: []}
  -> summary {health: yellow, nextAction: "Wait for App Store review outcome."}
```

The submission carries all four items, every one `READY_FOR_REVIEW`: two
`subscriptionVersion`s, one `subscriptionGroupVersion`, and one `appStoreVersion`
(build 7). Submission `4d62cd5b` is closed; **build 6 is not resubmitted**.

### 17.6 Still unexplained — and why §11.3 still matters

`MISSING_METADATA` on Apple's own web surface, with every metadata check green on
the API surface, is **not** explained by this round; neither is the original
empty product list. The one measured store-side asymmetry remains §11.3: both
subscriptions are sold in **USA only** while the app is sold in **175
territories**, with `availableInNewTerritories: false`. A client whose storefront
is outside a product's availability gets an **empty product list with no error** —
byte-for-byte the build-6 symptom (Apple TN3186).

`keep_usa` was Ryan's call and was **left as-is** in this round: no App Store
Connect write was made to subscription availability. Widening both products is
the first thing to change if this cycle fails again, and it is the last
unexplained asymmetry standing between this app and an approval.

Build 7 is what makes another failure diagnosable: the paywall now renders the
resolved **storefront**, `notFoundIDs` and the `IAPError` code, and never offers
an unloadable product as purchasable — so a third failure comes back with the
actual storefront rather than a dead-end toast.

## 18. 2026-10-02 — CYB-50 monitor wake 1: build 7 still in review, and the **ASC web session has expired**

Watch issue: CYB-50. Every reading below is read-only, asc 5.5.0 on the Mac Mini.

### 18.1 Outcome — no result yet (2026-10-02T11:1xZ)

```
asc status --app 6803645374
-> appstore.version 1.0.1      state WAITING_FOR_REVIEW
-> submission {inFlight: true, blockingIssues: []}
-> review {latestSubmissionId: 9f8ed584-ac0f-4df8-9432-97e2f3b05a3e,
           state: WAITING_FOR_REVIEW, submittedDate: 2026-10-01T23:04:50.439Z}
-> build 7 (335733d2-ced2-4f68-9513-1899557e7e3e) processingState VALID
```

`asc review history` shows all four submission items `READY_FOR_REVIEW`: two
`subscriptionVersion`s (`cabac1de`, `38f315ce`), one `subscriptionGroupVersion`
(`af642536`), one `appStoreVersion` (build 7). **The subscriptions are attached,
not merely claimed.**

Also re-confirmed live:

- Both introductory offers still present — `ONE_MONTH` / `FREE_TRIAL` /
  1 period / `startDate 2026-10-01` on `6807153048` and `6807153583`.
- `promoted-purchases list --app 6803645374` -> `total: 0`, so the 2.3.2
  promotional-image vector is still clear.
- **Still USA-only**: `subscriptionPlanAvailabilities.availableTerritories
  total: 1` (`USA`) and `availableInNewTerritories: false` on **both**
  products. §11.3 / §17.6 unchanged — still the first lever if this cycle fails.
- `asc review doctor` -> `blocking: 1` = `version.state.editable`
  ("version is in non-editable state WAITING_FOR_REVIEW"). **This is an artifact
  of being in review**, not a regression: `submission.blockingIssues` is `[]`
  and `inFlight` is `true`. Remaining warnings: keywords overlap name+subtitle,
  and `whatsNew` still empty (CYB-28 carry, post-approval action).

### 18.2 NEW RISK — the `asc web` session is dead, so reviewer text is unreadable right now

```
asc web auth status
-> {"authenticated": false, "passwordStored": true,
    "appleId": "rweekley@gmail.com", "developerTeamId": "R9U8JNTV28"}

asc web review show  --app 6803645374 --apple-id rweekley@gmail.com
asc web agreements status --apple-id rweekley@gmail.com
-> "Session expired." / "Error: password is required: run in a terminal for an
    interactive prompt or set ASC_WEB_PASSWORD"
```

The cached session (`~/.asc/web/session-*.json`, last refreshed
2026-10-01T23:09:00Z) has expired — Apple's web cookies live on the order of a
day, and the last human sign-in was 2026-10-01T16:20:41Z.

**A non-interactive re-login was attempted once and failed.** The saved password
is in the login keychain under `asc-web-password` / `asc:web-password:<apple-id>`,
but reading it from a non-GUI SSH session returns `errSecInteractionNotAllowed`
(rc 36) — the login keychain is locked for the SSH security session. **No
credential fixes this**: it is a macOS session-context problem, so
`ASC_WEB_PASSWORD` cannot be sourced either. Re-authentication requires Ryan at
the Mac Mini (double-click `~/Desktop/Apple-Sign-In.command`, which attaches to
the staged `screen` session and runs `~/asc-web-login.sh`).

**Consequence for the watch:** the *outcome* of build 7's review is fully
detectable without a web session (`asc status` / `asc review history` move to a
non-`WAITING_FOR_REVIEW` state). But the **verbatim Resolution Center rejection
text and the reviewer's screenshot are NOT retrievable** while the web session is
dead. If build 7 is rejected, capturing it verbatim needs either (a) a fresh
sign-in before the rejection lands, or (b) a durable alternate channel — Apple
mails every rejection to `rweekley@gmail.com`, and no mail client on this Mac has
an account configured, so that needs a Gmail read-only connection.

### 18.3 Agreement watchdog

`asc web agreements status` **could not be read this wake** (same expired
session). Last known state (2026-10-01, §17-era): Program License Agreement
v5031 `active`, `pending: false`. Its `dateAgreeBy` was 2026-10-01T23:59:59Z —
already passed — and nothing is recorded as reacting to that deadline. **Treat
the agreement state as unverified from 2026-10-02 onward** until a web session
is restored; a new pending agreement silently holds a review.

## 19. 2026-10-02 (wake 2) — build 7 still in review AND still in queue; `asc web` still dark

Watch issue: CYB-50. Every reading below is read-only, asc 5.5.0 on the Mac Mini,
taken 2026-10-02T23:10Z (run `3745d561-caf7-439d-95e6-ab596b747cca`).

### 19.1 Outcome — no result yet, and the *queue* state is the informative part

```
asc status --app 6803645374
-> appstore.version 1.0.1      state WAITING_FOR_REVIEW
-> submission {inFlight: true, blockingIssues: []}
-> review {latestSubmissionId: 9f8ed584-ac0f-4df8-9432-97e2f3b05a3e,
           state: WAITING_FOR_REVIEW, submittedDate: 2026-10-01T23:04:50.439Z}
-> build 7 (335733d2-ced2-4f68-9513-1899557e7e3e) processingState VALID
```

Byte-for-byte §18.1 — and that is the information: ~24 h after submission the
state is still `WAITING_FOR_REVIEW`, not `IN_REVIEW`, i.e. **Apple has not begun
the review yet**. Compare build 6: submitted 2026-09-24T19:29Z, rejected
2026-10-01T17:18Z — ~6.9 days. A 24 h wait is inside the normal band; **it is not
a stall and nothing should be nudged.**

`asc review history` — all four items `READY_FOR_REVIEW`: two
`subscriptionVersion`s (`cabac1de`, `38f315ce`), one `subscriptionGroupVersion`
(`af642536`), one `appStoreVersion` (build 7). Subscriptions genuinely attached.

### 19.2 Re-confirmed live (no writes made)

- Intro offers still present on both products — `ONE_MONTH` / `FREE_TRIAL` /
  1 period / `startDate 2026-10-01` (`6807153048`, `6807153583`).
- `promoted-purchases list --app 6803645374` -> `total: 0` — 2.3.2 vector still clear.
- **Still USA-only** on both products: `subscriptionPlanAvailabilities` ->
  `availableTerritories total: 1` (`USA`), `availableInNewTerritories: false`,
  vs ~175 app territories. §11.3 / §17.6 / §18.1 unchanged — still the first lever
  on a repeat 2.1(b), and **still deliberately not pulled**, because editing IAP
  attached to an in-flight submission can reset the review clock.
- `asc review doctor` -> `blocking: 1` = `version.state.editable` ("version is in
  non-editable state WAITING_FOR_REVIEW") — the in-review artifact, not a
  regression (`submission.blockingIssues` is `[]`, `inFlight` true). Warnings
  unchanged: keyword repeats name + subtitle, `whatsNew` empty (CYB-28 carry,
  post-approval action).

### 19.3 `asc web` is STILL dead 12 h on — plus a partial substitute for the watchdog

```
asc web auth status
-> {"authenticated": false, "passwordStored": true,
    "appleId": "rweekley@gmail.com", "developerTeamId": "R9U8JNTV28"}

asc web review threads --app 6803645374 --apple-id rweekley@gmail.com
-> Session expired.
   Error: password is required: run in a terminal for an interactive prompt
          or set ASC_WEB_PASSWORD
```

Unchanged from §18.2, and **no re-login was attempted this wake**: the single
attempt in §18.2 failed and repeating it risks an Apple sign-in lockout. There is
still no agent-side repair (the keychain is locked for the SSH security session).
The human path is still staged: `~/Desktop/Apple-Sign-In.command` on the Mac Mini
(~60 s, read-only). Reviewer text remains unreadable, and the pending CYB-50 card
`a6b9b5af-3169-4aca-9bb1-ed869e574035` ("Restore reviewer-text access …") is now
12 h old and unanswered.

**Partial substitute for the agreement watchdog — it is not fully dark.** The web
command is unavailable, but a public-API fact covers the review-relevant half:

> Subscriptions cannot be submitted for review at all unless the Paid
> Applications agreement is in effect.

Both `subscriptionVersion`s are attached to submission `9f8ed584` in
`READY_FOR_REVIEW`. **That proves the Paid Applications agreement was in effect at
2026-10-01T23:04:50Z** — no web session required. The residue that only a live
session can see is narrower than §18.3 implied:

  1. a **newly posted** agreement version (its own `dateAgreeBy`) silently holding
     the review, and
  2. a lapse occurring **since** submission (the shortcut only proves "in effect at
     submission", not "in effect now").

Last known: Program License Agreement v5031 `active`, `pending: false`,
`dateAgreeBy` 2026-10-01T23:59:59Z (passed; no recorded reaction).

### 19.4 Monitor re-armed and verified (self-armed, no board action needed)

- `nextCheckAt` **2026-10-03T11:10:00Z** (12 h), `timeoutAt` 2026-10-11T23:59:59Z,
  `maxAttempts` 24, `recoveryPolicy` `escalate_to_board`
- read-back from the same response: `monitorNextCheckAt` non-null ✔,
  `executionState.monitor.status` `scheduled` ✔, `scheduledBy` `assignee` ✔,
  status `in_progress` ✔, `assigneeAgentId` set ✔, `assigneeUserId` null ✔

### 19.5 Operator notes for the next agent (cheap traps, learned live)

- `asc subscriptions plan-availability …` is **not a command** in 5.5.0. Territory
  availability is read with
  `asc subscriptions pricing plan-availability show --subscription-id <ID>`.
  (`asc subscriptions pricing availability view --subscription-id <ID>` is the
  older, deprecated resource; `--subscription-id` on the bare
  `pricing availability` group is rejected with `unknown flag`.)
- `PATCH /api/issues/<id>` `executionPolicy.monitor.notes` is capped at **500
  characters**; longer text is rejected with HTTP 400 `too_big`. The other monitor
  fields (`kind`, `serviceName`, `externalRef`, `nextCheckAt`, `timeoutAt`,
  `maxAttempts`, `recoveryPolicy` …) have their own caps, so build the payload in a
  script and assert lengths before sending.
- The Mac working copy of this repo for the iOS work is
  `/Users/cyberal/projects/village-app-ios` on the Mac Mini (`/Users/cyberal/village-app`
  and `/Users/cyberal/build/village-app` are older trees, not the record).

## 20. 2026-10-03 (wake 3) — build 7 still `WAITING_FOR_REVIEW` ~36 h in, still queued; `asc web` still dark; monitor re-armed

Watch issue: CYB-50. Every reading read-only, `asc` 5.5.0 on the Mac Mini, taken
2026-10-03T11:10Z (run `9b9a6079-8bc5-451c-aa67-cd54f51670f4`). **No write was made
to App Store Connect.**

### 20.1 Outcome — no result yet, and the state is unchanged from §19

```
asc status --app 6803645374
-> appstore.version 1.0.1 (f6ba0c4c-bc37-4ae7-842f-f2273d0cb7d7) state WAITING_FOR_REVIEW
-> submission {inFlight: true, blockingIssues: []}
-> review {latestSubmissionId: 9f8ed584-ac0f-4df8-9432-97e2f3b05a3e,
           state: WAITING_FOR_REVIEW, submittedDate: 2026-10-01T23:04:50.439Z}
-> build 7 (335733d2-ced2-4f68-9513-1899557e7e3e) processingState VALID
-> summary {health: yellow, nextAction: "Wait for App Store review outcome."}
```

~36 h after submission the state is still `WAITING_FOR_REVIEW`, **still not
`IN_REVIEW`** — Apple has not begun the review. Build 6 took ~6.9 days
(2026-09-24T19:29Z -> 2026-10-01T17:18Z); 36 h is well inside the normal band. Not
a stall; nothing was nudged.

`asc review history` — latest submission `9f8ed584`, all four items
`READY_FOR_REVIEW`: 2x `subscriptionVersion` (`cabac1de`, `38f315ce`), one
`subscriptionGroupVersion` (`af642536`), one `appStoreVersion` (build 7). The prior
submission `4d62cd5b` (build 6) is `COMPLETE` with all four items `REMOVED`.

### 20.2 Re-confirmed live (no writes made)

- Intro offers present on both products — `ONE_MONTH` / `FREE_TRIAL` / 1 period /
  `startDate 2026-10-01` (`6807153048`, `6807153583`).
- 2.3.2 vector still clear — `asc subscriptions promoted-purchases view
  --subscription-id <ID>` returns empty `data` (`{"type":"","id":""}`) for both
  products: no promoted purchase linked.
- **Still USA-only** on both products: `subscriptionPlanAvailabilities` ->
  `availableTerritories total: 1` (`USA`), `availableInNewTerritories: false`,
  vs ~175 app territories. Unchanged §11.3 / §17.6 / §18.1 / §19.2 — still the
  first lever on a repeat 2.1(b), and still deliberately **not** pulled, because
  editing IAP attached to an in-flight submission can reset the review clock.
- `asc review doctor` -> `errors 1, warnings 3, infos 1, blocking 1`. The single
  blocking check is `version.state.editable` ("version is in non-editable state
  WAITING_FOR_REVIEW") — the in-review artifact, not a regression
  (`submission.blockingIssues` is `[]`, `inFlight` true). Warnings: keyword repeats
  name, keyword repeats subtitle, `whatsNew` empty (CYB-28 carry, post-approval).
  New coverage warning seen this wake:
  `review.coverage.app_store_regulations_and_permits` `NOT_CHECKED` — the App Store
  Regulations and Permits declarations (incl. the personal-service declaration) are
  web-only and not covered by `review doctor`; they sit behind the same dead session
  (`asc web apps declarations list`).

### 20.3 `asc web` is STILL dead 36 h on — reviewer text and the agreement watchdog remain unreadable

```
asc web auth status
-> {"authenticated": false, "passwordStored": true,
    "appleId": "rweekley@gmail.com", "developerTeamId": "R9U8JNTV28"}

asc web review show --app 6803645374 --apple-id rweekley@gmail.com
-> Session expired.
   Error: password is required: run in a terminal for an interactive prompt
          or set ASC_WEB_PASSWORD
asc web agreements status --apple-id rweekley@gmail.com
-> (identical failure)
```

Unchanged from §18.2 / §19.3, and **no re-login was attempted** (wake 1's single
attempt failed with `errSecInteractionNotAllowed` rc 36; repeating risks an Apple
sign-in lockout). The human path is still staged: `~/Desktop/Apple-Sign-In.command`
on the Mac Mini (~60 s, read-only). The CYB-50 card
`a6b9b5af-3169-4aca-9bb1-ed869e574035` ("Restore reviewer-text access …") is now
**24 h old and unanswered** — deliberately not re-asked, per the no-repeat rule.

The public-API substitute still holds: both `subscriptionVersion`s are attached to
`9f8ed584` in `READY_FOR_REVIEW` -> the Paid Applications agreement was in effect at
2026-10-01T23:04:50Z. Only a live session can still see (a) a newly posted agreement
version holding the review and (b) a lapse since submission. Last known: Program
License Agreement v5031 `active`, `pending: false`, `dateAgreeBy` 2026-10-01T23:59:59Z
(passed; no recorded reaction).

### 20.4 Monitor re-armed and verified (self-armed, no board action needed)

- `nextCheckAt` **2026-10-03T23:10:00Z** (12 h), `timeoutAt` 2026-10-11T23:59:59Z,
  `maxAttempts` 24, `recoveryPolicy` `escalate_to_board`.
- Verified from the read-back: `monitorNextCheckAt` non-null ✔,
  `executionState.monitor.status` `scheduled` ✔, `scheduledBy` `assignee` ✔, status
  `in_progress` ✔, `assigneeAgentId` set ✔, `assigneeUserId` null ✔.
- The monitor had fired before this wake (`attemptCount` 3, `nextCheckAt` null), so
  this PATCH is the re-arm. Re-confirmed live again that `executionPolicy.monitor.notes`
  above 500 characters is rejected with HTTP 400 `too_big` (§19.5).


## 21. 2026-10-03 (wake 4) — build 7 still `WAITING_FOR_REVIEW` ~48 h in, still queued; `asc web` still dark and now proven unreachable from the agent; monitor re-armed

Watch issue: CYB-50. Every reading read-only, `asc` 5.5.0 on the Mac Mini, taken
2026-10-03T23:10Z (run `ea7d11b0-bc4b-40e4-9d47-4e0e22c76ef2`). **No write was made
to App Store Connect.**

### 21.1 Outcome — no result yet; state byte-for-byte §20.1

```
asc status --app 6803645374
-> appstore.version 1.0.1 (f6ba0c4c-bc37-4ae7-842f-f2273d0cb7d7) state WAITING_FOR_REVIEW
-> submission {inFlight: true, blockingIssues: []}
-> review {latestSubmissionId: 9f8ed584-ac0f-4df8-9432-97e2f3b05a3e,
           state: WAITING_FOR_REVIEW, submittedDate: 2026-10-01T23:04:50.439Z}
-> build 7 (335733d2-ced2-4f68-9513-1899557e7e3e) processingState VALID
-> summary {health: yellow, nextAction: "Wait for App Store review outcome."}
```

~48 h after submission the state is still `WAITING_FOR_REVIEW`, **still not
`IN_REVIEW`** — Apple has not begun the review. Build 6 took ~6.9 days
(2026-09-24T19:29Z -> 2026-10-01T17:18Z), so the *predicted* outcome window opens
around 2026-10-08. 48 h is well inside the normal band — not a stall, nothing nudged.

`asc review history` — latest submission `9f8ed584`, all four items
`READY_FOR_REVIEW`: 2x `subscriptionVersion` (`cabac1de`, `38f315ce`), one
`subscriptionGroupVersion` (`af642536`), one `appStoreVersion` (build 7). Prior
submission `4d62cd5b` (build 6) `COMPLETE`, all four items `REMOVED`.

### 21.2 Re-confirmed live (no writes made)

Identical to §20.2 — nothing has moved in 12 h:

- Intro offers present on both products — `ONE_MONTH` / `FREE_TRIAL` / 1 period /
  `startDate 2026-10-01` (`6807153048`, `6807153583`).
- 2.3.2 vector still clear — `asc subscriptions promoted-purchases view
  --subscription-id <ID>` -> `{"data":{"type":"","id":""}}` for both products; no
  promoted purchase linked.
- **Still USA-only** on both products — `subscriptionPlanAvailabilities` ->
  `availableTerritories total: 1` (`USA`), `availableInNewTerritories: false`, vs
  ~175 app territories. Still the first lever on a repeat 2.1(b), still
  deliberately **not** pulled (editing IAP attached to an in-flight submission can
  reset the review clock).
- `asc review doctor` -> `errors 1, warnings 3, infos 1, blocking 1`. The single
  blocking check is `version.state.editable` — the in-review artifact, not a
  regression (`submission.blockingIssues` is `[]`, `inFlight` true). Warnings:
  keyword repeats name, keyword repeats subtitle, `whatsNew` empty (CYB-28 carry).
  Coverage warning `review.coverage.app_store_regulations_and_permits` `NOT_CHECKED`
  persists (web-only declarations, behind the same dead session).

### 21.3 `asc web` is STILL dead ~48 h on — and this wake establishes *why it cannot self-heal*

```
asc web auth status
-> {"authenticated": false, "passwordStored": true,
    "appleId": "rweekley@gmail.com", "developerTeamId": "R9U8JNTV28"}

asc web review threads --app 6803645374 --apple-id rweekley@gmail.com
asc web review show  --app 6803645374 --apple-id rweekley@gmail.com
asc web agreements status --apple-id rweekley@gmail.com
-> Session expired.
   Error: password is required: run in an interactive prompt or set ASC_WEB_PASSWORD
```

No re-login was attempted (wake 1's single attempt failed; repeating risks an Apple
sign-in lockout). This wake instead **measured** the repair surface directly — this
is the new information:

| probe | result |
|---|---|
| saved credential exists? | **yes** — login-keychain item, service `asc-web-password`, acct `asc:web-password:rweekley@gmail.com`, keychain `~/Library/Keychains/login.keychain-db` |
| readable from the agent's SSH session? | **no** — `security find-generic-password ... -w` -> `rc=36`, `show-keychain-info` -> *"User interaction is not allowed."* The login keychain is locked for the SSH security session |
| `sudo` to reach the GUI session? | **no** — `sudo -n true` -> *"a password is required"* |
| GUI session alive? | **yes** — `launchctl print gui/501` -> `type = login` (uid 501) |
| a waiting `screen` login prompt? | **no** — `screen -ls` -> *No Sockets found* |
| session cache | `~/.asc/web/session-0bc7f986….json`, `updated_at 2026-10-01T23:09:00.382746Z` (last good sign-in 2026-10-01) |
| mail fallback (Apple mails every rejection)? | **none configured** — no himalaya/mutt/Mail account on the Mac Mini, no Gmail/IMAP credential anywhere on the WSL box |

Conclusion, stated plainly: **the agent has no path to the reviewer's verbatim text
or the agreement watchdog.** It is not a missing command; it is a locked-credential
boundary that only a human at the Mac Mini (or a mail/IMAP channel) can cross. The
human path stays staged and read-only: `~/Desktop/Apple-Sign-In.command`
(~60 s). The CYB-50 card `a6b9b5af-3169-4aca-9bb1-ed869e574035` ("Restore
reviewer-text access …", `ask_user_questions`, `wake_assignee`) is now **36 h old and
unanswered** — deliberately not re-asked, per the no-repeat rule.

Unchanged public-API substitute: both `subscriptionVersion`s attached to `9f8ed584`
in `READY_FOR_REVIEW` -> the Paid Applications agreement was in effect at
2026-10-01T23:04:50Z. Only a live session can still see (a) a newly posted agreement
version holding the review and (b) a lapse since submission. Last known: Program
License Agreement v5031 `active`, `pending: false`, `dateAgreeBy` 2026-10-01T23:59:59Z
(passed; no recorded reaction).

### 21.4 Monitor re-armed, and the watch window widened to cover the measured review length

- `nextCheckAt` **2026-10-04T11:10:00Z** (12 h cadence), `scheduledBy` `assignee`,
  `kind` `external_service`, `serviceName` "App Store Connect", `externalRef`
  `9f8ed584-ac0f-4df8-9432-97e2f3b05a3e`, `recoveryPolicy` `escalate_to_board`.
- **Changed this wake:** `timeoutAt` **2026-10-11T23:59:59Z -> 2026-10-18T23:59:59Z**
  and `maxAttempts` **24 -> 40**. Rationale: the only measured review length is build
  6's **~6.9 days**, which from the 2026-10-01T23:04Z submission predicts an outcome
  ~2026-10-08 — leaving barely 3 days of margin under the old cap. A monitor that
  expires before Apple answers would re-create exactly the gap CYB-50 exists to
  close. Flagged for the board to dial back if it prefers the earlier escalation.
- Verified from the read-back of the same response: `monitorNextCheckAt` non-null ✔,
  `executionState.monitor.status` `scheduled` ✔, `scheduledBy` `assignee` ✔, status
  `in_progress` ✔, `assigneeAgentId` set ✔, `assigneeUserId` null ✔.
- The monitor had fired before this wake (`attemptCount` 4, `nextCheckAt` null), so
  this PATCH is the re-arm.

### 21.5 Operator notes added this wake

- A locked login keychain under SSH fails **`rc=36` / "User interaction is not
  allowed"** — that, not a missing item, is why `ASC_WEB_PASSWORD` is unsourceable.
  Confirm with `security show-keychain-info ~/Library/Keychains/login.keychain-db`.
- The human sign-in path is a `screen` session (`~/asc-web-login.sh`), so it is
  reattachable: a bare `screen -ls` showing *No Sockets found* means nobody has
  started it yet.
- `~/asc-login-attempts.log` records every sign-in attempt and its rc — check it
  before assuming a human acted. Last entries: three `rc=1` at 2026-10-01T12:16-12:17
  local, then `rc=0` at 2026-10-01T12:20:41 local.

## 22. Monitor wake 5 — 2026-10-04T11:10Z — build 7 still `WAITING_FOR_REVIEW` (~60 h in, still queued); monitor re-armed

Read-only, `asc` 5.5.0 on the Mac Mini. **No write was made to App Store Connect.**

### 22.1 Outcome — no result yet; state unchanged from §21.1

- Submission `9f8ed584-ac0f-4df8-9432-97e2f3b05a3e` `WAITING_FOR_REVIEW`, submitted
  2026-10-01T23:04:50.439Z.
- `appstore.version` 1.0.1 (`f6ba0c4c…`) `WAITING_FOR_REVIEW`; `submission.inFlight
  true`, `blockingIssues []`; build 7 (`335733d2…`) `processingState VALID`.
- `asc review history`: all four items `READY_FOR_REVIEW` — 2× `subscriptionVersion`
  (`cabac1de`, `38f315ce`), `subscriptionGroupVersion` (`af642536`), `appStoreVersion`
  (build 7). Prior submission `4d62cd5b` (build 6) `COMPLETE`, all items `REMOVED`.
- `asc status` `summary.health` **yellow**, `nextAction` "Wait for App Store review outcome."

**~60 h in the state is still `WAITING_FOR_REVIEW`, not `IN_REVIEW`** — Apple has not
begun the review. Build 6 took ~6.9 days (2026-09-24T19:29Z → 2026-10-01T17:18Z), so the
predicted outcome window still opens **~2026-10-08**. Inside the normal band; not a stall;
the in-flight submission was **not** nudged.

### 22.2 Re-confirmed live (no writes made)

- intro offers present on both products (`ONE_MONTH` / `FREE_TRIAL` / 1 period / `startDate 2026-10-01`)
- 2.3.2 vector clear — `asc subscriptions promoted-purchases view --subscription-id <ID>`
  → empty `data` for both
- **still USA-only** on both products (`availableTerritories total: 1` = `USA`,
  `availableInNewTerritories: false`) vs ~175 app territories
- `asc review doctor`: `errors 1`, `warnings 3`, `infos 1`, `blocking 1` — the `blocking 1`
  is `version.state.editable` (`version is in non-editable state "WAITING_FOR_REVIEW"`), the
  **in-review artifact** (`blockingIssues []` + `inFlight true`), not a regression; warnings
  unchanged (keywords repeat name + subtitle; `whatsNew` empty = CYB-28 carry)

### 22.3 `asc web` still dead — reviewer text and agreement watchdog still unreachable

```
asc web auth status -> {"authenticated": false, "passwordStored": true,
                        "appleId": "rweekley@gmail.com", "developerTeamId": "R9U8JNTV28"}
asc web review show / asc web agreements status
-> Session expired. / Error: password is required: run in a terminal for an
   interactive prompt or set ASC_WEB_PASSWORD
```

Unchanged from wakes 1–4 (measured unreachable from the agent in §21.3). **No re-login
attempted** — repeating a failed login risks an Apple sign-in lockout. Human path still
staged: **double-click `~/Desktop/Apple-Sign-In.command` on the Mac Mini (~60 s, read-only)**.
Card `a6b9b5af-3169-4aca-9bb1-ed869e574035` is now **48 h old and unanswered** — not
re-asked, per the no-repeat rule.

**There is no reviewer message to quote verbatim this wake.** If a rejection arrives, the
outcome is detected, and the text will be reported as *not retrievable* rather than guessed.

### 22.4 Monitor re-armed and verified

- `nextCheckAt` **2026-10-04T23:10:00Z** (12 h); `kind` `external_service`; `serviceName`
  "App Store Connect"; `externalRef` `9f8ed584…`; `timeoutAt` 2026-10-18T23:59:59Z;
  `maxAttempts` 40; `recoveryPolicy` `escalate_to_board`.
- read-back from the same response: `monitorNextCheckAt` non-null ✔,
  `executionState.monitor.status` `scheduled` ✔, `scheduledBy` `assignee` ✔, status
  `in_progress` ✔, `assigneeAgentId` set ✔, `assigneeUserId` null ✔.
- the monitor had fired before this wake (`attemptCount` 5, `nextCheckAt` null) → this
  PATCH is the re-arm.

## 23. Monitor wake 6 — 2026-10-04T23:10Z — build 7 still `WAITING_FOR_REVIEW` (~72 h in, still queued); monitor re-armed

Read-only, `asc` 5.5.0 on the Mac Mini. **No write was made to App Store Connect.**

### 23.1 Outcome — no result yet; state unchanged from §22.1

- Submission `9f8ed584-ac0f-4df8-9432-97e2f3b05a3e` `WAITING_FOR_REVIEW`, submitted
  2026-10-01T23:04:50.439Z.
- `appstore.version` 1.0.1 (`f6ba0c4c…`) `WAITING_FOR_REVIEW`; `submission.inFlight
  true`, `blockingIssues []`; build 7 (`335733d2…`) `processingState VALID`.
- `asc review history`: the latest submission `9f8ed584` shows all four items
  `READY_FOR_REVIEW` — 2× `subscriptionVersion` (`cabac1de`, `38f315ce`),
  `subscriptionGroupVersion` (`af642536`), `appStoreVersion` (build 7). Prior submission
  `4d62cd5b` (build 6) `COMPLETE`, all items `REMOVED`.
- `asc status` `summary.health` **yellow**, `nextAction` "Wait for App Store review outcome."

**~72 h in the state is still `WAITING_FOR_REVIEW`, not `IN_REVIEW`** — Apple has not
begun the review. Build 6 took ~6.9 days (2026-09-24T19:29Z → 2026-10-01T17:18Z), so the
predicted outcome window still opens **~2026-10-08**. Inside the normal band; not a stall;
the in-flight submission was **not** nudged.

### 23.2 Re-confirmed live (no writes made)

- intro offers present on both products (`ONE_MONTH` / `FREE_TRIAL` / 1 period / `startDate 2026-10-01`)
- 2.3.2 vector clear — `asc subscriptions promoted-purchases view --subscription-id <ID>`
  → empty `data` for both
- **still USA-only** on both products (`availableTerritories total: 1` = `USA`,
  `availableInNewTerritories: false`) vs ~175 app territories
- `asc review doctor`: `errors 1`, `warnings 3`, `infos 1`, `blocking 1` — the `blocking 1`
  is `version.state.editable` (`version is in non-editable state "WAITING_FOR_REVIEW"`), the
  **in-review artifact** (`blockingIssues []` + `inFlight true`), not a regression; warnings
  unchanged (keywords repeat name + subtitle; `whatsNew` empty = CYB-28 carry). Coverage
  warning unchanged: App Store Regulations/Permits declarations are web-only, not checked by
  `review doctor`.

### 23.3 `asc web` still dead — reviewer text and agreement watchdog still unreachable

```
asc web auth status -> {"authenticated": false, "passwordStored": true,
                        "appleId": "rweekley@gmail.com", "developerTeamId": "R9U8JNTV28"}
asc web review show / asc web agreements status
-> Session expired. / Error: password is required: run in a terminal for an
   interactive prompt or set ASC_WEB_PASSWORD
```

Unchanged from wakes 1–5 (measured unreachable from the agent in §21.3). **No re-login
attempted** — repeating a failed login risks an Apple sign-in lockout. Human path still
staged: **double-click `~/Desktop/Apple-Sign-In.command` on the Mac Mini (~60 s, read-only)**.
Card `a6b9b5af-3169-4aca-9bb1-ed869e574035` is now **~60 h old and unanswered** — not
re-asked, per the no-repeat rule.

**There is no reviewer message to quote verbatim this wake.** If a rejection arrives, the
outcome is detected, and the text will be reported as *not retrievable* rather than guessed.

### 23.4 Monitor re-armed and verified

- `nextCheckAt` **2026-10-05T11:10:00Z** (12 h); `kind` `external_service`; `serviceName`
  "App Store Connect"; `externalRef` `9f8ed584…`; `timeoutAt` 2026-10-18T23:59:59Z;
  `maxAttempts` 40; `recoveryPolicy` `escalate_to_board`.
- read-back from the same response: `monitorNextCheckAt` non-null ✔,
  `executionState.monitor.status` `scheduled` ✔, `scheduledBy` `assignee` ✔, status
  `in_progress` ✔, `assigneeAgentId` set ✔, `assigneeUserId` null ✔.
- the monitor had fired before this wake (`attemptCount` 6, `nextCheckAt` null) → this
  PATCH is the re-arm. `monitor.notes` is capped at 500 chars (HTTP 400 `too_big` if longer).
