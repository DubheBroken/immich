import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:immich_mobile/generated/translations.g.dart';
import 'package:immich_mobile/presentation/actions/action.dart';
import 'package:immich_mobile/providers/infrastructure/setting.provider.dart';
import 'package:immich_mobile/routing/router.dart';

class AssetDebugAction extends BaseAction {
  const AssetDebugAction();

  @override
  WidgetAction? resolve(ActionScope scope) {
    final ActionScope(:ref, :context) = scope;
    final assets = scope.assets.toList(growable: false);

    final enabled = ref.watch(settingsProvider.notifier).get(.advancedTroubleshooting);
    if (!enabled || assets.length != 1) {
      return null;
    }

    return .new(
      icon: Icons.help_outline_rounded,
      label: context.t.troubleshoot,
      onAction: () async => unawaited(context.pushRoute(AssetTroubleshootRoute(asset: assets.first))),
    );
  }
}
