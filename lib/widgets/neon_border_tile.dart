import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../globals.dart';
import '../neon_config.dart';
import '../error_logger.dart';

// --- WIDGET CLASS ---
class NeonBorderGradientTile extends StatefulWidget {
  final double? width;
  final double? height;
  final EdgeInsets padding;
  final LinearGradient? gradient;
  final double borderRadius;

  // Hybrid content properties
  final Widget? child;
  final String? text;
  final double textSize;

  const NeonBorderGradientTile({
    super.key,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(12.0),
    this.gradient,
    this.child,
    this.text,
    this.textSize = 16.0,
    this.borderRadius = 20.0,
  }) : assert(child == null || text == null,
            'Cannot provide both a child and a text property.');

  @override
  State<NeonBorderGradientTile> createState() => _NeonBorderGradientTileState();
}

/// A lightweight version of the neon border tile for list/detail pages.
class NeonBorderLiteTile extends StatelessWidget {
  final double? width;
  final double? height;
  final EdgeInsets padding;
  final Widget? child;
  final String? text;
  final double textSize;
  final double borderRadius;

  const NeonBorderLiteTile({
    super.key,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(12.0),
    this.child,
    this.text,
    this.textSize = 16.0,
    this.borderRadius = 20.0,
  }) : assert(child == null || text == null,
            'Cannot provide both child and text');

  @override
  Widget build(BuildContext context) {
    // Preset lite style
    const LinearGradient gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF201D49), Color(0xFF211B79)],
    );
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius + 4),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 148, 0, 255).withOpacity(0.22 * 0.6),
            blurRadius: 14,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF6BD1FF).withOpacity(0.25),
              width: 1.2,
            ),
            gradient: gradient,
          ),
          child: child ??
              (text != null
                  ? Text(
                      text!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: textSize,
                        height: 1.45,
                      ),
                    )
                  : const SizedBox.shrink()),
        ),
      ),
    );
  }
}
// --- STATE CLASS ---
class _NeonBorderGradientTileState extends State<NeonBorderGradientTile> {
  final ScrollController _scrollController = ScrollController();
  Offset _smoothedMousePos = Offset.zero;
  int _smoothedAlpha = 0;
  Alignment _smoothedGradientBegin = Alignment.topLeft;
  Alignment _smoothedGradientEnd = Alignment.bottomRight;
  int _lastGeneration = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double _distanceToEdge(Offset point, Size size) {
    final dx = max(0, max(0 - point.dx, point.dx - size.width));
    final dy = max(0, max(0 - point.dy, point.dy - size.height));
    return sqrt(dx * dx + dy * dy);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: globalDisableNeon,
      builder: (context, hardDisabled, _) {
        return ValueListenableBuilder<NeonSettings>(
          valueListenable: neonSettingsNotifier,
          builder: (context, settings, _) {
            if (hardDisabled || settings.intensity == NeonIntensity.off) {
              return _staticContainer();
            }
            if (settings.intensity == NeonIntensity.lite) {
              return _liteContainer(settings);
            }
            // If both dynamic features are off while in a higher intensity, degrade to lite container.
            if (!settings.gradientTilt && !settings.cometBorder) {
              final degraded = defaultForIntensity(NeonIntensity.lite);
              return _liteContainer(degraded);
            }
            return ValueListenableBuilder<int>(
              valueListenable: globalNeonGeneration,
              builder: (context, generation, _) {
                if (generation != _lastGeneration) {
                  _lastGeneration = generation;
                  // Reset smoothed values to avoid stale states after major edits
                  _smoothedMousePos = Offset.zero;
                  _smoothedAlpha = 0;
                  _smoothedGradientBegin = Alignment.topLeft;
                  _smoothedGradientEnd = Alignment.bottomRight;
                }
                return ValueListenableBuilder<Offset>(
      valueListenable: globalMousePosition,
      builder: (context, mousePos, child) {
        try {
        final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
        // These gradients are needed for both fallback and active states
        const LinearGradient defaultGradient = LinearGradient(
          colors: [
            Color.fromARGB(255, 32, 29, 73),
            Color.fromARGB(255, 33, 27, 121)
          ],
        );
        final baseGradient = widget.gradient ?? defaultGradient;

        // Fallback render before first layout pass (prevents zero-height blank tiles on mobile/web)
        if (renderBox == null || !renderBox.hasSize) {
          return Container(
            width: widget.width,
            // Let height be intrinsic if not provided
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius + 5),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(255, 148, 0, 255).withOpacity(0.25),
                  blurRadius: 18,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: Container(
                decoration: BoxDecoration(gradient: baseGradient),
                child: Padding(
                  padding: widget.padding,
                  child: widget.child ?? (widget.text != null
                      ? Text(
                          widget.text!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: widget.textSize,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        )
                      : const SizedBox.shrink()),
                ),
              ),
            ),
          );
        }

        final tileSize = renderBox.size;
        if (tileSize.width == 0 || tileSize.height == 0) {
          return _staticContainer();
        }

        final Offset localMouse = renderBox.globalToLocal(mousePos);
        _smoothedMousePos = _safeOffsetLerp(_smoothedMousePos, localMouse, settings.smoothing);

        // BORDER ALPHA LOGIC
        final distance = _distanceToEdge(_smoothedMousePos, tileSize);
        const maxProximity = 80.0;
        final targetAlpha = ((1.0 - (distance / maxProximity)).clamp(0.0, 1.0) * 255).round();
  _smoothedAlpha = (_smoothedAlpha * 0.9 + targetAlpha * 0.1).round();

        // --- RESTORED GRADIENT TILT LOGIC ---
        final center = Offset(tileSize.width / 2, tileSize.height / 2);
        final radius = sqrt(pow(tileSize.width / 2, 2) + pow(tileSize.height / 2, 2));

        final vec = _smoothedMousePos - center;
        final unitVec = vec.distance > 0 ? vec / vec.distance : const Offset(1, 0);

        final startPoint = center - unitVec * radius;
        final endPoint = center + unitVec * radius;

        Alignment targetGradientBegin = Alignment(
          (startPoint.dx / (tileSize.width / 2)) - 1,
          (startPoint.dy / (tileSize.height / 2)) - 1,
        );
        Alignment targetGradientEnd = Alignment(
          (endPoint.dx / (tileSize.width / 2)) - 1,
          (endPoint.dy / (tileSize.height / 2)) - 1,
        );
        
        if (settings.gradientTilt) {
    _smoothedGradientBegin = _safeAlignLerp(_smoothedGradientBegin, targetGradientBegin, 0.04);
    _smoothedGradientEnd = _safeAlignLerp(_smoothedGradientEnd, targetGradientEnd, 0.04);
        } else {
          _smoothedGradientBegin = Alignment.topLeft;
          _smoothedGradientEnd = Alignment.bottomRight;
        }
        
        // defaultGradient & baseGradient already defined above

        final activeGradient = LinearGradient(
          colors: baseGradient.colors,
          stops: baseGradient.stops,
          transform: baseGradient.transform,
          begin: _smoothedGradientBegin,
          end: _smoothedGradientEnd,
        );

        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius + 5),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 148, 0, 255).withOpacity(settings.glowOpacity),
                blurRadius: 25,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Stack(
              children: [
                if (settings.backdropBlur && settings.blurSigma > 0)
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: settings.blurSigma, sigmaY: settings.blurSigma),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: activeGradient,
                      ),
                    ),
                  )
                else
                  Container(decoration: BoxDecoration(gradient: activeGradient)),
                if (widget.child != null)
                  Positioned.fill(
                    child: Padding(
                      padding: widget.padding,
                      child: widget.child,
                    ),
                  )
                else
                  Padding(
                    padding: widget.padding,
                    child: ScrollConfiguration(
                      behavior: const ScrollBehavior().copyWith(overscroll: false),
                      child: RawScrollbar(
                        controller: _scrollController,
                        thumbColor: Colors.purpleAccent.withOpacity(0.7),
                        radius: const Radius.circular(8),
                        thickness: 6,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: Text(
                            widget.text ?? '',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: widget.textSize,
                              fontWeight: FontWeight.w500, // Adjusted for readability
                              height: 1.5, // Improved line spacing
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (settings.cometBorder)
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _NeonBorderPainter(
                          mousePosition: _smoothedMousePos,
                          tileSize: tileSize,
                          alpha: _smoothedAlpha,
                          borderRadius: widget.borderRadius,
                          strokeWidth: settings.strokeWidth,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
        } catch (e, st) {
          // Log and fall back to static container to avoid total blank screen
          try { ErrorLogger().logError(e, st); } catch (_) {}
          return _staticContainer();
        }
      },
    );
              },
            );
          },
        );
      },
    );
  }

  Widget _staticContainer() => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: const Color(0xFF18263C),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: const Color(0xFF2D476C)),
        ),
        padding: widget.padding,
        child: widget.child ?? (widget.text != null
            ? Text(widget.text!, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: widget.textSize, height: 1.4))
            : const SizedBox.shrink()),
      );

  Widget _liteContainer(NeonSettings settings) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius + 4),
          gradient: const LinearGradient(colors: [Color(0xFF201D49), Color(0xFF211B79)]),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 148, 0, 255).withOpacity(settings.glowOpacity * 0.6),
              blurRadius: 14,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF6BD1FF).withOpacity(.25), width: 1.2),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF242F55), Color(0xFF1A2743)],
              ),
            ),
            child: widget.child ?? (widget.text != null
                ? Text(widget.text!, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: widget.textSize, height: 1.45))
                : const SizedBox.shrink()),
          ),
        ),
      );
}

// --- PAINTER CLASS ---
class _NeonBorderPainter extends CustomPainter {
  final Offset mousePosition;
  final Size tileSize;
  final int alpha;
  final double borderRadius;
  final double strokeWidth;

  _NeonBorderPainter({
    required this.mousePosition,
    required this.tileSize,
    required this.alpha,
    required this.borderRadius,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (alpha == 0) return;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth.clamp(0.5, 40.0);

    final center = Offset(tileSize.width / 2, tileSize.height / 2);
    final dx = mousePosition.dx - center.dx;
    final dy = mousePosition.dy - center.dy;
    final angle = atan2(dy, dx);

    const cometHead = 0.16;
    const cometTail = 0.32;
    final angleOffset = cometHead * 2 * pi;

    paint.shader = SweepGradient(
      center: Alignment.center,
      colors: [
        Colors.transparent,
        Color.fromARGB(alpha, 148, 0, 211), // Changed to a deep purple
        Colors.transparent,
      ],
      stops: const [0.0, cometHead, cometTail],
      transform: GradientRotation(angle - angleOffset),
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _NeonBorderPainter oldDelegate) {
    return oldDelegate.mousePosition != mousePosition ||
      oldDelegate.alpha != alpha ||
      oldDelegate.strokeWidth != strokeWidth;
  }
}

// --- SAFETY HELPERS ---
Offset _safeOffsetLerp(Offset a, Offset b, double t) {
  final tt = t.isNaN ? 0.0 : t.clamp(0.0, 1.0);
  return Offset(
    a.dx + (b.dx - a.dx) * tt,
    a.dy + (b.dy - a.dy) * tt,
  );
}

Alignment _safeAlignLerp(Alignment a, Alignment b, double t) {
  final tt = t.isNaN ? 0.0 : t.clamp(0.0, 1.0);
  return Alignment(
    a.x + (b.x - a.x) * tt,
    a.y + (b.y - a.y) * tt,
  );
}