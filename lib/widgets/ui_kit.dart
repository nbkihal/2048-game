import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/skin.dart';

/// The DESIGN.md component set, rebuilt as widgets.
///
/// Everything here is flat: no shadows, no gradients, no elevation. Depth comes
/// from colour contrast and stacking order alone.

/// "Gate Pill Button" — the system's only primary action.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.skin,
    this.icon,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Skin skin;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return _TappableSurface(
      onPressed: onPressed,
      borderRadius: AppRadius.pillRadius,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          width: expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.cardPadding + 7,
            vertical: AppSpacing.s16,
          ),
          decoration: BoxDecoration(
            color: skin.pillFill,
            borderRadius: AppRadius.pillRadius,
          ),
          child: _ButtonContent(
            label: label,
            icon: icon,
            color: skin.onPill,
            center: expand,
          ),
        ),
      ),
    );
  }
}

/// "Outlined Display Button" — a chromatic outlined action, never a filled CTA.
class OutlinedActionButton extends StatelessWidget {
  const OutlinedActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.skin,
    this.icon,
    this.expand = false,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final Skin skin;
  final IconData? icon;
  final bool expand;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final tint = color ?? skin.accent;
    return _TappableSurface(
      onPressed: onPressed,
      borderRadius: AppRadius.pillRadius,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Container(
          width: expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.cardPadding + 7,
            vertical: AppSpacing.s16,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: tint, width: 2.5),
            borderRadius: AppRadius.pillRadius,
          ),
          child: _ButtonContent(
            label: label,
            icon: icon,
            color: tint,
            center: expand,
          ),
        ),
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.color,
    required this.center,
  });

  final String label;
  final IconData? icon;
  final Color color;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: center ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: center
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: AppType.body.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/// "Underline Text Link" — tertiary action, reads as a disclaimer.
class UnderlineTextLink extends StatelessWidget {
  const UnderlineTextLink({
    super.key,
    required this.label,
    required this.onPressed,
    required this.color,
  });

  final String label;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _TappableSurface(
      onPressed: onPressed,
      borderRadius: AppRadius.cardRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text(
          label.toUpperCase(),
          style: AppType.monoLabel.copyWith(
            color: color,
            decoration: TextDecoration.underline,
            decorationColor: color,
          ),
        ),
      ),
    );
  }
}

/// "Mono Label Tag" — a stamped label rather than a pill button.
class MonoTag extends StatelessWidget {
  const MonoTag({
    super.key,
    required this.label,
    required this.color,
    this.bordered = true,
    this.background,
  });

  final String label;
  final Color color;
  final bool bordered;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        border: bordered ? Border.all(color: color, width: 1) : null,
        borderRadius: AppRadius.pillRadius,
      ),
      child: Text(
        label.toUpperCase(),
        style: AppType.monoLabel.copyWith(color: color, height: 1.0),
      ),
    );
  }
}

/// "Confetti Card" / "Dark Text Card" — a flat 6px paint swatch.
class RisoCard extends StatelessWidget {
  const RisoCard({
    super.key,
    required this.color,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.border,
    this.onTap,
  });

  final Color color;
  final Widget child;
  final EdgeInsets padding;
  final Color? border;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.cardRadius,
        border: border == null ? null : Border.all(color: border!, width: 2),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return _TappableSurface(
      onPressed: onTap,
      borderRadius: AppRadius.cardRadius,
      child: card,
    );
  }
}

/// A square icon button sized for the HUD.
class IconPill extends StatelessWidget {
  const IconPill({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.color,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = _TappableSurface(
      onPressed: onPressed,
      borderRadius: AppRadius.pillRadius,
      child: Opacity(
        opacity: onPressed == null ? 0.35 : 1,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 2),
            borderRadius: AppRadius.pillRadius,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Shared tap affordance: a press shrinks the target slightly. Cheaper to read
/// than a ripple and it suits a system with no elevation.
class _TappableSurface extends StatefulWidget {
  const _TappableSurface({
    required this.child,
    required this.onPressed,
    required this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final BorderRadius borderRadius;

  @override
  State<_TappableSurface> createState() => _TappableSurfaceState();
}

class _TappableSurfaceState extends State<_TappableSurface> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// "Stamp" — a framed circular icon mark.
///
/// The system has no illustration layer, so an outcome (won, stuck, out of
/// moves) is stated with one large glyph in a ring rather than with artwork.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.icon,
    required this.color,
    this.fill,
    this.size = 74,
  });

  final IconData icon;

  /// Ring and glyph colour.
  final Color color;

  /// Optional disc behind the glyph. Left null the badge is an outline only.
  final Color? fill;

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
      ),
      child: Icon(icon, size: size * 0.52, color: color),
    );
  }
}
