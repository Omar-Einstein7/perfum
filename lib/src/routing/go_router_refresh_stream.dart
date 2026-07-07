import 'dart:async';
import 'package:flutter/foundation.dart';

/// Converts a [Stream] into a [ChangeNotifier] so GoRouter can
/// re-evaluate its redirect() whenever the stream emits.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
