import 'package:flutter/material.dart';

import '../tokens/app_tokens.dart';

class AppSplitPane extends StatelessWidget {
  final Widget primary;
  final Widget secondary;
  final double breakpoint;
  final int primaryFlex;
  final int secondaryFlex;
  final double gap;

  const AppSplitPane({
    super.key,
    required this.primary,
    required this.secondary,
    this.breakpoint = 860,
    this.primaryFlex = 1,
    this.secondaryFlex = 1,
    this.gap = AppTokens.s3,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            children: [
              Expanded(flex: primaryFlex, child: primary),
              SizedBox(height: gap),
              Expanded(flex: secondaryFlex, child: secondary),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: primaryFlex, child: primary),
            SizedBox(width: gap),
            Expanded(flex: secondaryFlex, child: secondary),
          ],
        );
      },
    );
  }
}
