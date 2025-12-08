import 'package:get/get.dart';

/// Controller to manage navigation state in the sample app
class NavigationController extends GetxController {
  // Reactive state for selected navigation index
  final selectedIndex = 0.obs;
  
  /// Change the selected tab index
  void changeTab(int index) {
    selectedIndex.value = index;
  }
}
