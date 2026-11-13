import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'ui/layout/orientation_lock.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Phones stay portrait; tablets rotate. The window may have no size yet
  // here (then App decides after its first frame). Nothing may delay runApp.
  final view = PlatformDispatcher.instance.views.first;
  if (view.devicePixelRatio > 0) {
    PortraitLock.decide(view.physicalSize / view.devicePixelRatio);
  }
  runApp(const ProviderScope(child: App()));
}
