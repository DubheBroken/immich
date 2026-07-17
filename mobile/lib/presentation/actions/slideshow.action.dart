import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:immich_mobile/generated/translations.g.dart';
import 'package:immich_mobile/presentation/actions/action.dart';
import 'package:immich_mobile/providers/infrastructure/timeline.provider.dart';
import 'package:immich_mobile/routing/router.dart';

class SlideshowAction extends BaseAction {
  const SlideshowAction();

  @override
  WidgetAction? resolve(ActionScope scope) {
    final ActionScope(:ref, :context) = scope;
    return .new(
      icon: Icons.slideshow,
      label: context.t.slideshow,
      onAction: () async =>
          unawaited(context.pushRoute(DriftSlideshowRoute(timeline: ref.read(timelineServiceProvider)))),
    );
  }
}
