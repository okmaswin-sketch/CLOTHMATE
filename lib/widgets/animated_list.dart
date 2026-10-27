import 'package:flutter/material.dart';

class CMAnimatedListItem extends StatefulWidget {
  const CMAnimatedListItem({
    super.key,
    required this.index,
    required this.child,
    this.duration = const Duration(milliseconds: 350),
    this.delay = const Duration(milliseconds: 40),
    this.curve = Curves.easeOutCubic,
    this.beginOffset = const Offset(0, 0.15),
    this.fadeIn = true,
  });

  final int index;
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final Offset beginOffset;
  final bool fadeIn;

  @override
  State<CMAnimatedListItem> createState() => _CMAnimatedListItemState();
}

class _CMAnimatedListItemState extends State<CMAnimatedListItem> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _slideAnimation = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.7, curve: Curves.easeOut)),
    );
    Future.delayed(widget.delay * widget.index, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.fadeIn) {
      return SlideTransition(position: _slideAnimation, child: widget.child);
    }
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}

class CMAnimatedList extends StatelessWidget {
  const CMAnimatedList({
    super.key,
    required this.children,
    this.itemDuration = const Duration(milliseconds: 350),
    this.itemDelay = const Duration(milliseconds: 40),
    this.curve = Curves.easeOutCubic,
    this.beginOffset = const Offset(0, 0.15),
    this.fadeIn = true,
  });

  final List<Widget> children;
  final Duration itemDuration;
  final Duration itemDelay;
  final Curve curve;
  final Offset beginOffset;
  final bool fadeIn;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(children.length, (index) {
        return CMAnimatedListItem(
          index: index,
          duration: itemDuration,
          delay: itemDelay,
          curve: curve,
          beginOffset: beginOffset,
          fadeIn: fadeIn,
          child: children[index],
        );
      }),
    );
  }
}

class CMAnimatedListView extends StatelessWidget {
  const CMAnimatedListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.itemDuration = const Duration(milliseconds: 350),
    this.itemDelay = const Duration(milliseconds: 40),
    this.curve = Curves.easeOutCubic,
    this.beginOffset = const Offset(0, 0.15),
    this.fadeIn = true,
    this.scrollDirection = Axis.vertical,
    this.shrinkWrap = false,
    this.physics,
    this.padding,
  });

  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final Duration itemDuration;
  final Duration itemDelay;
  final Curve curve;
  final Offset beginOffset;
  final bool fadeIn;
  final Axis scrollDirection;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: scrollDirection,
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return CMAnimatedListItem(
          index: index,
          duration: itemDuration,
          delay: itemDelay,
          curve: curve,
          beginOffset: beginOffset,
          fadeIn: fadeIn,
          child: itemBuilder(context, index),
        );
      },
    );
  }
}

class CMStaggeredList extends StatelessWidget {
  const CMStaggeredList({
    super.key,
    required this.children,
    this.itemDuration = const Duration(milliseconds: 400),
    this.itemDelay = const Duration(milliseconds: 50),
    this.curve = Curves.easeOutCubic,
    this.spacing = 8,
    this.padding,
  });

  final List<Widget> children;
  final Duration itemDuration;
  final Duration itemDelay;
  final Curve curve;
  final double spacing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        children: List.generate(children.length, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: index == children.length - 1 ? 0 : spacing),
            child: CMAnimatedListItem(
              index: index,
              duration: itemDuration,
              delay: itemDelay,
              curve: curve,
              child: children[index],
            ),
          );
        }),
      ),
    );
  }
}