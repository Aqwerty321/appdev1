import 'package:flutter/material.dart';
import '../user_data_service.dart';

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
    final service = UserDataService();
    final counts = service.getHashtagCounts();
    if (counts.isEmpty) return const Color(0xFF8A2BE2);
    final lower = tag.toLowerCase();
    final values = counts.values;
    int min = values.reduce((a,b)=> a < b ? a : b);
    int max = values.reduce((a,b)=> a > b ? a : b);
    final c = counts[lower] ?? min;
    final t = max == min ? 0.5 : (c - min) / (max - min);
    const cool = Color(0xFF8A2BE2);
    const warm = Color(0xFFFF5252);
    return Color.lerp(cool, warm, t)!;
  }

  @override
  Widget build(BuildContext context) {
    // Global scale factor for making chips larger everywhere
    const double scale = 1.5; // requested 1.8x

    final display = prefixHash
        ? (tag.startsWith('#') ? tag : '#$tag')
        : tag; // allow raw label without '#'
    final color = _colorFor(tag.replaceAll('#',''));
    const neonSelected = Color(0xFF986AF0);
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
