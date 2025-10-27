
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth_wrapper.dart';
import 'error_logger.dart';
import 'dart:async';
import 'globals.dart';

void main() {
  FlutterError.onError = (details) {
    ErrorLogger().logError(details.exception, details.stack ?? StackTrace.current);
    FlutterError.presentError(details);
  };
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Firebase first
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Don't load user data here - let AuthWrapper handle it after checking auth state
    // await UserDataService().ensureLoaded(); // REMOVED - will load after login
    
    runApp(const MyApp());
  }, (error, stack) {
    ErrorLogger().logError(error, stack);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set a custom ErrorWidget builder once.
    ErrorWidget.builder = (FlutterErrorDetails details) {
      ErrorLogger().logError(details.exception, details.stack ?? StackTrace.current);
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: const Text('Something broke rendering this screen. See console logs.',
            style: TextStyle(color: Colors.redAccent)),
      );
    };
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorObservers: [globalRouteObserver, _LoggingObserver()],
      home: const AuthWrapper(),
    );
  }
}

class _LoggingObserver extends NavigatorObserver {
  void _log(String msg) { print('[ROUTE] $msg'); }
  @override
  void didPush(Route route, Route? previousRoute) {
    _log('push ${route.settings.name ?? route.runtimeType} from ${previousRoute?.settings.name}');
    super.didPush(route, previousRoute);
  }
  @override
  void didPop(Route route, Route? previousRoute) {
    _log('pop ${route.settings.name ?? route.runtimeType} -> ${previousRoute?.settings.name}');
    super.didPop(route, previousRoute);
  }
  @override
  void didRemove(Route route, Route? previousRoute) {
    _log('remove ${route.settings.name ?? route.runtimeType}');
    super.didRemove(route, previousRoute);
  }
  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    _log('replace ${oldRoute?.settings.name ?? oldRoute?.runtimeType} with ${newRoute?.settings.name ?? newRoute?.runtimeType}');
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

