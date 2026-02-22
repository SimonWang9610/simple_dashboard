import 'package:flutter/widgets.dart';
import 'package:simple_dashboard/simple_dashboard.dart';

/// Returns the [LayoutItem] at the given [index], or `null` if the index is
/// out of range.
typedef LayoutItemFinder = LayoutItem? Function(int index);

/// Returns the list index of the item with [itemId], or `null` if no such item
/// exists in the list.
typedef LayoutItemIndexFinder = int? Function(Object itemId);

/// Builds a [Widget] for the given [LayoutItem].
///
/// Called by [SliverDashboardBuilderDelegate] for each visible item during
/// layout. The [item] carries both the layout geometry and the application-
/// defined identifier that can be used to look up domain data.
typedef LayoutItemWidgetBuilder =
    Widget Function(BuildContext context, LayoutItem item);

int _kDefaultSemanticIndexCallback(Widget _, int localIndex) => localIndex;

/// Internal key type that ties a rendered child back to its [LayoutItem.id].
///
/// Used by [SliverDashboardChildDelegate.findIndexByKey] to map a Flutter [Key]
/// back to a list index when the framework needs to reuse or relocate an
/// existing element (e.g. after a scroll).
///
/// Stores the stable [itemId] via the [ValueKey] super-class.
class _ItemKey extends ValueKey<Object> {
  final Object itemId;
  const _ItemKey(this.itemId) : super(itemId);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is _ItemKey && other.itemId == itemId;
  }

  @override
  int get hashCode => itemId.hashCode;
}

/// Base class for delegates that supply children to a [SliverDashboard].
///
/// A [SliverDashboardChildDelegate] is responsible for:
/// - Building child widgets on demand via [buildItemWidget].
/// - Wrapping each child in optional accessibility, performance, and keep-alive
///   infrastructure ([addRepaintBoundaries], [addSemanticIndexes],
///   [addAutomaticKeepAlives]).
/// - Providing stable [Key]s for element reuse via [_itemKeyForIndex].
/// - Mapping framework [Key]s back to list indices via [findIndexByKey].
///
/// Two concrete implementations are provided:
/// - [SliverDashboardBuilderDelegate] — builds children lazily with a builder
///   callback, suitable for large or dynamic lists.
/// - [SliverDashboardListDelegate] — takes a pre-built [List<Widget>], suitable
///   for small, static lists.
///
/// ## Subclassing
///
/// When creating a custom subclass, override:
/// - [buildItemWidget] — return the widget for the given index, or `null` to
///   signal the end of the list.
/// - [_itemKeyForIndex] — return a stable [Key] derived from the item's
///   identity so the framework can reconcile elements across rebuilds.
/// - [shouldRebuild] — return `false` when the delegate's configuration has
///   not changed to avoid unnecessary layout passes.
///
/// > **Note:** [_itemKeyForIndex] uses a library-private name. Subclasses
/// > defined in a *separate file* cannot override it, causing the dashboard to
/// > fall back to keyless [KeyedSubtree] nodes and potentially incorrect widget
/// > diffing.
abstract class SliverDashboardChildDelegate extends SliverChildDelegate {
  /// Whether to wrap each child in a [RepaintBoundary].
  ///
  /// Defaults to `true`. Disable only if the child already provides its own
  /// repaint isolation or if profiling shows the boundary is unnecessary.
  final bool addRepaintBoundaries;

  /// Whether to wrap each child in an [AutomaticKeepAlive].
  ///
  /// Defaults to `true`. Allows children that mix in [AutomaticKeepAliveClientMixin]
  /// to stay alive when scrolled out of the viewport.
  final bool addAutomaticKeepAlives;

  /// Whether to wrap each child in an [IndexedSemantics] node.
  ///
  /// Defaults to `true`. Set to `false` when the children provide their own
  /// semantic ordering or when semantics are not needed.
  final bool addSemanticIndexes;

  /// Callback that maps a local child index to a semantic index.
  ///
  /// Defaults to the identity mapping (semantic index == list index).
  /// Override to skip indices or apply an offset independently of
  /// [semanticIndexOffset].
  final SemanticIndexCallback semanticIndexCallback;

  /// A constant added to the semantic index produced by [semanticIndexCallback].
  ///
  /// Useful when this delegate represents a sub-section of a larger list and
  /// semantic numbering must continue from where a previous section left off.
  final int semanticIndexOffset;

  /// Resolves a list index from an item identifier.
  ///
  /// Required for [findIndexByKey] to work. When `null`, key-based index
  /// lookups always return `null`, which may degrade scroll restoration and
  /// animated list operations.
  final LayoutItemIndexFinder? findItemIndexById;

  const SliverDashboardChildDelegate({
    this.addRepaintBoundaries = true,
    this.addAutomaticKeepAlives = true,
    this.addSemanticIndexes = true,
    this.semanticIndexOffset = 0,
    this.semanticIndexCallback = _kDefaultSemanticIndexCallback,
    this.findItemIndexById,
  });

  /// Whether this delegate requires the children to be rebuilt.
  ///
  /// The base implementation always returns `true` — a conservative but
  /// potentially expensive default. Override in subclasses to return `false`
  /// when the delegate's fields are equal to [oldDelegate]'s fields so that
  /// layout passes are skipped during rebuilds that do not affect child content.
  @override
  bool shouldRebuild(covariant SliverDashboardChildDelegate oldDelegate) =>
      true;

  /// Returns the list index for the element identified by [key].
  ///
  /// Only [_ItemKey] instances produced by [itemKeyForIndex] carry an item
  /// identifier. All other key types return `null`.
  @override
  int? findIndexByKey(Key key) {
    if (key is! _ItemKey) {
      return null;
    }

    return findItemIndexById?.call(key.itemId);
  }

  /// Builds and wraps the child widget at [index].
  ///
  /// Delegates to [buildItemWidget] and then applies the configured wrapping
  /// layers in order: [RepaintBoundary] → [IndexedSemantics] →
  /// [AutomaticKeepAlive] → [KeyedSubtree].
  ///
  /// Returns `null` when [buildItemWidget] returns `null` (signalling the end
  /// of the list) or when [buildItemWidget] throws (in which case an
  /// [ErrorWidget] is substituted and the error is reported via
  /// [FlutterError.reportError]).
  @override
  @pragma('vm:notify-debugger-on-exception')
  Widget? build(BuildContext context, int index) {
    Widget? child;

    try {
      child = buildItemWidget(context, index);
    } catch (e, s) {
      child = _createErrorWidget(e, s);
    }

    if (child == null) {
      return null;
    }

    if (addRepaintBoundaries) {
      child = RepaintBoundary(child: child);
    }

    if (addSemanticIndexes) {
      final int? semanticIndex = semanticIndexCallback(child, index);
      if (semanticIndex != null) {
        child = IndexedSemantics(
          index: semanticIndex + semanticIndexOffset,
          child: child,
        );
      }
    }

    if (addAutomaticKeepAlives) {
      child = AutomaticKeepAlive(child: child);
    }

    return KeyedSubtree(
      key: itemKeyForIndex(index, child.key),
      child: child,
    );
  }

  /// Builds the raw child widget for [itemIndex].
  ///
  /// Return `null` to indicate that [itemIndex] is beyond the end of the list.
  /// Implementations must not throw — exceptions are caught by [build] and
  /// replaced with an [ErrorWidget].
  Widget? buildItemWidget(BuildContext context, int itemIndex);

  /// Returns a stable [Key] for the child at [index].
  ///
  /// [subKey] is the key already present on the child widget (may be `null`).
  /// The returned key is used as the key of the [KeyedSubtree] that wraps the
  /// child, enabling the framework to reuse elements across rebuilds.
  ///
  /// The base implementation returns `null` (no stable key). Override in
  /// subclasses to return an [_ItemKey] derived from the item's identity.
  ///
  /// > **Warning:** This is a library-private method. Subclasses in other files
  /// > cannot override it. If you need custom keying in an external subclass,
  /// > consider making this method protected and public.
  Key? itemKeyForIndex(int index, Key? subKey) => null;
}

/// A [SliverDashboardChildDelegate] that builds children lazily using a
/// [LayoutItemWidgetBuilder] callback.
///
/// This is the recommended delegate for most use cases because it only builds
/// widgets for items currently visible (or within the cache extent), keeping
/// memory overhead proportional to the viewport rather than the full list.
///
/// ## Usage
///
/// ```dart
/// SliverDashboardBuilderDelegate(
///   childCount: items.length,
///   findItemByIndex: (index) => items[index],
///   findItemIndexById: (id) => items.indexWhere((i) => i.id == id),
///   builder: (context, item) => MyItemWidget(item: item),
/// )
/// ```
///
/// For the common case of a plain `List<LayoutItem>`, prefer the
/// [SliverDashboardBuilderDelegate.items] named constructor, which wires up
/// [findItemByIndex] and [findItemIndexById] automatically.
class SliverDashboardBuilderDelegate extends SliverDashboardChildDelegate {
  /// The total number of children, or `null` if the count is unknown.
  ///
  /// When `null`, the sliver treats the list as unbounded and lays out children
  /// until [buildItemWidget] returns `null`. Providing an accurate count allows
  /// the framework to calculate scroll extents without building all children.
  final int? childCount;

  /// Returns the [LayoutItem] for the given list index.
  ///
  /// Should return `null` for indices ≥ [childCount] (or whenever the index
  /// is out of range).
  final LayoutItemFinder findItemByIndex;

  /// Builds a widget for the given [LayoutItem].
  final LayoutItemWidgetBuilder builder;

  const SliverDashboardBuilderDelegate({
    required this.findItemByIndex,
    required this.builder,
    super.findItemIndexById,
    super.addRepaintBoundaries,
    super.addAutomaticKeepAlives,
    super.addSemanticIndexes,
    super.semanticIndexCallback,
    super.semanticIndexOffset,
    this.childCount,
  });

  /// Creates a delegate from a plain [List<LayoutItem>].
  ///
  /// [findItemByIndex] and [findItemIndexById] are derived from the list
  /// automatically, so this constructor is the simplest way to drive the
  /// dashboard from an in-memory list.
  ///
  /// ```dart
  /// SliverDashboardBuilderDelegate.items(
  ///   items: myLayoutItems,
  ///   builder: (context, item) => MyCard(item: item),
  /// )
  /// ```
  SliverDashboardBuilderDelegate.items({
    required List<LayoutItem> items,
    required this.builder,
    super.addRepaintBoundaries,
    super.addAutomaticKeepAlives,
    super.addSemanticIndexes,
    super.semanticIndexCallback,
    super.semanticIndexOffset,
  }) : childCount = items.length,
       findItemByIndex = ((index) =>
           index >= 0 && index < items.length ? items[index] : null),
       super(
         findItemIndexById: (itemId) {
           final index = items.indexWhere((item) => item.id == itemId);
           return index >= 0 ? index : null;
         },
       );

  @override
  int? get estimatedChildCount => childCount;

  @override
  Key? itemKeyForIndex(int index, Key? subKey) {
    final item = findItemByIndex(index);

    if (item == null) {
      return subKey;
    }

    return _ItemKey(item.id);
  }

  @override
  Widget? buildItemWidget(BuildContext context, int itemIndex) {
    final item = findItemByIndex(itemIndex);

    if (item == null) {
      return null;
    }

    return builder(context, item);
  }
}

/// A [SliverDashboardChildDelegate] that displays a pre-built [List<Widget>].
///
/// Unlike [SliverDashboardBuilderDelegate], all child widgets are instantiated
/// before being passed to the delegate, so this is best suited to small,
/// static lists where the overhead of building all widgets upfront is
/// acceptable.
///
/// ## Keying
///
/// Stable item keys require [findItemByIndex] **and** [findItemIndexById] to
/// both be provided. Providing neither means items fall back to their own
/// widget keys (or become keyless), which may cause incorrect element reuse
/// when items are reordered. Providing only one of the two results in an
/// inconsistent state where keying works in one direction but not the other.
///
/// ```dart
/// SliverDashboardListDelegate(
///   children: myWidgets,
///   findItemByIndex: (index) => items[index],
///   findItemIndexById: (id) => items.indexWhere((i) => i.id == id),
/// )
/// ```
class SliverDashboardListDelegate extends SliverDashboardChildDelegate {
  /// The pre-built child widgets in list order.
  final List<Widget> children;

  /// Returns the [LayoutItem] for the given list index.
  ///
  /// Optional, but should be provided alongside [findItemIndexById] to enable
  /// stable [_ItemKey]-based keying for correct element reconciliation during
  /// reorders.
  final LayoutItemFinder? findItemByIndex;

  const SliverDashboardListDelegate({
    super.addRepaintBoundaries,
    super.addAutomaticKeepAlives,
    super.addSemanticIndexes,
    super.semanticIndexCallback,
    super.semanticIndexOffset,
    required this.children,
    this.findItemByIndex,
    super.findItemIndexById,
  });

  @override
  int? get estimatedChildCount => children.length;

  @override
  Widget? buildItemWidget(BuildContext context, int itemIndex) {
    if (itemIndex < 0 || itemIndex >= children.length) {
      return null;
    }

    return children[itemIndex];
  }

  @override
  Key? itemKeyForIndex(int index, Key? subKey) {
    final item = findItemByIndex?.call(index);

    if (item == null) {
      return subKey;
    }

    return _ItemKey(item.id);
  }
}

Widget _createErrorWidget(Object exception, StackTrace stackTrace) {
  final FlutterErrorDetails details = FlutterErrorDetails(
    exception: exception,
    stack: stackTrace,
    library: 'simple_dashboard',
    context: ErrorDescription('building'),
  );
  FlutterError.reportError(details);
  return ErrorWidget.builder(details);
}
