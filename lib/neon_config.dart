import 'package:flutter/material.dart';

/// Intensity / preset levels for the neon tile.
enum NeonIntensity { full, medium, lite, off }

/// Runtime-editable neon settings. Use the [neonSettingsNotifier] to mutate.
class NeonSettings {
  final NeonIntensity intensity;
  final double blurSigma;      // Backdrop blur strength
  final double strokeWidth;    // Border painter stroke
  final double smoothing;      // Mouse smoothing 0-1 (higher = more smoothing)
  final double glowOpacity;    // BoxShadow/glow opacity 0-1
  final bool gradientTilt;     // Enable dynamic gradient tilt
  final bool cometBorder;      // Enable comet sweep border painter
  final bool backdropBlur;     // Whether to apply BackdropFilter at all

  const NeonSettings({
    this.intensity = NeonIntensity.full,
    this.blurSigma = 15,
    this.strokeWidth = 9,
    this.smoothing = 0.06,
    this.glowOpacity = 0.40,
    this.gradientTilt = true,
    this.cometBorder = true,
    this.backdropBlur = true,
  });

  NeonSettings copyWith({
    NeonIntensity? intensity,
    double? blurSigma,
    double? strokeWidth,
    double? smoothing,
    double? glowOpacity,
    bool? gradientTilt,
    bool? cometBorder,
    bool? backdropBlur,
  }) => NeonSettings(
        intensity: intensity ?? this.intensity,
        blurSigma: blurSigma ?? this.blurSigma,
        strokeWidth: strokeWidth ?? this.strokeWidth,
        smoothing: smoothing ?? this.smoothing,
        glowOpacity: glowOpacity ?? this.glowOpacity,
        gradientTilt: gradientTilt ?? this.gradientTilt,
        cometBorder: cometBorder ?? this.cometBorder,
        backdropBlur: backdropBlur ?? this.backdropBlur,
      );
}

/// Global runtime neon settings notifier.
final ValueNotifier<NeonSettings> neonSettingsNotifier =
    ValueNotifier<NeonSettings>(const NeonSettings());

NeonSettings defaultForIntensity(NeonIntensity intensity) {
  switch (intensity) {
    case NeonIntensity.full:
      return const NeonSettings(
        intensity: NeonIntensity.full,
        blurSigma: 15,
        strokeWidth: 9,
        smoothing: 0.06,
        glowOpacity: 0.40,
        gradientTilt: true,
        cometBorder: true,
        backdropBlur: true,
      );
    case NeonIntensity.medium:
      return const NeonSettings(
        intensity: NeonIntensity.medium,
        blurSigma: 8,
        strokeWidth: 6,
        smoothing: 0.08,
        glowOpacity: 0.30,
        gradientTilt: true,
        cometBorder: true,
        backdropBlur: true,
      );
    case NeonIntensity.lite:
      return const NeonSettings(
        intensity: NeonIntensity.lite,
        blurSigma: 0,
        strokeWidth: 3,
        smoothing: 0.05,
        glowOpacity: 0.22,
        gradientTilt: false,
        cometBorder: false,
        backdropBlur: false,
      );
    case NeonIntensity.off:
      return const NeonSettings(
        intensity: NeonIntensity.off,
        blurSigma: 0,
        strokeWidth: 0,
        smoothing: 0.05,
        glowOpacity: 0,
        gradientTilt: false,
        cometBorder: false,
        backdropBlur: false,
      );
  }
}

/// Opens a bottom sheet allowing real-time editing of neon settings.
Future<void> showNeonConfigSheet(BuildContext context) async {
  final theme = Theme.of(context);
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF0F1B2E),
    builder: (ctx) {
      return ValueListenableBuilder<NeonSettings>(
        valueListenable: neonSettingsNotifier,
        builder: (context, settings, _) {
          void update(NeonSettings s) => neonSettingsNotifier.value = s;
          Widget slider({
            required String label,
            required double value,
            required double min,
            required double max,
            int? divisions,
            required ValueChanged<double> onChanged,
          }) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$label: ${value.toStringAsFixed(1)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  Slider(
                    value: value,
                    min: min,
                    max: max,
                    divisions: divisions,
                    label: value.toStringAsFixed(1),
                    onChanged: (v) => onChanged(v),
                  )
                ],
              );
          return Theme(
            data: theme.copyWith(
              sliderTheme: theme.sliderTheme.copyWith(
                activeTrackColor: const Color(0xFF6BD1FF),
                thumbColor: const Color(0xFF6BD1FF),
                inactiveTrackColor: Colors.white24,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Neon Config', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white70),
                          tooltip: 'Reset',
                          onPressed: () => update(const NeonSettings()),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: NeonIntensity.values.map((lvl) {
                        final selected = lvl == settings.intensity;
                        return ChoiceChip(
                          label: Text(lvl.name, style: TextStyle(color: selected ? Colors.black : Colors.white70)),
                          selected: selected,
                          onSelected: (_) {
                            // Replace full config with preset defaults
                            update(defaultForIntensity(lvl));
                          },
                          selectedColor: const Color(0xFF6BD1FF),
                          backgroundColor: const Color(0xFF1C2F4D),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    if (settings.intensity != NeonIntensity.lite && settings.intensity != NeonIntensity.off) ...[
                      slider(
                        label: 'Blur',
                        value: settings.blurSigma,
                        min: 0,
                        max: 30,
                        divisions: 30,
                        onChanged: (v) => update(settings.copyWith(blurSigma: v)),
                      ),
                      SwitchListTile(
                        dense: true,
                        value: settings.backdropBlur,
                        onChanged: (v) => update(settings.copyWith(backdropBlur: v)),
                        title: const Text('Backdrop Blur Enabled', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: const Color(0xFF6BD1FF),
                      ),
                      slider(
                        label: 'Stroke',
                        value: settings.strokeWidth,
                        min: 1,
                        max: 20,
                        divisions: 19,
                        onChanged: (v) => update(settings.copyWith(strokeWidth: v)),
                      ),
                      slider(
                        label: 'Mouse Smooth',
                        value: settings.smoothing,
                        min: 0.01,
                        max: 0.2,
                        divisions: 19,
                        onChanged: (v) => update(settings.copyWith(smoothing: v)),
                      ),
                      slider(
                        label: 'Glow Opacity',
                        value: settings.glowOpacity,
                        min: 0,
                        max: 1,
                        divisions: 20,
                        onChanged: (v) => update(settings.copyWith(glowOpacity: v)),
                      ),
                      SwitchListTile(
                        dense: true,
                        value: settings.gradientTilt,
                        onChanged: (v) => update(settings.copyWith(gradientTilt: v)),
                        title: const Text('Gradient Tilt', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: const Color(0xFF6BD1FF),
                      ),
                      SwitchListTile(
                        dense: true,
                        value: settings.cometBorder,
                        onChanged: (v) => update(settings.copyWith(cometBorder: v)),
                        title: const Text('Comet Border', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: const Color(0xFF6BD1FF),
                      ),
                    ] else
                      const Text('Limited controls for Lite / Off presets.', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
