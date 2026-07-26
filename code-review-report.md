# Village App — Flutter/Dart Code Review Report

**Date:** 2026-07-24  
**Files Reviewed:** 36 `.dart` files under `lib/`  
**Project:** `village-app` (Flutter + Riverpod + GoRouter + Dio)

---

## Severity 1 — 🔴 CRITICAL (6 issues)

### C1. Fire-and-Forget API Mutations — No Error Handling (9 locations)

API calls that mutate state (create, delete, toggle, complete, submit, grade) are fired with no `try/catch`, no loading spinner, and no error feedback to the user. A network failure silently does nothing while the UI acts as if it succeeded.

| File | Line(s) | Call |
|---|---|---|
| `shopping/pages/shopping_lists_page.dart` | 84–86 | `deleteList(list.id)` |
| `shopping/pages/shopping_lists_page.dart` | 126–128 | `createList(nameCtrl.text)` |
| `shopping/pages/shopping_lists_page.dart` | 314 | `toggleItem(...)` |
| `shopping/pages/shopping_lists_page.dart` | 344–347 | `deleteItem(...)` |
| `chores/pages/chores_page.dart` | 116 | `createChore(...)` |
| `chores/pages/chores_page.dart` | 303 | `assignChore(...)` |
| `chores/pages/chores_page.dart` | 366 | `completeChore(...)` |
| `chores/pages/chores_page.dart` | 434, 442 | `approveCompletion(...)` |
| `school/pages/school_page.dart` | 331 | `createSchoolWork(...)` |
| `rewards/pages/rewards_page.dart` | 107, 170, 222–229 | `createReward`, `redeemReward`, `approveRedemption` |

**Fix:** Wrap every mutation in `try/catch` and show a `SnackBar` on failure. Consider `AsyncValue` for the mutation state (e.g., `AsyncNotifierProvider`) to handle loading/error states uniformly.

**Positive counter-example:** `auth_provider.dart` lines 78–131 wrap `register`/`login` in `try/catch` and surface errors via `state.error`.

---

### C2. No Provider Invalidation After Mutations (9 locations)

After mutating API calls, the corresponding `FutureProvider` is **never** invalidated. The UI remains stale until the user pull-to-refreshes or re-navigates.

| File | Line | Mutation | Should invalidate |
|---|---|---|---|
| `shopping/pages/shopping_lists_page.dart` | 84 | `deleteList` | `shoppingListsProvider` |
| `shopping/pages/shopping_lists_page.dart` | 126 | `createList` | `shoppingListsProvider` |
| `shopping/pages/shopping_lists_page.dart` | 314 | `toggleItem` | `shoppingListDetailProvider(listId)` |
| `shopping/pages/shopping_lists_page.dart` | 344 | `deleteItem` | `shoppingListDetailProvider(listId)` |
| `chores/pages/chores_page.dart` | 116 | `createChore` | `choresListProvider` |
| `chores/pages/chores_page.dart` | 303 | `assignChore` | `assignmentsListProvider` |
| `chores/pages/chores_page.dart` | 366 | `completeChore` | `assignmentsListProvider` |
| `chores/pages/chores_page.dart` | 434, 442 | `approveCompletion` | `assignmentsListProvider` |
| `school/pages/school_page.dart` | 331, 657, 787 | create/submit/grade | `schoolWorkListProvider` |
| `rewards/pages/rewards_page.dart` | 107, 170, 222–229 | create/redeem/approve | `rewardsListProvider`, `redemptionsListProvider` |

**Positive counter-example:** `meals_page.dart` line 726 calls `ref.invalidate(recipesListProvider)` after creating a recipe.

**Fix:** After every successful mutation, call `ref.invalidate(shoppingListsProvider)` (or the relevant provider) to trigger a fresh fetch.

---

### C3. JWT Token Stored in SharedPreferences (Plain Text)

**File:** `core/auth/auth_service.dart`, lines 32, 45, 59, 62, 67  
**Severity:** Critical — security

The JWT token is read/written via `SharedPreferences` (`_prefs.setString('jwt_token', ...)`). On Android, `SharedPreferences` stores values in an unencrypted XML file accessible to any process on a rooted device and readable via ADB backups.

**Fix:** Replace `SharedPreferences` with `flutter_secure_storage` (which uses encrypted storage: EncryptedSharedPreferences on Android, Keychain on iOS). Auth service is the only consumer — the swap is localized.

---

### C4. Auth Service Uses AuthenticatedDio for Login/Register

**File:** `core/auth/auth_service.dart`, line 72  
`core/network/authenticated_client.dart`, lines 12–18

`AuthService` uses the same `authenticatedDioProvider` that attaches a `Bearer` token **from a previous session** to every request. This means:

- `POST /api/auth/login` is sent with an old JWT in the `Authorization` header from a prior session (or stale token).
- `POST /api/auth/register` is sent the same way.

While the server may ignore the header on auth endpoints, this is architecturally incorrect and could cause issues if the server validates tokens on every endpoint. It also means the Dio interceptor chain is polluted for auth endpoints.

**Fix:** Create a separate `plainDioProvider` (or use `dioProvider` directly, which has no auth interceptor) for auth endpoints. Only use `authenticatedDioProvider` for authenticated API calls.

---

### C5. Token Cleared on Every 401 Without Race Protection

**File:** `core/network/authenticated_client.dart`, lines 21–24

When any request returns 401, the interceptor immediately calls `prefs.remove('jwt_token')`. If two concurrent requests both get 401, the first clears the token and the second also clears it (no-op). But the logout logic in `auth_provider.dart` line 63 (`logout()` → `prefs.remove('jwt_token')`) also races with this interceptor.

There is **no concurrency lock** (mutex / semaphore) preventing a token refresh race condition. The `onError` handler clears the token unconditionally — it does not attempt a token refresh before clearing.

**Fix:** Implement a 401 retry with a concurrency lock (`Completer<bool>` pattern): on first 401, attempt a refresh. Subsequent 401s while refresh is in-flight should await the same refresh result. Only clear the token if refresh fails.

---

### C6. Family Setup — Join Flow is a Dead Stub

**File:** `features/family/pages/family_setup_page.dart`, lines 297–308

The "Join Family" branch of `family_setup_page.dart` is completely dead code. It shows a `SnackBar` with `"Joining is handled during registration for now."` and immediately calls `Navigator.pop(ctx)`. No API call is ever made. The user can fill in 3 form fields and click "Join" — nothing happens.

**Fix:** Either implement the join-family API endpoint and wire it up, or remove the "Join Family" tab entirely to avoid UI dead ends.

---

## Severity 2 — 🟠 WARNING (10 issues)

### W1. Single-File Conflation Anti-pattern (5 features)

Five feature files conflate model definitions, API service class, **and** Riverpod providers in a single file:

| File | Lines | Conflated concerns |
|---|---|---|
| `chores/chores_service.dart` | 197 | 3 models + `ChoresService` + 2 providers |
| `shopping/shopping_service.dart` | 177 | 3 models + `ShoppingService` + 1 provider |
| `calendar/calendar_service.dart` | ~150 | 2 models + `CalendarService` + providers |
| `school/school_service.dart` | ~180 | 2 models + `SchoolService` + 4 providers |
| `meals/meals_service.dart` | 363 | 3 models + `MealsService` + 4 providers |

**Positive reference:** `notification_service.dart` (232 lines) cleanly separates `AppNotification` (model), `NotificationApiService` (API class), and `NotificationNotifier/NotificationState` (Notifier + State). This is the correct pattern to follow.

**Fix:** Split each file into:
- `models/<feature>_models.dart` — data classes + JSON serialization
- `api/<feature>_service.dart` — API calls via Dio
- `providers/<feature>_providers.dart` — Riverpod providers

---

### W2. Inline Provider Definition in Page File

**File:** `shopping/pages/shopping_lists_page.dart`, lines 356–359

```dart
final shoppingListDetailProvider =
    FutureProvider.family<ShoppingListDetail, String>((ref, listId) {
  return ref.watch(shoppingServiceProvider).getList(listId);
});
```

A `FutureProvider.family` is defined at the **bottom of a page file**, where it cannot be shared with other consumers or used by the parent shopping lists page. This hides the provider from the rest of the app and encourages duplication.

**Fix:** Move `shoppingListDetailProvider` to `shopping_service.dart` alongside the existing `shoppingListsProvider`.

---

### W3. Raw Exception Text Shown to Users (6 locations)

Users see raw `DioException` messages or `$e` in the UI:

| File | Line(s) | Code |
|---|---|---|
| `rewards/pages/rewards_page.dart` | 135, 194 | `Text('Error: $e')` |
| `chores/pages/chores_page.dart` | 145 | `Text('Error: $e')` |
| `shopping/pages/shopping_lists_page.dart` | 172 | `Text('Error: $e')` |
| `school/pages/school_page.dart` | 566 | `Text('Error: $e')` |
| `meals/pages/meals_page.dart` | 552, 746 | `Text('Error: $e')` |
| `calendar/pages/calendar_page.dart` | ~95 | `Text('Error: $e')` |

This leaks internal error details (stack traces, API URL paths, internal server errors) to end users and provides no actionable guidance.

**Fix:** Map exceptions to user-friendly strings (e.g., "Something went wrong. Please try again.") and log the full error for debugging. Consider `ref.onError` or a centralized error handler.

---

### W4. GoRouter Bypassed for Shopping Detail Navigation

**File:** `shopping/pages/shopping_lists_page.dart`, lines 91–97

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ShoppingListDetailPage(listId: list.id),
  ),
);
```

The shopping list detail page is pushed via `Navigator.push` instead of `context.go('/shopping/${list.id}')`. This:
- Breaks URL-based deep linking
- Skips GoRouter's redirect/guard middleware
- Prevents browser back-button integration on web
- Makes the route invisible to any auth guard state transitions

**Fix:** Register a `/shopping/:id` route in `app_router.dart` and navigate with `context.go('/shopping/${list.id}')`.

---

### W5. ShoppingListDetailPage — Not Reviewed for Error States

The `ShoppingListDetailPage` (pushed via Navigator, not GoRouter) was not fully reviewed. The inline `shoppingListDetailProvider` at line 356 uses `.when()` but with no retry on error — if the API call fails, the detail page shows a static error with no retry button.

**Fix:** Ensure `shoppingListDetailProvider.when()` has a proper error state with a retry button matching other pages' patterns.

---

### W6. Duplicate Color Parsing Logic in School Page

**File:** `school/pages/school_page.dart`

Two nearly identical methods exist for parsing subject colors:

- Lines 352–405: `_parseSubjectColor(String? color)` in `_SchoolPageState`
- Lines 492–546: `_subjectColor(String? color)` in `_SubjectsTab`

Both do the same `switch` on color name → `Color` mapping. Code is duplicated across two classes.

**Fix:** Extract a shared helper function (e.g., `SubjectColor.fromName(String? name)`) in a utility file or the subject model.

---

### W7. No Loading/Auth State on `tryAutoLogin()` Startup

**File:** `core/router/app_router.dart`, line 25

`initialLocation: '/login'` means the login screen flashes briefly before the auth redirect guard kicks in. The guard correctly returns `null` when `isUnknown` is true, meaning the router **stays at `/login`** until `tryAutoLogin()` resolves. An authenticated returning user sees:

1. `/login` renders (100–500ms flash)
2. Auth resolves → `router.refresh()` → redirect to `/hub`

**Fix:** Use a splash/loading route as `initialLocation` that shows a branded splash screen while auth resolves. Only redirect to login once auth confirms unauthenticated. Optionally set `initialLocation: '/splash'` with a no-op redirect that waits for auth.

---

### W8. `ShoppingItem.isChecked` is a Public Mutable Field

**File:** `shopping/shopping_service.dart`, line 41

```dart
class ShoppingItem {
  ...
  bool isChecked;  // public, mutable
```

`isChecked` is a non-`final` public field. Since it's consumed via `FutureProvider`, mutating it in local state won't trigger a UI rebuild. If any code mutates `item.isChecked = true` directly (rather than calling `toggleItem` API), the UI will silently diverge from server state.

**Fix:** Make `isChecked` `final` and rely on the API + provider invalidation for state updates.

---

### W9. Family Member Management — Promote/Remove are TODO Stubs

**File:** `features/family/pages/family_page.dart`, line 356

```dart
// TODO: implement role change / remove member
```

The `PopupMenuButton` on each member tile shows "Promote to Admin" / "Remove from Family" options, but both are non-functional stubs. The user taps them and nothing happens (the menu simply closes).

**Fix:** Implement the API calls for role change and member removal, or hide the options with a feature flag.

---

### W10. Calendar Page — No RefreshIndicator

**File:** `features/calendar/pages/calendar_page.dart`

The calendar page uses `FutureProvider` for events but has no `RefreshIndicator` wrapping its content. Users cannot pull-to-refresh to see updated events.

**Fix:** Wrap the calendar content in `RefreshIndicator` calling `ref.refresh(calendarEventsProvider(...).future)`.

---

## Severity 3 — 🔵 SUGGESTION (10 issues)

### S1. Missing `.autoDispose` on All FutureProviders

None of the `FutureProvider` declarations use `.autoDispose`:

- `shoppingListsProvider`
- `choresListProvider`, `assignmentsListProvider`
- `schoolWorkListProvider`, `subjectsProvider`
- `recipesListProvider`, `mealPlansListProvider`
- `rewardsListProvider`, `redemptionsListProvider`

Without `autoDispose`, these providers hold stale fetch results in memory indefinitely, even after the user navigates away from the page. They never re-evaluate unless explicitly invalidated.

**Fix:** Change all to `FutureProvider.autoDispose` (or `.autoDispose.family` for parameterized ones). This ensures cached data is released when no page is watching.

---

### S2. Chores Assignments Tab — Boring Empty State

**File:** `chores/pages/chores_page.dart`, line 344

```dart
Text('No assignments yet.')
```

No icon, no guiding text, no suggestion of what to do next. Contrast with the Rewards page which has a nice `Icons.card_giftcard` + "No rewards yet. Tap + to create one.".

**Fix:** Add an icon and encouraging text (e.g., "No chores assigned. Ask a parent to assign one!").

---

### S3. Notifications `loadMore` — No Error State

**File:** `features/notifications/pages/notifications_page.dart`, line 88–90

The infinite scroll triggers `loadMore()` but the `NotificationNotifier` at line 192–199 swallows errors silently (`try/catch` with no state update on failure). The user never sees a "Failed to load more" indicator.

**Fix:** Add an `error` field to `NotificationState` and surface it in the UI (e.g., showing a retry button at the bottom of the list).

---

### S4. Login Redirect After Auth Uses `context.go` Instead of `context.replace`

**File:** `features/auth/pages/login_page.dart`, line 38

```dart
if (mounted) context.go('/hub');
```

Using `context.go` instead of `context.replace` means the login page stays in the navigation stack. The user can press back and briefly see the login page again before the redirect guard pushes them away.

**Fix:** Use `context.go('/hub')` is actually fine if using ShellRoute. But for auth-route transitions, `context.replace('/hub')` is preferred to remove the login page from history.

---

### S5. Rewards Page — No Provider Invalidation After Redemption

**File:** `rewards/pages/rewards_page.dart`, lines 170–172

```dart
ref.read(rewardsServiceProvider).redeemReward(reward.id);
```

Fire-and-forget with no invalidation of `rewardsListProvider` or `redemptionsListProvider`. After redeeming, neither the available rewards list nor the redemptions list updates.

**Fix:** Add `try/catch` and `ref.invalidate(rewardsListProvider)` + `ref.invalidate(redemptionsListProvider)` after successful redemption.

---

### S6. Mixed `withOpacity` and `withValues` API Usage

Some files use the modern `withValues(alpha: ...)` API (e.g., `family_page.dart` line 85), while others still use the deprecated `withOpacity(...)`. This creates maintenance inconsistency as the deprecated API may be removed in future Flutter versions.

**Fix:** Audit and migrate all `withOpacity` calls to `withValues(alpha: ...)`.

---

### S7. Chores Page — No Loading State on Create/Assign Dialogs

**File:** `chores/pages/chores_page.dart`

When the user taps "Create" in the new-chore dialog, the dialog closes immediately via `Navigator.pop` and the API call fires in the background. If the API is slow or fails, the user gets no feedback. Same for "Assign" and "Complete" dialogs.

**Fix:** Show a loading indicator within the dialog while the API call is in flight, and only close the dialog on success.

---

### S8. Meals Page — Create Recipe Only Invalidates `recipesListProvider`, Misses `familyFavoritesListProvider`

**File:** `meals/pages/meals_page.dart`, line 726

```dart
ref.invalidate(recipesListProvider);
```

If the recipe was created with `isFamilyFavorite: true`, the `familyFavoritesListProvider` is not invalidated, so the Favorites tab won't reflect the new recipe.

**Fix:** Also invalidate `familyFavoritesListProvider` after creating a family-favorite recipe.

---

### S9. School Page — SnackBar Context May Be Invalid After Dialog Dismiss

**File:** `school/pages/school_page.dart`, line 778

```dart
ScaffoldMessenger.of(context).showSnackBar(...);
```

Inside a dialog's `onPressed`, `context` refers to the outer widget's context, not the dialog's context. After the dialog dismisses (`Navigator.pop(ctx)`), the outer `context` may not have a `ScaffoldMessenger` ancestor, leading to a runtime error.

**Fix:** Use `ctx` (the dialog context) instead, or capture `ScaffoldMessenger.of(context)` before the dialog closes and store in a local variable.

---

### S10. Missing Points History and Profile Pages

**File:** Not present — these features are referenced in routes but no pages exist

The `app_router.dart` references `/points` and `/profile` in the HubPage's `build` method, but no corresponding pages or route definitions exist. The user sees no-op navigation (or worse, a 404).

**Fix:** Either implement the pages or remove the navigation targets.

---

## Positive Patterns & Reference Code

The following areas are well-structured and serve as patterns to follow:

| Pattern | File | Why it's good |
|---|---|---|
| Proper separation of concerns | `notification_service.dart` | Models, API service, and NotifierState are in 3 separate sections; clear responsibility boundaries |
| State error handling | `auth_provider.dart` | `try/catch` with `state.error` propagation; `DioException` parsing into user-friendly messages |
| Provider invalidation after mutation | `meals_page.dart` line 726 | `ref.invalidate(recipesListProvider)` after `createRecipe` — the only page that does this |
| Scoped caching with `.family` | `calendar_service.dart`, `meals_service.dart` | `FutureProvider.family` with date range / week-start keys minimizes redundant fetches |
| Pagination with Notifier | `notification_service.dart` `NotificationNotifier` | `loadMore()` with offset tracking; clean state management for infinite scroll |
| Pull-to-refresh | `school_page.dart`, `rewards_page.dart`, `chores_page.dart` | `RefreshIndicator` with provider refresh gives users a manual escape hatch from stale data |
| Empty states with icons | `notifications_page.dart`, `rewards_page.dart` | Icons + hint text instead of bare "No items" messages |

---

## Summary Statistics

| Metric | Count |
|---|---|
| **Critical issues** | 6 |
| **Warning issues** | 10 |
| **Suggestions** | 10 |
| **Total files reviewed** | 36 |
| **Total code lines** | ~12,500 |
| **Files with fire-and-forget mutations** | 5 |
| **Features conflating models/service/providers** | 5 |
| **Pages using raw `Text('Error: $e')`** | 5 |
| **Pages with no post-mutation invalidation** | 4 |
