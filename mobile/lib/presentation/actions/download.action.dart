import 'dart:async';

import 'package:flutter/material.dart';
import 'package:immich_mobile/generated/translations.g.dart';
import 'package:immich_mobile/presentation/actions/action.dart';
import 'package:immich_mobile/providers/background_sync.provider.dart';
import 'package:immich_mobile/repositories/download.repository.dart';
import 'package:immich_mobile/utils/asset_filter.dart';

class DownloadAction extends BaseAction {
  const DownloadAction();

  @override
  WidgetAction? resolve(ActionScope scope) {
    final ActionScope(:ref, :context, :assets) = scope;
    final remoteAssets = AssetFilter(assets).remote().toList(growable: false);
    if (remoteAssets.isEmpty) {
      return null;
    }

    return .new(
      icon: Icons.download,
      label: context.t.download,
      onAction: () async {
        final backgroundSync = ref.read(backgroundSyncProvider);
        await ref.read(downloadRepositoryProvider).downloadAllAssets(remoteAssets);

        unawaited(
          Future.delayed(const Duration(seconds: 1), () async {
            await backgroundSync.syncLocal();
            await backgroundSync.hashAssets();
          }),
        );
      },
    );
  }
}
