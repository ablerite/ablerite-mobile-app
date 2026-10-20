import 'package:flutter/material.dart';

/// Shared tablet breakpoints and sizing. Phone layouts deliberately keep their
/// existing widget trees; these helpers are only used after [isTabletLayout]
/// returns true.
bool isTabletLayout(BuildContext context) {
  return MediaQuery.sizeOf(context).shortestSide >= 600;
}

bool isTabletLandscape(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return isTabletLayout(context) && size.width > size.height;
}

double tabletPopupWidth(
  BuildContext context, {
  double portrait = 680,
  double landscape = 820,
}) {
  final size = MediaQuery.sizeOf(context);
  final requested = size.width > size.height ? landscape : portrait;
  return requested.clamp(0, size.width - 48).toDouble();
}

BoxConstraints tabletDialogConstraints(
  BuildContext context, {
  double portraitWidth = 680,
  double landscapeWidth = 820,
  double heightFactor = 0.84,
}) {
  return BoxConstraints(
    maxWidth: tabletPopupWidth(
      context,
      portrait: portraitWidth,
      landscape: landscapeWidth,
    ),
    maxHeight: MediaQuery.sizeOf(context).height * heightFactor,
  );
}

Widget constrainTabletSheet(
  BuildContext context,
  Widget child, {
  double portraitWidth = 680,
  double landscapeWidth = 820,
}) {
  if (!isTabletLayout(context)) return child;
  return Align(
    alignment: Alignment.bottomCenter,
    child: SizedBox(
      width: tabletPopupWidth(
        context,
        portrait: portraitWidth,
        landscape: landscapeWidth,
      ),
      child: child,
    ),
  );
}

Widget scrollOnTablet(BuildContext context, Widget child) {
  if (!isTabletLayout(context)) return child;
  return SingleChildScrollView(child: child);
}
