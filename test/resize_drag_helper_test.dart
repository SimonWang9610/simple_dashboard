import 'package:flutter_test/flutter_test.dart';
import 'package:simple_dashboard/simple_dashboard.dart';
import 'package:simple_dashboard/src/classes/resize_drag_handler.dart';
import 'package:simple_dashboard/src/utils/checker.dart';

LayoutItem _item(String id, int x, int y, int w, int h) => LayoutItem(
  id: id,
  rect: LayoutRect(
    x: x,
    y: y,
    size: LayoutSize(width: w, height: h),
  ),
);

LayoutItem _itemById(List<LayoutItem> items, Object id) {
  return items.firstWhere((item) => item.id == id);
}

void main() {
  group('ResizeDragHelper.resolveCollision', () {
    test('right resize shrinks adjacent right item from left edge', () {
      final draggingItem = _item('a', 0, 0, 2, 2);
      final rightItem = _item('b', 2, 0, 2, 2);

      final candidateRect = ResizeDragHelper.computeCandidateRect(
        1,
        0,
        draggingItem.rect,
        ResizeDirection.right,
      );

      final resolved = ResizeDragHelper.resolveCollision(
        draggingItem,
        candidateRect,
        ResizeDirection.right,
        [LayoutItem.placeholderOf(draggingItem), rightItem],
        (_) => true,
      );

      expect(resolved, isNotNull);

      final updatedItems = resolved!;
      final updatedRight = _itemById(updatedItems, 'b');
      final placeholder = updatedItems.firstWhere((i) => i.isPlaceholder);

      expect(
        updatedRight.rect,
        const LayoutRect(x: 3, y: 0, size: LayoutSize(width: 1, height: 2)),
      );
      expect(placeholder.rect, candidateRect);
      expect(LayoutChecker.findFirstConflictItems(updatedItems), isNull);
    });

    test('left resize shrinks adjacent left item from right edge', () {
      final draggingItem = _item('a', 2, 0, 2, 2);
      final leftItem = _item('b', 0, 0, 2, 2);

      final candidateRect = ResizeDragHelper.computeCandidateRect(
        -1,
        0,
        draggingItem.rect,
        ResizeDirection.left,
      );

      final resolved = ResizeDragHelper.resolveCollision(
        draggingItem,
        candidateRect,
        ResizeDirection.left,
        [LayoutItem.placeholderOf(draggingItem), leftItem],
        (_) => true,
      );

      expect(resolved, isNotNull);

      final updatedLeft = _itemById(resolved!, 'b');
      final placeholder = resolved.firstWhere((i) => i.isPlaceholder);

      expect(
        updatedLeft.rect,
        const LayoutRect(x: 0, y: 0, size: LayoutSize(width: 1, height: 2)),
      );
      expect(placeholder.rect, candidateRect);
      expect(LayoutChecker.findFirstConflictItems(resolved), isNull);
    });

    test(
      'bottom-right resize shrinks diagonal collided item from top-left',
      () {
        final draggingItem = _item('a', 0, 0, 2, 2);
        final diagonalItem = _item('b', 2, 2, 2, 2);

        final candidateRect = ResizeDragHelper.computeCandidateRect(
          1,
          1,
          draggingItem.rect,
          ResizeDirection.bottomRight,
        );

        final resolved = ResizeDragHelper.resolveCollision(
          draggingItem,
          candidateRect,
          ResizeDirection.bottomRight,
          [LayoutItem.placeholderOf(draggingItem), diagonalItem],
          (_) => true,
        );

        expect(resolved, isNotNull);

        final updatedItems = resolved!;
        final updatedDiagonal = _itemById(updatedItems, 'b');
        final placeholder = updatedItems.firstWhere(
          (i) => i.isPlaceholder,
        );

        expect(
          updatedDiagonal.rect,
          const LayoutRect(x: 3, y: 3, size: LayoutSize(width: 1, height: 1)),
        );
        expect(placeholder.rect, candidateRect);
        expect(LayoutChecker.findFirstConflictItems(updatedItems), isNull);
      },
    );

    test(
      'left resize resolves overlap by geometry even without step deltas',
      () {
        final draggingItem = _item('a', 2, 0, 2, 2);
        final leftItem = _item('b', 0, 0, 3, 2);

        final candidateRect = ResizeDragHelper.computeCandidateRect(
          -1,
          0,
          draggingItem.rect,
          ResizeDirection.left,
        );

        final resolved = ResizeDragHelper.resolveCollision(
          draggingItem,
          candidateRect,
          ResizeDirection.left,
          [LayoutItem.placeholderOf(draggingItem), leftItem],
          (_) => true,
        );

        expect(resolved, isNotNull);

        final updatedItems = resolved!;
        final updatedLeft = _itemById(updatedItems, 'b');

        expect(
          updatedLeft.rect,
          const LayoutRect(x: 0, y: 0, size: LayoutSize(width: 1, height: 2)),
        );
        expect(LayoutChecker.findFirstConflictItems(updatedItems), isNull);
      },
    );
  });
}
