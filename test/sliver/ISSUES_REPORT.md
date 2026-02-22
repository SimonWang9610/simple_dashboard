# Issues & Vulnerabilities Report — `lib/src/sliver/`

Generated: 2026-02-22
Test suite: `test/sliver/` — **136 tests, 0 failures**

---

## Summary

| Severity | Count |
|----------|-------|
| High     | 1     |
| Medium   | 5     |
| Low      | 5     |
| Informational | 3 |

---

## HIGH

### H1 — `getMinChildIndexForScrollOffset` Off-by-One When Scrolled Past All Items

**File:** `lib/src/sliver/layout_delegate.dart:154`
**Method:** `SliverDashboardLayout.getMinChildIndexForScrollOffset`

**Description:**
When the scroll offset exceeds the trailing edge of all items, the while-loop exhausts all indices (`index` becomes `items.length`) and the return guard fires:

```dart
return index < items.length ? index : items.length - 1;
```

This returns `items.length - 1` (the last item's index) instead of a sentinel value that signals "no items are visible". As a result, `RenderSliverDashboard.performLayout` calls `computeGeometry(items.length - 1)` and attempts to build/layout the last item even though the viewport is fully scrolled past it.

**Impact:**
- The last item may be laid out and potentially painted when it should be garbage-collected.
- In extreme overscroll scenarios this can cause unnecessary layout work proportional to item count.
- No crash or incorrect rendering in normal usage, but wasted GPU/CPU work on every frame at the end of the scroll.

**Recommendation:**
Return `items.length` (one past the end) as a sentinel, and guard in `performLayout` before calling `computeGeometry`:

```dart
// Option A: return items.length as "no visible item" sentinel
return items.length;

// In performLayout, guard:
if (firstIndex >= dashboardLayout.items.length) {
  geometry = SliverGeometry(scrollExtent: max, ...);
  return;
}
```

---

## MEDIUM

### M1 — `SliverDashboardParentData.id` Field Is Dead Code

**File:** `lib/src/sliver/render.dart:6-9`

**Description:**
`SliverDashboardParentData` declares an `id` field:

```dart
class SliverDashboardParentData extends SliverMultiBoxAdaptorParentData {
  double? crossAxisOffset;
  Object? id;  // ← never set, never read
}
```

`_setupChildParentData` never assigns `childParentData.id`, and no other code reads it. The field is entirely unused.

**Impact:**
- Misleads maintainers into thinking `id` is available for tracking which item a render box belongs to.
- Future code may mistakenly rely on `id` being non-null when it is always `null`.

**Recommendation:**
Either remove the field entirely, or implement it by assigning the item's ID in `_setupChildParentData` (and exposing a way to look up the item from a `RenderBox`).

---

### M2 — `SliverDashboardChildDelegate` and Related Types Not Exported

**File:** `lib/simple_dashboard.dart`, `lib/src/sliver/child_delegate.dart`

**Description:**
The public entry points `SliverDashboard.builder`, `SliverDashboard.list`, `DashboardView.builder`, and `DashboardView.list` all accept or internally create `SliverDashboardChildDelegate`, `SliverDashboardBuilderDelegate`, `SliverDashboardListDelegate`, and `LayoutItemWidgetBuilder`. None of these types are exported from the public package API.

**Impact:**
- Users who call `SliverDashboard()` (default constructor) cannot import `SliverDashboardChildDelegate` to type their variable or create a custom delegate, forcing them to either use the convenience constructors exclusively or import internal `src/` paths.
- Library consumers who need to extend `SliverDashboardChildDelegate` must use `package:simple_dashboard/src/sliver/child_delegate.dart`, which is an unstable internal path.

**Recommendation:**
Export `child_delegate.dart` (or at minimum the abstract base class and the two concrete delegates) from `simple_dashboard.dart`:

```dart
export 'src/sliver/child_delegate.dart';
```

---

### M3 — `Dashboard` Widget Always Builds `emptyBuilder` Regardless of Visibility

**File:** `lib/src/sliver/dashboard.dart:46-56`

**Description:**
The `emptyBuilder` child is eagerly built inside `ListenableBuilder` regardless of whether items are present:

```dart
child: widget.emptyBuilder != null
    ? widget.emptyBuilder!(context)  // ← built every time
    : const SizedBox.shrink(),
```

The widget is then conditionally shown or hidden via `hasItems ? SizedBox.shrink() : child!`. But `child` is still inflated and maintained in the element tree at all times.

**Impact:**
- If `emptyBuilder` creates expensive widgets (e.g., animations, network images), those are built and kept alive even when items are present.
- Minor unnecessary memory usage.

**Recommendation:**
Use conditional building rather than conditional visibility:

```dart
// In ListenableBuilder builder:
if (hasItems) return const SizedBox.shrink();
return widget.emptyBuilder!(context);
```

---

### M4 — `SliverDashboardBuilderDelegate.findIndexByKey` Is an Exact Duplicate of Base Class

**File:** `lib/src/sliver/child_delegate.dart:292-298`

**Description:**
The code comment explicitly notes this is a duplicate:

```dart
// NOTE: This override is identical to the base-class implementation in
// SliverDashboardChildDelegate.findIndexByKey and can be removed.
@override
int? findIndexByKey(Key key) { ... }
```

**Impact:**
- Dead code: any future bug fix in the base class method would need to be replicated here manually.
- Maintenance burden and confusion for contributors.

**Recommendation:**
Remove the override from `SliverDashboardBuilderDelegate` entirely, relying on the base class implementation.

---

### M5 — `PositionStrategy.after` with Missing `afterId` Silently Falls Back to `append`

**File:** `lib/src/sliver/controller.dart:44-50`, `lib/src/classes/layout_positioner.dart:209-218`

**Description:**
When `PositionStrategy.after` is used with an `afterId` that does not exist in the items list, the positioner silently falls back to appending the item at the end. There is no warning, assertion, or error.

```dart
if (after == null && append) {
  // silently appends — caller gets no feedback
  return appendPositioner.position(id, size);
}
```

**Impact:**
- Callers who pass a stale or misspelled `afterId` get unexpected item ordering with no diagnostic.
- Difficult to debug because the fallback behavior looks identical to an intentional append.

**Recommendation:**
Add a `debugPrint` warning (at minimum) or an optional strict mode that asserts `afterId != null && after != null`:

```dart
assert(
  afterId == null || after != null,
  'DashboardAfterPositioner: no item found with id "$afterId"; falling back to append.',
);
```

---

## LOW

### L1 — `DashboardController` Items List Mutation Throws `UnsupportedError` with No Context

**File:** `lib/src/sliver/controller.dart:196`

**Description:**
`_items` is stored as `List.unmodifiable(items)`. Attempting to mutate it throws `UnsupportedError: Cannot add to an unmodifiable list`. The error message does not mention `DashboardController.add()` or `DashboardController.remove()` as the intended mutation API.

**Recommendation:**
Document in `DashboardController.items`'s getter doc comment that the list is unmodifiable and mutations must go through `add()`/`remove()`.

---

### L2 — `itemKeyForIndex` Is Documented as "Library-Private" but Is a Public Method

**File:** `lib/src/sliver/child_delegate.dart:203`

**Description:**
The doc comment warns:

> **Warning:** This is a library-private method. Subclasses in other files cannot override it.

However, `itemKeyForIndex` is a standard public method on `SliverDashboardChildDelegate`. External subclasses can override it; they just cannot create `_ItemKey` instances (since `_ItemKey` is truly library-private). The documentation is misleading.

**Recommendation:**
Clarify the documentation: the method is public and overridable, but custom keys cannot be `_ItemKey` instances unless the subclass is in the same library file.

---

### L3 — `SliverDashboardLayout.computeMaxScrollOffset` Uses `maxCrossDashboardAxisSlots` from Constructor, Not Recomputed from `items`

**File:** `lib/src/sliver/layout_delegate.dart:184-193`

**Description:**
`computeMaxScrollOffset` uses `maxCrossDashboardAxisSlots` that is passed to the constructor:

```dart
return maxCrossDashboardAxisSlots * crossDashboardAxisStride - crossDashboardAxisSpacing;
```

`SliverDashboardDelegateWithFixedSlotCount.getLayout` computes `maxCrossAxisSlots` by iterating items and passes it. If someone constructs `SliverDashboardLayout` directly with a wrong `maxCrossDashboardAxisSlots`, the scroll extent will be incorrect. The constructor has no validation that `maxCrossDashboardAxisSlots` matches `items`.

**Recommendation:**
Either validate that `maxCrossDashboardAxisSlots` is consistent with `items` in the constructor, or compute it internally from `items`.

---

### L4 — `DashboardController.remove` Assert Fires on Internal Consistency Only (Not User-Facing)

**File:** `lib/src/sliver/controller.dart:70-75`

**Description:**
```dart
assert(
  newItems.length == items.length - 1,
  "Exactly one item should be removed.",
);
```
This assert is an internal sanity check (the `where` filter on unique IDs guarantees it). In release mode it is stripped. If `items` somehow contained duplicate IDs (which should be impossible, but see the `LayoutChecker` which uses asserts-only checks), the assert would fire in debug, but in release mode a silent data corruption occurs.

**Recommendation:**
Consider replacing with a concrete check or ensuring the `LayoutChecker.assertNoDuplicatedIds` guard runs unconditionally (not only inside `assert`).

---

### L5 — `SliverDashboardLayout` Constructor Takes `items` but Does Not Sort or Validate Them

**File:** `lib/src/sliver/layout_delegate.dart:102-120`

**Description:**
`SliverDashboardLayout` receives `items` and uses them in `getMinChildIndexForScrollOffset` / `getMaxChildIndexForScrollOffset` assuming they are sorted (items are iterated in order to find visibility boundaries). If items are passed unsorted, the visibility calculations return incorrect indices. There is no assertion or sort step.

**Recommendation:**
Assert that items are sorted (using `DashboardHelper.assertSorted`) in a debug-mode assertion inside the `SliverDashboardLayout` constructor, or sort internally.

---

## INFORMATIONAL

### I1 — `oldMainAxisSlots` Parameter in `DashboardHelper.adoptMetrics` Is Unused

**File:** `lib/src/utils/helper.dart:93-98`
(Also documented in `test/dashboard_helper_test.dart:574`)

**Description:**
`adoptMetrics` accepts `oldMainAxisSlots` but never reads it. The parameter exists in the public API and its doc comment describes intended optimization behavior, but the implementation ignores it. The existing test suite documents this as known behavior.

**Recommendation:**
Either implement the intended optimization (skip repositioning when `mainAxisSlots` increased), or remove the parameter from the public signature to avoid misleading callers.

---

### I2 — `SliverDashboardChildDelegate.shouldRebuild` Always Returns `true`

**File:** `lib/src/sliver/child_delegate.dart:119-120`

**Description:**
The base class default:

```dart
@override
bool shouldRebuild(covariant SliverDashboardChildDelegate oldDelegate) => true;
```

Neither concrete subclass (`SliverDashboardBuilderDelegate`, `SliverDashboardListDelegate`) overrides this. Every rebuild causes the sliver to re-layout all children, even when items have not changed.

**Recommendation:**
Override `shouldRebuild` in both concrete delegates to compare their fields and return `false` when nothing has changed. For `SliverDashboardBuilderDelegate`, compare `childCount`, `findItemByIndex`, `builder`, and the wrapping flags.

---

### I3 — `LayoutChecker.assertNoDuplicatedIds` Has Inconsistent Nullability Semantics

**File:** `lib/src/utils/checker.dart:61-74`

**Description:**
`assertNoDuplicatedIds` returns `bool` but only performs the check inside an `assert()` block:

```dart
static bool assertNoDuplicatedIds(Iterable<LayoutItem> items) {
  bool hasDuplicates = false;
  assert(() {
    final ids = items.map((item) => item.id).toSet();
    hasDuplicates = ids.length != items.length;
    return true;  // assert always passes
  }());
  return !hasDuplicates;  // always true in release mode
}
```

In release mode this always returns `true` regardless of whether duplicates exist. Code that calls `assertNoDuplicatedIds` expecting a real runtime check (e.g., `DashboardHelper.adoptMetrics`) receives a useless value in production.

**Recommendation:**
Either rename to `debugAssertNoDuplicatedIds` (to signal debug-only semantics), or move the duplicate-ID check outside the `assert` block so it runs in both debug and release mode.

---

## Test Coverage Summary

| File | Tests | Areas Covered |
|------|-------|---------------|
| `test/sliver/controller_test.dart` | 38 | Factory ctor, items setter, add (4 strategies), remove, axis setter, mainAxisSlots setter, sortedItems cache, dispose |
| `test/sliver/layout_delegate_test.dart` | 43 | Strides, computeMaxScrollOffset, computeGeometry, computeItemGeometry, getMin/MaxChildIndexForScrollOffset, SliverDashboardGeometry, BoxItemGeometry, shouldRelayout, getLayout |
| `test/sliver/child_delegate_test.dart` | 33 | BuilderDelegate (.items & base), ListDelegate, key round-trips, build() wrapping (RepaintBoundary, AutomaticKeepAlive, IndexedSemantics), error widget |
| `test/sliver/dashboard_widget_test.dart` | 22 | Dashboard empty/loading/controller-integration, DashboardView.builder/list/default, SliverDashboard inside CustomScrollView |
| **Total** | **136** | **All pass** |
