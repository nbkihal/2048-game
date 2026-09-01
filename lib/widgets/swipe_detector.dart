import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants.dart';
import '../models/direction.dart';

/// Turns drags — and arrow / WASD keys on desktop and web — into [Direction]s.
///
/// A drag fires exactly once, on the axis that dominated the gesture, so a
/// sloppy diagonal still produces the swipe the player meant.
class SwipeDetector extends StatefulWidget {
  const SwipeDetector({
    super.key,
    required this.onSwipe,
    required this.child,
    this.enabled = true,
    this.autofocus = true,
  });

  final ValueChanged<Direction> onSwipe;
  final Widget child;
  final bool enabled;
  final bool autofocus;

  @override
  State<SwipeDetector> createState() => _SwipeDetectorState();
}

class _SwipeDetectorState extends State<SwipeDetector> {
  Offset _delta = Offset.zero;
  bool _fired = false;

  static final _keyMap = <LogicalKeyboardKey, Direction>{
    LogicalKeyboardKey.arrowUp: Direction.up,
    LogicalKeyboardKey.arrowDown: Direction.down,
    LogicalKeyboardKey.arrowLeft: Direction.left,
    LogicalKeyboardKey.arrowRight: Direction.right,
    LogicalKeyboardKey.keyW: Direction.up,
    LogicalKeyboardKey.keyS: Direction.down,
    LogicalKeyboardKey.keyA: Direction.left,
    LogicalKeyboardKey.keyD: Direction.right,
  };

  void _onPanStart(DragStartDetails _) {
    _delta = Offset.zero;
    _fired = false;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_fired) return;
    _delta += details.delta;
    final dx = _delta.dx;
    final dy = _delta.dy;
    if (dx.abs() < kSwipeThreshold && dy.abs() < kSwipeThreshold) return;

    _fired = true;
    if (dx.abs() > dy.abs()) {
      widget.onSwipe(dx > 0 ? Direction.right : Direction.left);
    } else {
      widget.onSwipe(dy > 0 ? Direction.down : Direction.up);
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!widget.enabled || event is! KeyDownEvent)
      return KeyEventResult.ignored;
    final direction = _keyMap[event.logicalKey];
    if (direction == null) return KeyEventResult.ignored;
    widget.onSwipe(direction);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: widget.autofocus,
      onKeyEvent: _onKey,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: widget.enabled ? _onPanStart : null,
        onPanUpdate: widget.enabled ? _onPanUpdate : null,
        child: widget.child,
      ),
    );
  }
}
