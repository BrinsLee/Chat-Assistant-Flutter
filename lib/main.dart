import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gpt_flutter/app.dart';
import 'dart:async';



Future<void> main() async {
  /// Captures errors reported by the Flutter framework.
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      // In development mode, simply print to console.
      FlutterError.dumpErrorToConsole(details);
    } else {
      // In production mode, report to the application zone to report to sentry.
      Zone.current.handleUncaughtError(details.exception, details.stack!);
    }
  };

  Future<void> reportError(dynamic error, StackTrace stackTrace) async {
    // Print the exception to the console.
    if (kDebugMode) {
      // Print the full stacktrace in debug mode.
      print(stackTrace);
      return;
    } else {
      // Send the Exception and Stacktrace to sentry in Production mode.
      // await Sentry.captureException(error, stackTrace: stackTrace);
    }
  }

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Wait for Sentry and Firebase to initialize before running the app.
      /* await Future.wait([
        SentryFlutter.init((options) => options.dsn = sentryDsn),
        Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
      ]); */

      runApp(const ChatGptApp());

    },
    reportError,
  );
}



