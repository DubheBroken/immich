import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:immich_mobile/generated/translations.g.dart';
import 'package:immich_mobile/presentation/actions/action.dart';
import 'package:immich_mobile/routing/router.dart';
import 'package:immich_mobile/utils/asset_filter.dart';

class ShareLinkAction extends BaseAction {
  const ShareLinkAction();

  @override
  WidgetAction? resolve(ActionScope scope) {
    final ActionScope(:context, :assets) = scope;

    final remoteIds = AssetFilter(assets).remote().map((asset) => asset.id).toList(growable: false);
    if (remoteIds.isEmpty) {
      return null;
    }

    return .new(
      icon: Icons.link_rounded,
      label: context.t.share_link,
      onAction: () async => unawaited(context.pushRoute(SharedLinkEditRoute(assetsList: remoteIds))),
    );
  }
}
