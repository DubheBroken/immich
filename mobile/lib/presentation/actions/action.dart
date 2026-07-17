import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/constants/enums.dart';
import 'package:immich_mobile/domain/models/asset/base_asset.model.dart';
import 'package:immich_mobile/domain/models/user.model.dart';
import 'package:immich_mobile/providers/asset_viewer/asset_viewer.provider.dart';
import 'package:immich_mobile/providers/timeline/multiselect.provider.dart';
import 'package:immich_mobile/providers/user.provider.dart';

export 'package:immich_mobile/constants/enums.dart' show ActionSource;

extension ActionSourceAssets on ActionSource {
  Iterable<BaseAsset> select(WidgetRef ref) => switch (this) {
    .timeline => ref.watch(multiSelectProvider.select((s) => s.selectedAssets)),
    .viewer => switch (ref.watch(assetViewerProvider.select((s) => s.currentAsset))) {
      final a? => [a],
      null => const [],
    },
  };
}

class ActionScope {
  final Iterable<BaseAsset> assets;
  final UserDto authUser;
  final WidgetRef ref;
  BuildContext get context => ref.context;

  const ActionScope({required this.assets, required this.authUser, required this.ref});

  static ActionScope of(WidgetRef ref, ActionSource? source) {
    final authUser = ref.watch(currentUserProvider);
    if (authUser == null) {
      throw StateError('Auth user is not available in ActionScope');
    }

    return ActionScope(assets: source?.select(ref) ?? const [], authUser: authUser, ref: ref);
  }
}

abstract class BaseAction {
  const BaseAction();

  // Return null if the action is not applicable in the given scope
  WidgetAction? resolve(ActionScope scope);
}

class WidgetAction {
  final IconData icon;
  final String label;
  final Future<void> Function() onAction;
  final Future<void> Function()? onSecondaryAction;

  const WidgetAction({required this.icon, required this.label, required this.onAction, this.onSecondaryAction});
}
