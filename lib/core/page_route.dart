import 'package:flutter/material.dart';

import 'constants.dart';

/// A fade-through transition.
///
/// The house style has no elevation, so the platform's slide-and-shadow push
/// would be the only shadow in the whole app. Screens cross-fade instead.
class FadeThroughRoute<T> extends PageRouteBuilder<T> {
  FadeThroughRoute({required this.child})
      : super(
          transitionDuration: kDialogDuration,
          reverseTransitionDuration: kDialogDuration,
          pageBuilder: (_, _, _) => child,
          transitionsBuilder: (_, animation, _, page) {
            final curved =
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
                child: page,
              ),
            );
          },
        );

  final Widget child;
}
