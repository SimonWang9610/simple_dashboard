import 'package:flutter/widgets.dart';

typedef CacheKeyGetter = GlobalKey Function(Object itemId);

GlobalKey _defaultCacheKeyGetter(Object itemId) =>
    GlobalKey(debugLabel: "cache_key_$itemId");

/// A store for cache keys of layout items.
/// This is used to preserve the state of item widgets during reparenting an item,
/// like dragging.
///
/// If no key is found for an item, the store will return null,
/// and the item widget may be recreated (re-mounted) from scratch when needed.
///
/// Typically, [DashboardMutatingStateMixin] will work with the store to
/// keep items alive when mutating the layout,
/// by assigning cache keys to items and providing them to item widgets like [DraggableItemWidget].
class ItemCacheKeyStore extends InheritedWidget {
  /// A map from item id to cache key.
  final Map<Object, GlobalKey> cacheKeys;

  final bool autoGenerateCacheKeys;

  /// When [autoGenerateCacheKeys] is true and there is no existing cache key for an item,
  /// the store will generate a new cache key using [getKey] and store it in [cacheKeys].
  final CacheKeyGetter getKey;

  const ItemCacheKeyStore({
    super.key,
    required this.cacheKeys,
    required super.child,
    this.getKey = _defaultCacheKeyGetter,
    this.autoGenerateCacheKeys = false,
  });

  @override
  bool updateShouldNotify(covariant ItemCacheKeyStore oldWidget) {
    return cacheKeys != oldWidget.cacheKeys ||
        getKey != oldWidget.getKey ||
        autoGenerateCacheKeys != oldWidget.autoGenerateCacheKeys;
  }

  static ItemCacheKeyStore? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ItemCacheKeyStore>();
  }

  static GlobalKey? getCacheKeyForItem(BuildContext context, Object itemId) {
    final store = of(context);

    if (store == null) {
      return null;
    }

    if (store.autoGenerateCacheKeys) {
      return store.cacheKeys.putIfAbsent(itemId, () => store.getKey(itemId));
    }

    return store.cacheKeys[itemId];
  }
}
