import 'package:flutter/material.dart';

class TabChangeListener extends StatefulWidget {
  final Widget child;
  final void Function(int index) onTabChanged;

  const TabChangeListener({
    super.key,
    required this.child,
    required this.onTabChanged,
  });

  @override
  State<TabChangeListener> createState() => _TabChangeListenerState();
}

class _TabChangeListenerState extends State<TabChangeListener> {
  TabController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = DefaultTabController.maybeOf(context);
    if (_controller != controller) {
      final oldIndex = _controller?.index;
      _controller?.removeListener(_handleTabChange);
      _controller = controller;
      _controller?.addListener(_handleTabChange);
      
      // If the controller was completely replaced and the new index is different from the old one,
      // it means DefaultTabController recreated it (e.g. length changed) and reset to 0.
      if (oldIndex != null && _controller != null && oldIndex != _controller!.index) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onTabChanged(_controller!.index);
          }
        });
      }
    }
  }

  void _handleTabChange() {
    if (_controller != null) {
      widget.onTabChanged(_controller!.index);
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_handleTabChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
