import 'package:flutter/foundation.dart';

final bool ddriDebugLogEnabled =
    kDebugMode || const bool.fromEnvironment('DDRI_DEBUG_LOG', defaultValue: false);

void ddriDebugPrint(String message) {
  if (ddriDebugLogEnabled) {
    debugPrint(message);
  }
}
