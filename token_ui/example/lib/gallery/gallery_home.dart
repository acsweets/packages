import 'package:flutter/material.dart';
import 'package:token_ui/token_ui.dart';

class GalleryHome extends StatelessWidget {
  const GalleryHome({
    super.key,
    required this.mode,
    required this.useBrand,
    required this.onToggleMode,
    required this.onToggleBrand,
  });

  final ThemeMode mode;
  final bool useBrand;
  final VoidCallback onToggleMode;
  final VoidCallback onToggleBrand;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TuAppBar(
        titleText: 'token_ui',
        hideBack: true,
        actions: [
          IconButton(
            tooltip: 'Toggle light/dark',
            onPressed: onToggleMode,
            icon: Icon(
              mode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
            ),
          ),
          IconButton(
            tooltip: 'Toggle brand tokens',
            onPressed: onToggleBrand,
            icon: Icon(
              useBrand ? Icons.palette : Icons.palette_outlined,
              color: useBrand ? context.colors.button.neutral : null,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 32.aw, vertical: 24.aw),
        children: [
          Text(
            useBrand ? 'Brand tokens ON' : 'Built-in tokens',
            style: context.styles.meta[4] + context.colors.text.secondary1,
          ),
          SizedBox(height: 24.aw),
          _section(context, 'Buttons', const _ButtonsDemo()),
          _section(context, 'Tag / Dot / Badge', const _ChipsDemo()),
          _section(context, 'TextField', const _FieldDemo()),
          _section(context, 'Feedback', const _FeedbackDemo()),
          _section(context, 'List / Empty / Error', const _StateDemo()),
          _section(context, 'Swipe', const _SwipeDemo()),
          _section(context, 'Carousel indicator', const _CarouselDemo()),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, Widget child) {
    return Padding(
      padding: EdgeInsets.only(bottom: 40.aw),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.styles.title[5] + context.colors.text.primary),
          SizedBox(height: 16.aw),
          child,
        ],
      ),
    );
  }
}

class _ButtonsDemo extends StatelessWidget {
  const _ButtonsDemo();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12.aw,
      runSpacing: 12.aw,
      children: [
        TuButton.neutral.medium(label: 'Neutral', onPressed: () {}),
        TuButton.primary.medium(label: 'Primary', onPressed: () {}),
        TuButton.secondary.medium.outline(label: 'Outline', onPressed: () {}),
        TuButton.error.medium(label: 'Error', onPressed: () {}),
        TuButton.neutral.small(
          label: 'Loading',
          isLoading: true,
          onPressed: () {},
        ),
      ],
    );
  }
}

class _ChipsDemo extends StatelessWidget {
  const _ChipsDemo();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TuTag(text: 'Creator', backgroundColor: context.colors.button.neutral),
        SizedBox(width: 12.aw),
        TuNotificationDot.number(
          count: 3,
          child: Icon(Icons.notifications, size: 36.aw, color: context.colors.text.primary),
        ),
        SizedBox(width: 24.aw),
        TuBadgeWrapper(
          badgeText: 'NEW',
          backgroundColor: context.colors.error.primary,
          child: Container(
            width: 80.aw,
            height: 80.aw,
            color: context.colors.bg.component,
          ),
        ),
      ],
    );
  }
}

class _FieldDemo extends StatelessWidget {
  const _FieldDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TuTextField.primary(hintText: 'Primary field'),
        SizedBox(height: 16.aw),
        TuTextField.search(),
      ],
    );
  }
}

class _FeedbackDemo extends StatelessWidget {
  const _FeedbackDemo();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12.aw,
      runSpacing: 12.aw,
      children: [
        TuButton.neutral.small(
          label: 'Sheet',
          onPressed: () {
            TuBottomSheet.show(
              context,
              child: Padding(
                padding: EdgeInsets.all(32.aw),
                child: Text(
                  'Compose your billing / report UI here.',
                  style: context.styles.body[2] + context.colors.text.primary,
                ),
              ),
            );
          },
        ),
        TuButton.neutral.small(
          label: 'ActionSheet',
          onPressed: () {
            TuActionSheet.show(
              context,
              items: [
                TuActionSheetItem(label: 'Share', onTap: () {}),
                TuActionSheetItem(
                  label: 'Delete',
                  isDestructive: true,
                  onTap: () {},
                ),
              ],
            );
          },
        ),
        TuButton.neutral.small(
          label: 'Confirm',
          onPressed: () {
            TuConfirmDialog.show(
              context,
              title: 'Leave?',
              content: 'Unsaved changes will be lost.',
              confirmButton: 'Leave',
              cancelButton: 'Stay',
              isDestructive: true,
            );
          },
        ),
        TuButton.neutral.small(
          label: 'Loading 1s',
          onPressed: () async {
            TuBlockingLoadingOverlay.show(context);
            await Future<void>.delayed(const Duration(seconds: 1));
            TuBlockingLoadingOverlay.dismiss();
          },
        ),
      ],
    );
  }
}

class _StateDemo extends StatelessWidget {
  const _StateDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 120.aw,
          child: TuEmpty.content(message: 'No content'),
        ),
        SizedBox(height: 16.aw),
        SizedBox(
          height: 160.aw,
          child: TuError.network(onRetry: () {}),
        ),
        TuListItem.menu(title: 'Settings', onTap: () {}),
        const TuDivider(),
        TuListItem.menu(title: 'About', onTap: () {}),
      ],
    );
  }
}

class _SwipeDemo extends StatefulWidget {
  const _SwipeDemo();

  @override
  State<_SwipeDemo> createState() => _SwipeDemoState();
}

class _SwipeDemoState extends State<_SwipeDemo> {
  final _controller = TuSwipeCardController();
  var _items = ['A', 'B', 'C'];
  double _progress = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 220.aw,
          child: TuSwipeCardStack<String>(
            controller: _controller,
            items: _items,
            onDragUpdate: (p) => setState(() => _progress = p),
            onSwipeLeft: (item) {
              setState(() => _items = _items.where((e) => e != item).toList());
            },
            onSwipeRight: (item) {
              setState(() => _items = _items.where((e) => e != item).toList());
            },
            cardBuilder: (context, item, depth) {
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 24.aw),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.colors.bg.secondary,
                  borderRadius: BorderRadius.circular(24.ar),
                  border: Border.all(color: context.colors.component.stroke),
                ),
                child: Text(
                  'Card $item',
                  style: context.styles.headline[3] + context.colors.text.primary,
                ),
              );
            },
          ),
        ),
        SizedBox(height: 16.aw),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TuSwipeActionButton(
              iconBuilder: (c) => Icon(Icons.close, color: c),
              backgroundColor: context.colors.bg.component,
              iconColor: context.colors.text.primary,
              activeBackgroundColor: context.colors.error.primary,
              activeIconColor: context.colors.text.primary,
              label: 'Skip',
              direction: -1,
              progress: _progress,
              onTap: _controller.swipeLeft,
            ),
            SizedBox(width: 48.aw),
            TuSwipeActionButton(
              iconBuilder: (c) => Icon(Icons.favorite, color: c),
              backgroundColor: context.colors.bg.component,
              iconColor: context.colors.text.primary,
              activeBackgroundColor: context.colors.success,
              activeIconColor: context.colors.text.invert,
              label: 'Like',
              direction: 1,
              progress: _progress,
              onTap: _controller.swipeRight,
            ),
          ],
        ),
        if (_items.isEmpty)
          TextButton(
            onPressed: () => setState(() => _items = ['A', 'B', 'C']),
            child: const Text('Reset cards'),
          ),
      ],
    );
  }
}

class _CarouselDemo extends StatefulWidget {
  const _CarouselDemo();

  @override
  State<_CarouselDemo> createState() => _CarouselDemoState();
}

class _CarouselDemoState extends State<_CarouselDemo> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TuCarouselIndicator(count: 7, currentIndex: _index),
        SizedBox(height: 12.aw),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => setState(() => _index = (_index - 1).clamp(0, 6)),
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              onPressed: () => setState(() => _index = (_index + 1).clamp(0, 6)),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }
}
