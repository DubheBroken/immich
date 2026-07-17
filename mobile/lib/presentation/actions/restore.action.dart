import 'package:flutter/material.dart';
import 'package:immich_mobile/generated/translations.g.dart';
import 'package:immich_mobile/presentation/actions/action.dart';
import 'package:immich_mobile/providers/infrastructure/asset.provider.dart';
import 'package:immich_mobile/providers/infrastructure/toast.provider.dart';
import 'package:immich_mobile/utils/asset_filter.dart';

class RestoreAction extends BaseAction {
  const RestoreAction();

  @override
  WidgetAction? resolve(ActionScope scope) {
    final ActionScope(:ref, :context, :authUser, :assets) = scope;
    final ids = AssetFilter(assets).owned(authUser.id).trashed().map((asset) => asset.id).toList(growable: false);
    if (ids.isEmpty) {
      return null;
    }

    return .new(
      icon: Icons.history_rounded,
      label: context.t.restore,
      onAction: () async {
        await ref.read(assetServiceProvider).restoreTrash(ids);
        ref.read(toastRepositoryProvider).success(context.t.assets_restored_count(count: ids.length));
      },
    );
  }
}
