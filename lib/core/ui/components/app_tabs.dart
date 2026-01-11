
import 'package:flutter/material.dart';

class AppTabs extends StatelessWidget {
  final List<String> tabs;
  final List<Widget> children;
  final TabController? controller;
  final bool isScrollable;

  const AppTabs({
    super.key,
    required this.tabs,
    required this.children,
    this.controller,
    this.isScrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    if (controller != null) {
      return Column(
        children: [
          TabBar(
            controller: controller,
            isScrollable: isScrollable,
            tabAlignment: isScrollable ? TabAlignment.start : TabAlignment.fill,
            tabs: tabs.map((t) => Tab(text: t)).toList(),
          ),
          Expanded(
            child: TabBarView(
              controller: controller,
              children: children,
            ),
          ),
        ],
      );
    }

    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: isScrollable,
            tabAlignment: isScrollable ? TabAlignment.start : TabAlignment.fill,
            tabs: tabs.map((t) => Tab(text: t)).toList(),
          ),
          Expanded(
            child: TabBarView(
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}
