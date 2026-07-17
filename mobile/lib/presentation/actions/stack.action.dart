import 'package:flutter/material.dart';
import 'package:immich_mobile/generated/translations.g.dart';
import 'package:immich_mobile/presentation/actions/action.dart';
import 'package:immich_mobile/providers/infrastructure/asset.provider.dart';
import 'package:immich_mobile/providers/infrastructure/toast.provider.dart';
import 'package:immich_mobile/utils/asset_filter.dart';

class StackAction extends BaseAction {
  const StackAction();

  @override
  WidgetAction? resolve(ActionScope scope) {
    final ActionScope(:ref, :context, :authUser, :assets) = scope;

    final owned = AssetFilter(assets).owned(authUser.id);
    // Stack when any owned asset is not yet stacked; otherwise unstack them all.
    final stack = owned.stacked(isStacked: false).isNotEmpty;
    final assetIds = owned.map((asset) => asset.id).toList(growable: false);
    final stackIds = owned.map((asset) => asset.stackId).nonNulls.toList(growable: false);

    if (stack ? assetIds.length <= 1 : stackIds.isEmpty) {
      return null;
    }

    return .new(
      icon: stack ? Icons.filter_none_rounded : Icons.layers_clear_outlined,
      label: stack ? context.t.stack : context.t.unstack,
      onAction: () async {
        if (stack) {
          await ref.read(assetServiceProvider).stack(authUser.id, assetIds);
        } else {
          await ref.read(assetServiceProvider).unstack(stackIds);
        }
        final message = stack
            ? context.t.stacked_assets_count(count: assetIds.length)
            : context.t.unstacked_assets_count(count: assetIds.length);
        ref.read(toastRepositoryProvider).success(stack ? message : message);
      },
    );
  }
}
