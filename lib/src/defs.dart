import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:simple_dashboard/simple_dashboard.dart';

typedef DashboardItemBuilder =
    Widget Function(BuildContext context, LayoutItem item);

typedef DraggingItemFeedbackBuilder =
    Widget Function(
      BuildContext context,
      ValueListenable<DraggingItemPosition> position,
      Widget feedback,
    );
