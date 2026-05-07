import 'package:flutter_riverpod/flutter_riverpod.dart';

class NavigationController extends StateNotifier<int> {
  // Default to the Request workspace (index 1) for a tool-first UX.
  NavigationController() : super(1);

  void setIndex(int index) {
    state = index;
  }
}

final navigationProvider =
    StateNotifierProvider<NavigationController, int>((ref) {
  return NavigationController();
});
