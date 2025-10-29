import 'package:flutter/material.dart';
import 'globals.dart';
import 'user_data_service.dart';
import 'firestore_service.dart';
import 'search_results_screen.dart';
import 'dart:math' as math;

class _FlickerEvent {
  final int startMs;
  final int endMs;
  final double opacity;
  const _FlickerEvent({required this.startMs, required this.endMs, required this.opacity});
}

class HashtagWallScreen extends StatefulWidget {
  const HashtagWallScreen({super.key});

  @override
  State<HashtagWallScreen> createState() => _HashtagWallScreenState();
}

class _HashtagWallScreenState extends State<HashtagWallScreen> with SingleTickerProviderStateMixin {
  static const Color _darkBlue = Color.fromARGB(255, 19, 35, 63);
  static const Color _lightBlue = Color.fromARGB(255, 129, 167, 238);

  final Set<String> _hovered = <String>{};
  final Set<String> _pressed = <String>{};
  late final AnimationController _flickerController;
  final Map<String, List<_FlickerEvent>> _flickerPatterns = {};
  final Map<String, int> _tagOffsets = {}; // staggered per-tag start (ms)
  final Set<String> _fadeInGroup = {}; // ~20% that will simple fade in (no flicker)
  bool _fadeGroupInitialized = false;
  late math.Random _sessionRandom;
  late final Duration _flickerTotalDuration; // randomized 2-3s
  late final Duration _startupDelay; // randomized 1-2s
  bool _flickerStarted = false;

  @override
  void initState() {
    super.initState();
    final rand = math.Random();
  _sessionRandom = math.Random();
    _startupDelay = Duration(milliseconds: rand.nextInt(501)); // 0-500ms
    _flickerTotalDuration = Duration(milliseconds: 2000 + rand.nextInt(1001)); // 2000-3000ms
    _flickerController = AnimationController(vsync: this, duration: _flickerTotalDuration)
      ..addListener(() {
        if (mounted) setState(() {}); // rebuild for opacity progression
      });
    Future.delayed(_startupDelay, () {
      if (!mounted) return;
      setState(() {
        _flickerStarted = true;
      });
      _flickerController.forward();
    });
  }

  @override
  void dispose() {
    _flickerController.dispose();
    super.dispose();
  }

  double _opacityForTag(String tag) {
    if (_fadeInGroup.contains(tag)) {
      if (!_flickerStarted) return 0.0;
      if (_flickerController.isCompleted) return 1.0;
      // Eased fade across the entire flicker timeline so it completes exactly when flickering ends.
      final v = _flickerController.value; // 0..1 over full duration
      return Curves.easeInOut.transform(v);
    }
    if (!_flickerStarted) return 0.0; // hidden until its global delay passes
    if (_flickerController.isCompleted) return 1.0;
    final tMs = (_flickerController.value * _flickerTotalDuration.inMilliseconds);
    final pattern = _flickerPatterns[tag];
    final offset = _tagOffsets[tag] ?? 0;
    final localMs = tMs - offset;
    if (pattern == null) return 1.0;
    if (localMs < 0) return 0.0; // not started for this tag yet
    // Damped oscillation: treat events as flicker impulses but fade frequency & depth over time
    final progress = (localMs / _flickerTotalDuration.inMilliseconds).clamp(0.0, 1.0);
    // Frequency decays from high (8Hz) to low (1Hz)
    final freq = 8.0 * (1 - progress) + 1.0; // linear decay
    final timeSec = localMs / 1000.0;
    // Base oscillation in [0,1]
    final osc = (math.sin(2 * math.pi * freq * timeSec) + 1) / 2;
    // Depth decays (strong early flicker -> subtle later)
    final depth = 0.7 * (1 - Curves.easeOut.transform(progress));
    // Randomized per-tag variance using pattern hash
    final variance = pattern.first.opacity; // reuse first event opacity as stable pseudo-random seed
    final flicker = (osc * depth * (0.6 + variance * 0.4));
    // Smooth ease overall opacity upward
    final envelope = Curves.easeInOut.transform(progress);
    final opacity = (envelope * (0.3 + 0.7 * (1 - depth))) + flicker;
    return opacity.clamp(0.0, 1.0);
  }

  void _ensurePatternFor(String tag) {
    if (_flickerPatterns.containsKey(tag)) return;
    // Deterministic random based on tag hash so it's stable per session
    final seed = tag.hashCode & 0x7FFFFFFF;
    final rand = math.Random(seed);
    // Per-tag stagger offset: 0 - 500ms (fade group still waits global delay but no offset flicker)
    _tagOffsets[tag] = _fadeInGroup.contains(tag) ? 0 : rand.nextInt(501);
    final int flashes = 5 + rand.nextInt(5); // 5-9 flickers for longer sequence
    final totalMs = _flickerTotalDuration.inMilliseconds;
    final usableMs = (totalMs * 0.9).toInt(); // keep last 10% stable
    final List<_FlickerEvent> raw = [];
    for (int i = 0; i < flashes; i++) {
      final start = rand.nextInt(usableMs.clamp(100, usableMs));
      final len = 60 + rand.nextInt(180); // 60-240ms
      final end = start + len;
      final opacity = 0.15 + rand.nextDouble() * 0.55; // 0.15 - 0.70 dip
      raw.add(_FlickerEvent(startMs: start, endMs: end > usableMs ? usableMs : end, opacity: opacity));
    }
    raw.sort((a, b) => a.startMs.compareTo(b.startMs));
    // Remove overlaps by keeping earlier interval and trimming or skipping later
    final List<_FlickerEvent> cleaned = [];
    int lastEnd = -1;
    for (final e in raw) {
      if (e.startMs >= lastEnd) {
        cleaned.add(e);
        lastEnd = e.endMs;
      } else if (e.endMs > lastEnd + 10) {
        // Partial overlap; trim start forward if still gives >=20ms duration
        final newStart = lastEnd + 5;
        if (e.endMs - newStart >= 20) {
          cleaned.add(_FlickerEvent(startMs: newStart, endMs: e.endMs, opacity: e.opacity));
          lastEnd = e.endMs;
        }
      }
    }
    _flickerPatterns[tag] = cleaned;
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService _firestoreService = FirestoreService();
    return StreamBuilder<List<BuddyProfile>>(
      stream: _firestoreService.watchAllUsers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final allUsers = snapshot.data!;
        // Calculate hashtag counts from real users
        final Map<String, int> counts = {};
        for (final user in allUsers) {
          for (final tag in user.interests) {
            final key = tag.toLowerCase();
            counts[key] = (counts[key] ?? 0) + 1;
          }
        }
        final entries = counts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return _buildHashtagWall(context, entries);
      },
    );
  }

  Widget _buildHashtagWall(BuildContext context, List<MapEntry<String, int>> entries) {
    final maxCount = entries.isNotEmpty ? entries.first.value : 1;
    final minCount = entries.isNotEmpty ? entries.last.value : 1;

    double sizeScaleFor(int n) {
      if (maxCount == minCount) return 1.0; // avoid div by zero
      final t = (n - minCount) / (maxCount - minCount);
      return 0.9 + t * 1.6; // scale from ~0.9x to ~2.5x
    }

    Color colorFor(int n) {
      if (maxCount == minCount) {
        // Default mid tone between cool and warm when all equal
        return const Color(0xFFB444FF);
      }
      final t = (n - minCount) / (maxCount - minCount);
      // Cool (violet) -> Warm (red)
      const cool = Color(0xFF8A2BE2); // blue-violet
      const warm = Color(0xFFFF5252); // warm red
      return Color.lerp(cool, warm, t) ?? warm;
    }

    return MouseRegion(
      onHover: (event) => globalMousePosition.value = event.position,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Hashtag Wall', style: TextStyle(color: _lightBlue)),
          backgroundColor: _darkBlue,
          iconTheme: const IconThemeData(color: _lightBlue),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              // Precompute tag display info and measure sizes using TextPainter
              final List<_TagInfo> tags = [];
              for (final e in entries) {
                final tagText = '#${e.key}';
                final fontSize = 16.0 * sizeScaleFor(e.value);
                final FontWeight weight = fontSize < 18
                    ? FontWeight.w400
                    : (fontSize < 24 ? FontWeight.w600 : FontWeight.w800);
                final color = colorFor(e.value);

                final textPainter = TextPainter(
                  text: TextSpan(
                    text: tagText,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: weight,
                      color: color,
                    ),
                  ),
                  textDirection: TextDirection.ltr,
                  maxLines: 1,
                )..layout();

                final textSize = textPainter.size;
                final padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
                final baseSize = Size(textSize.width + padding.horizontal, textSize.height + padding.vertical);

                tags.add(_TagInfo(
                  key: e.key,
                  label: tagText,
                  color: color,
                  fontSize: fontSize,
                  fontWeight: weight,
                  baseSize: baseSize,
                ));
              }

              // Initialize random fade-in group once (20% of tags) before placement
              if (!_fadeGroupInitialized) {
                final total = tags.length;
                if (total > 0) {
                  final target = (total * 0.2).round().clamp(1, total);
                  final indices = List<int>.generate(total, (i) => i);
                  indices.shuffle(_sessionRandom);
                  _fadeInGroup.clear();
                  for (int i = 0; i < target; i++) {
                    _fadeInGroup.add(tags[indices[i]].key);
                  }
                }
                _fadeGroupInitialized = true;
              }

              // Place tags around center using spiral search without overlaps
              final placed = _placeTags(size, tags);

              // Compute bounding box of placed rects (unscaled)
              if (placed.isEmpty) {
                return const SizedBox.shrink();
              }
              double minLeft = placed.first.rect.left;
              double minTop = placed.first.rect.top;
              double maxRight = placed.first.rect.right;
              double maxBottom = placed.first.rect.bottom;
              for (final p in placed) {
                if (p.rect.left < minLeft) minLeft = p.rect.left;
                if (p.rect.top < minTop) minTop = p.rect.top;
                if (p.rect.right > maxRight) maxRight = p.rect.right;
                if (p.rect.bottom > maxBottom) maxBottom = p.rect.bottom;
              }
              final bboxWidth = (maxRight - minLeft).clamp(1, size.width);
              final bboxHeight = (maxBottom - minTop).clamp(1, size.height);

              // Target area: 80% of available width/height (10% padding each side)
              final targetWidth = size.width * 0.8;
              final targetHeight = size.height * 0.8;
              final scaleW = targetWidth / bboxWidth;
              final scaleH = targetHeight / bboxHeight;
              final globalScale = scaleW < scaleH ? scaleW : scaleH;

              // Position offset so scaled bbox is centered
              final scaledBBoxWidth = bboxWidth * globalScale;
              final scaledBBoxHeight = bboxHeight * globalScale;
              final originLeft = (size.width - scaledBBoxWidth) / 2;
              final originTop = (size.height - scaledBBoxHeight) / 2;

              return Stack(
                children: placed.map((p) {
                  final tag = p.info.key;
                  _ensurePatternFor(tag);
                  final isHovered = _hovered.contains(tag);
                  final isPressed = _pressed.contains(tag);
                  final hoverScale = isHovered ? 1.05 : 1.0;
                  final pressScale = isPressed ? 0.97 : 1.0;
                  final totalScale = hoverScale * pressScale;
                  // Removed surge effect; container will not scale/glow pulse at end.

                  // Scaled rect
                  final scaledLeft = originLeft + (p.rect.left - minLeft) * globalScale;
                  final scaledTop = originTop + (p.rect.top - minTop) * globalScale;
                  final scaledWidth = p.rect.width * globalScale;
                  final scaledHeight = p.rect.height * globalScale;

                  final effectiveFontSize = p.info.fontSize * globalScale;

                  return Positioned(
                    left: scaledLeft,
                    top: scaledTop,
                    width: scaledWidth,
                    height: scaledHeight,
                    child: MouseRegion(
                      onEnter: (_) => setState(() => _hovered.add(tag)),
                      onExit: (_) => setState(() => _hovered.remove(tag)),
                      child: GestureDetector(
                        behavior: HitTestBehavior.deferToChild,
                        onTapDown: (_) => setState(() => _pressed.add(tag)),
                        onTapCancel: () => setState(() => _pressed.remove(tag)),
                        onTapUp: (_) {
                          setState(() => _pressed.remove(tag));
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SearchResultsScreen(hashtag: tag),
                            ),
                          );
                        },
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 120),
                          curve: Curves.easeOut,
                          scale: totalScale,
                          child: Opacity(
                            opacity: _opacityForTag(tag),
                            child: _RotatedTagContainer(
                              rotation: p.rotation,
                              color: p.info.color,
                              isHovered: isHovered,
                              child: Text(
                                p.info.label,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  color: p.info.color,
                                  fontSize: effectiveFontSize,
                                  fontWeight: p.info.fontWeight,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TagInfo {
  final String key;
  final String label;
  final Color color;
  final double fontSize;
  final FontWeight fontWeight;
  final Size baseSize; // size without rotation
  _TagInfo({
    required this.key,
    required this.label,
    required this.color,
    required this.fontSize,
    required this.fontWeight,
    required this.baseSize,
  });
}

class _PlacedTag {
  final _TagInfo info;
  final Rect rect; // positioned rect on canvas
  final double rotation; // 0, pi/2, -pi/2
  _PlacedTag({required this.info, required this.rect, required this.rotation});
}

List<_PlacedTag> _placeTags(Size canvas, List<_TagInfo> tags) {
  // Place larger tags first (tags should already be sorted, but defensively sort by width*height desc)
  final sorted = [...tags]..sort((a, b) => (b.baseSize.width * b.baseSize.height)
      .compareTo(a.baseSize.width * a.baseSize.height));

  final List<_PlacedTag> placed = [];
  final List<Rect> taken = [];
  final center = Offset(canvas.width / 2, canvas.height / 2);

  // Spiral parameters
  const double step = 10.0; // radial step per turn
  const double angleStep = math.pi / 10; // 18 degrees
  const double margin = 10.0; // spacing between tags
  const double boundsMargin = 8.0; // padding from edges

  bool fits(Rect r) {
    if (r.left < boundsMargin || r.top < boundsMargin ||
        r.right > canvas.width - boundsMargin || r.bottom > canvas.height - boundsMargin) {
      return false;
    }
    final expanded = r.inflate(margin);
    for (final o in taken) {
      if (expanded.overlaps(o)) return false;
    }
    return true;
  }

  for (final info in sorted) {
    // Try candidates along a spiral from the center
    bool placedTag = false;
    double radius = 0;
    double theta = 0;
    const int maxAttempts = 3000;
    for (int attempt = 0; attempt < maxAttempts && !placedTag; attempt++) {
      final offset = Offset(radius * math.cos(theta), radius * math.sin(theta));
      final pos = center + offset;

      // Allowed rotations: 0, +90°, -90°
      for (final rot in <double>[0.0, math.pi / 2, -math.pi / 2]) {
        final bool ninety = rot != 0.0;
        final rotatedSize = ninety
            ? Size(info.baseSize.height, info.baseSize.width)
            : info.baseSize;
        final rect = Rect.fromCenter(center: pos, width: rotatedSize.width, height: rotatedSize.height);
        if (fits(rect)) {
          placed.add(_PlacedTag(info: info, rect: rect, rotation: rot));
          taken.add(rect);
          placedTag = true;
          break;
        }
      }

      // Advance spiral
      theta += angleStep;
      radius += step * (angleStep / (2 * math.pi)); // smooth radial growth relative to angle
    }

    // If not placed, try to clamp within bounds without overlap (looser)
    if (!placedTag) {
      final rect = Rect.fromCenter(center: center, width: info.baseSize.width, height: info.baseSize.height);
      final clamped = Rect.fromLTWH(
        rect.left.clamp(boundsMargin, canvas.width - boundsMargin - rect.width),
        rect.top.clamp(boundsMargin, canvas.height - boundsMargin - rect.height),
        rect.width,
        rect.height,
      );
      placed.add(_PlacedTag(info: info, rect: clamped, rotation: 0.0));
      taken.add(clamped);
    }
  }

  return placed;
}

class _RotatedTagContainer extends StatelessWidget {
  final double rotation; // 0, pi/2, -pi/2
  final Color color;
  final bool isHovered;
  final Widget child;
  const _RotatedTagContainer({
    required this.rotation,
    required this.color,
    required this.isHovered,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Convert angle to quarterTurns for RotatedBox
    int quarterTurns;
    if (rotation > 1.4 && rotation < 1.7) {
      quarterTurns = 1; // ~ +90
    } else if (rotation < -1.4 && rotation > -1.7) {
      quarterTurns = 3; // ~ -90 (270)
    } else {
      quarterTurns = 0; // 0 deg
    }

    final blurBase = isHovered ? 22 : 12;
    final spreadBase = isHovered ? 4 : 2;
    final container = Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 19, 35, 63),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.9)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.45),
            blurRadius: blurBase.toDouble(),
            spreadRadius: spreadBase.toDouble(),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Center(child: child),
    );

    return RotatedBox(quarterTurns: quarterTurns, child: container);
  }
}
