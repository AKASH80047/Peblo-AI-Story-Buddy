import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/app.dart';

/// Entry point.
///
/// [SystemChrome] calls are placed here — called once at startup, never inside
/// a build() method. Calling them in build() is a bug because build() can be
/// invoked multiple times per second, turning these into async platform-channel
/// calls on every frame rebuild.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait before the first frame renders.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const PebloApp());
}
