// Centralized logging for physics engine; disabled by default
library;

import 'package:flutter/foundation.dart';

bool kPhysicsLoggingEnabled = false;

void physicsLog(Object? message) {
  if (!kPhysicsLoggingEnabled) return;
  debugPrint(message?.toString());
}
