import 'package:flutter/material.dart';

/// Unified interest / topic chip styling for visual coherence across the app.
/// Transparent background, gradient-based text color (violet -> red), subtle border.
class InterestChip extends StatelessWidget {
  final String tag; // raw tag without '#'
  final bool selected;
  final ValueChanged<bool>? onSelected; // if provided, renders a ChoiceChip
  final bool compact; // smaller padding/font
  final bool clickable; // if false and onSelected null -> passive chip
  final EdgeInsets? padding;
  final bool prefixHash; // allow disabling '#' for special labels

  const InterestChip(
    this.tag, {
    super.key,
    this.selected = false,
    this.onSelected,
    this.compact = false,
    this.clickable = true,
    this.padding,
    this.prefixHash = true,
  });

  Color _colorFor(String tag) {
    // Use a deterministic color based on tag hash for vibrant, varied coloring
    final lower = tag.toLowerCase().replaceAll('#', '');
    final hash = lower.hashCode.abs();
    final t = (hash % 100) / 100.0; // 0.0 to 1.0 based on tag
    
    // Multi-stop gradient: Cyan -> Purple -> Pink -> Orange
    if (t < 0.33) {
      // Cyan to Purple
      final localT = t / 0.33;
      return Color.lerp(const Color(0xFF00D9FF), const Color(0xFFB366FF), localT)!;
    } else if (t < 0.66) {
      // Purple to Pink
      final localT = (t - 0.33) / 0.33;
      return Color.lerp(const Color(0xFFB366FF), const Color(0xFFFF2E97), localT)!;
    } else {
      // Pink to Orange
      final localT = (t - 0.66) / 0.34;
      return Color.lerp(const Color(0xFFFF2E97), const Color(0xFFFF8C00), localT)!;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Global scale factor for making chips larger everywhere
    const double scale = 1.5; // requested 1.8x

    final display = prefixHash
        ? (tag.startsWith('#') ? tag : '#$tag')
        : tag; // allow raw label without '#'
    final color = _colorFor(tag.replaceAll('#',''));
    const neonSelected = Color(0xFFB366FF); // Updated to match new purple
    final baseFont = compact ? 11.0 : 13.0;
    final textStyle = TextStyle(
      color: color,
      fontSize: baseFont * scale,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.25,
    );
    final sideColor = selected ? neonSelected : color.withOpacity(0.55);
    final horiz = (compact ? 8.0 : 12.0) * scale;
    final vert = (compact ? 2.0 : 4.0) * scale * 0.55; // keep vertical growth a bit restrained

    final pill = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: padding ?? EdgeInsets.symmetric(horizontal: horiz, vertical: vert),
      decoration: ShapeDecoration(
        shape: StadiumBorder(side: BorderSide(color: sideColor, width: selected ? 2.0 : 1.2)),
        // Fully transparent background; subtle gradient tint only when selected
        gradient: selected ? LinearGradient(colors: [neonSelected.withOpacity(0.12), neonSelected.withOpacity(0.05)]) : null,
        shadows: selected && onSelected != null
            ? [
                BoxShadow(
                  color: sideColor.withOpacity(0.65),
                  blurRadius: 14 * scale,
                  spreadRadius: 1.5,
                ),
              ]
            : null,
      ),
      child: Text(display, style: textStyle),
    );

    final interactive = (onSelected != null) || clickable;
    if (!interactive) return pill;
    return InkWell(
      borderRadius: BorderRadius.circular(40),
      onTap: onSelected == null ? null : () => onSelected!(!selected),
      child: pill,
    );
  }
}
