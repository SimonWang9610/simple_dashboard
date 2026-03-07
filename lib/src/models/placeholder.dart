final class PlaceholderId {
  final Object itemId;

  const PlaceholderId(this.itemId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaceholderId && other.itemId == itemId;

  @override
  int get hashCode => itemId.hashCode;

  @override
  String toString() => "PlaceholderId($itemId)";
}
