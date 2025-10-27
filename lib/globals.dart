import 'package:flutter/material.dart';

// A central place for app-wide ("global") variables.
final globalMousePosition = ValueNotifier<Offset>(Offset.zero);
// When true, vertical scrolling in primary page lists should be suppressed
final globalVerticalScrollLock = ValueNotifier<bool>(false);

// Allow forcing all neon effects off (for web blank screen isolation)
final globalDisableNeon = ValueNotifier<bool>(false);

// Global route observer to log navigation for debugging
final RouteObserver<PageRoute<dynamic>> globalRouteObserver = RouteObserver<PageRoute<dynamic>>();

// Forces neon widgets to fully rebuild / reset internal smoothing when incremented.
final ValueNotifier<int> globalNeonGeneration = ValueNotifier<int>(0);

void bumpNeonGeneration([int step = 1]) {
	try {
		globalNeonGeneration.value = globalNeonGeneration.value + step;
	} catch (_) {}
}