import 'dart:async';

import 'package:flutter/material.dart';
import 'package:simple_dashboard/simple_dashboard.dart';

class ItemWidget extends StatefulWidget {
  final LayoutItem item;
  final VoidCallback? onRemove;
  final VoidCallback? onDoubleTap;
  const ItemWidget({
    super.key,
    required this.item,
    this.onRemove,
    this.onDoubleTap,
  });

  @override
  State<ItemWidget> createState() => _ItemWidgetState();
}

class _ItemWidgetState extends State<ItemWidget>
    with AutomaticKeepAliveClientMixin {
  int count = 0;

  late final Timer timer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // print('Creating item ${widget.item.id}');
    timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        setState(() {
          count++;
        });
      },
    );
  }

  @override
  void didUpdateWidget(covariant ItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // print('Updating item to ${widget.item.id}');
    if (oldWidget.item.id != widget.item.id) {
      count = 0;
    }
  }

  @override
  void activate() {
    super.activate();
    // print('Activating item ${widget.item.id}');
  }

  @override
  void deactivate() {
    super.deactivate();
    // print('Deactivating item ${widget.item.id}');
  }

  @override
  void dispose() {
    // print('Disposing item ${widget.item.id}');
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Item ${widget.item.id}'),
            content: Text(
              'Position: (${widget.item.rect.x}, ${widget.item.rect.y})\nSize: ${widget.item.rect.size.width} x ${widget.item.rect.size.height}',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onRemove?.call();
                },
                child: const Text('Remove'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      onDoubleTap: widget.onDoubleTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black),
          color: Colors
              .primaries[widget.item.id.hashCode % Colors.primaries.length]
              .withOpacity(0.5),
        ),
        child: Center(
          child: Text('[${widget.item.id}]: $count'),
        ),
      ),
    );
  }
}
