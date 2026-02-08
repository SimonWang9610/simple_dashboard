import 'package:simple_dashboard/src/models/item_flex.dart';
import 'package:simple_dashboard/src/models/item_rect.dart';
import 'package:simple_dashboard/src/utils/helper.dart';

class DashboardItem {
  final Object id;
  final ItemFlexRange range;
  final ItemRect rect;

  DashboardItem({
    required this.id,
    required this.range,
    required this.rect,
  }) : assert(DashboardAssertion.assertValidFlex(range, rect.flexes));
}
