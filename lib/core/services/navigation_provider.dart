import 'package:flutter_riverpod/flutter_riverpod.dart';

class NavigationController extends StateNotifier<int> {
  NavigationController() : super(0);

  void setIndex(int index) {
    state = index;
  }
}

final navigationProvider = StateNotifierProvider<NavigationController, int>((ref) {
  return NavigationController();
});
