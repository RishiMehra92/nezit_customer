import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:dismissible_page/dismissible_page.dart';
import '../model/discover_status_model.dart';
import '../widgets/single_user_story_view.dart';

class DiscoverStoryPage extends StatefulWidget {
  final List<DiscoverStatusItem> users;
  final int initialUserIndex;
  final void Function(int)? onPageChanged;

  const DiscoverStoryPage({
    super.key,
    required this.users,
    this.initialUserIndex = 0,
    this.onPageChanged,
  });

  @override
  State<DiscoverStoryPage> createState() => _DiscoverStoryPageState();
}

class _DiscoverStoryPageState extends State<DiscoverStoryPage> {
  late PageController _pageController;
  final ValueNotifier<bool> _isScrollingNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialUserIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _isScrollingNotifier.dispose();
    super.dispose();
  }

  void _onUserCompleted(int userIndex) async {
    if (_isScrollingNotifier.value) return;
    _isScrollingNotifier.value = true;
    if (userIndex < widget.users.length - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  void _onUserPrevious(int userIndex) async {
    if (_isScrollingNotifier.value) return;
    _isScrollingNotifier.value = true;
    if (userIndex > 0) {
      await _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.users.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.tr('noStoriesAvailable', fallback: 'No stories available'), style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
        ),
      );
    }

    return DismissiblePage(
      onDismissed: () => Navigator.of(context).pop(),
      direction: DismissiblePageDismissDirection.down,
      isFullScreen: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollStartNotification) {
              _isScrollingNotifier.value = true;
            } else if (notification is ScrollEndNotification) {
              _isScrollingNotifier.value = false;
            }
            return false;
          },
          child: ValueListenableBuilder<bool>(
            valueListenable: _isScrollingNotifier,
            builder: (context, isScrolling, child) {
              return AbsorbPointer(
                absorbing: isScrolling,
                child: child,
              );
            },
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                widget.onPageChanged?.call(index);
              },
              itemCount: widget.users.length,
              itemBuilder: (context, index) {
                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double pageOffset = 0;
                    if (_pageController.position.haveDimensions) {
                      pageOffset = _pageController.page! - index;
                    } else {
                      pageOffset = (widget.initialUserIndex.toDouble() - index);
                    }

                    if (pageOffset > 1 || pageOffset < -1) {
                      return child!;
                    }

                    final double rotation = pageOffset * (math.pi / 2);
                    final Alignment alignment =
                        pageOffset > 0 ? Alignment.centerRight : Alignment.centerLeft;

                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(rotation),
                      alignment: alignment,
                      child: child,
                    );
                  },
                  child: SingleUserStoryView(
                    userIndex: index,
                    userItem: widget.users[index],
                    nextUserItem: index < widget.users.length - 1 ? widget.users[index + 1] : null,
                    onComplete: () => _onUserCompleted(index),
                    onPreviousUser: () => _onUserPrevious(index),
                    onClose: () => Navigator.pop(context),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
