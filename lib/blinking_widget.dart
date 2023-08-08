// ignore_for_file: must_be_immutable, library_private_types_in_public_api

import 'package:flutter/material.dart';

class BlinkingWidget extends StatefulWidget {
  Widget child;
  Duration duration;

  BlinkingWidget({super.key, required this.child, required this.duration});

  @override
  _BlinkingWidgetState createState() => _BlinkingWidgetState();
}

class _BlinkingWidgetState extends State<BlinkingWidget> with TickerProviderStateMixin {
  AnimationController? _animationController;

  @override
  void initState() {
    _animationController = AnimationController(vsync: this, duration: widget.duration);
    _animationController?.repeat(reverse: true);
    super.initState();
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration.inMilliseconds != widget.duration.inMilliseconds) {
      _animationController?.dispose();
      _animationController = AnimationController(vsync: this, duration: widget.duration);
      _animationController?.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_animationController != null) {
      return FadeTransition(
        opacity: _animationController!,
        child: widget.child,
      );
    }
    return const SizedBox();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }
}