import 'package:flutter/material.dart';
import 'package:immich_mobile/generated/translations.g.dart';
import 'package:immich_mobile/presentation/actions/action.dart';
import 'package:immich_mobile/providers/infrastructure/asset.provider.dart';
import 'package:immich_mobile/providers/infrastructure/toast.provider.dart';
import 'package:immich_mobile/utils/asset_filter.dart';

class FavoriteAction extends BaseAction {
  const FavoriteAction();

  @override
  WidgetAction? resolve(ActionScope scope) {
    final ActionScope(:ref, :context, :authUser, :assets) = scope;

    final owned = AssetFilter(assets).owned(authUser.id);
    final favorite = owned.favorite(isFavorite: false).isNotEmpty;
    final ids = owned.favorite(isFavorite: !favorite).map((asset) => asset.id).toList(growable: false);
    if (ids.isEmpty) {
      return null;
    }

    return .new(
      icon: favorite ? Icons.favorite_border_rounded : Icons.favorite_rounded,
      label: favorite ? context.t.favorite : context.t.unfavorite,
      onAction: () => _onAction(scope, ids, favorite: favorite),
    );
  }

  Future<void> _onAction(ActionScope scope, List<String> ids, {required bool favorite}) async {
    final ActionScope(:ref, :context) = scope;

    await ref.read(assetServiceProvider).update(ids, isFavorite: .some(favorite));
    final message = favorite
        ? context.t.favorite_action_prompt(count: ids.length)
        : context.t.unfavorite_action_prompt(count: ids.length);
    ref.read(toastRepositoryProvider).success(message);
  }
}
