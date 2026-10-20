import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../services/app_review_service.dart';

class AppReviewPrompt extends StatefulWidget {
  const AppReviewPrompt({required this.child, super.key});

  final Widget child;

  @override
  State<AppReviewPrompt> createState() => _AppReviewPromptState();
}

class _AppReviewPromptState extends State<AppReviewPrompt> {
  @override
  void initState() {
    super.initState();
    unawaited(
      AppReviewService.instance.registerEligibleSessionAndMaybeRequest(),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
