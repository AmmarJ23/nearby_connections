import 'dart:async';
import 'package:get/get.dart';

/// Controller to manage activity tracking and idle timer
class ActivityController extends GetxController {
  // Reactive state variables
  final currentActivity = "Idle".obs;
  final _idleTimer = Rx<Timer?>(null);
  
  // Callback for activity updates (for backward compatibility with main.dart)
  Function(String)? onActivityUpdate;
  
  ActivityController({this.onActivityUpdate});
  
  /// Update the current activity
  void updateActivity(String activity) {
    if (currentActivity.value != activity) {
      currentActivity.value = activity;
      onActivityUpdate?.call(activity);
      _resetIdleTimer();
    }
  }
  
  /// Reset the idle timer
  void _resetIdleTimer() {
    _idleTimer.value?.cancel();
    _idleTimer.value = Timer(const Duration(minutes: 2), () {
      if (currentActivity.value != "Idle") {
        updateActivity("Idle");
      }
    });
  }
  
  @override
  void onInit() {
    super.onInit();
    _resetIdleTimer();
  }
  
  @override
  void onClose() {
    _idleTimer.value?.cancel();
    super.onClose();
  }
}
