import 'package:flutter/material.dart';
import 'package:immich_mobile/generated/translations.g.dart';
import 'package:immich_mobile/presentation/actions/action.dart';
import 'package:immich_mobile/providers/infrastructure/album.provider.dart';
import 'package:immich_mobile/providers/infrastructure/toast.provider.dart';
import 'package:immich_mobile/utils/asset_filter.dart';

class RemoveFromAlbumAction extends BaseAction {
  final String albumId;

  const RemoveFromAlbumAction({required this.albumId});

  @override
  WidgetAction? resolve(ActionScope scope) {
    final ActionScope(:context, :assets) = scope;
    final ids = AssetFilter(assets).map((asset) => asset.remoteId).nonNulls.toList(growable: false);
    if (ids.isEmpty) {
      return null;
    }

    return .new(
      icon: Icons.remove_circle_outline,
      label: context.t.remove_from_album,
      onAction: () => _onAction(scope, ids),
    );
  }

  Future<void> _onAction(ActionScope scope, List<String> ids) async {
    final ActionScope(:ref, :context) = scope;
    final count = await ref.read(remoteAlbumServiceProvider).removeAssets(albumId: albumId, assetIds: ids);
    ref.read(toastRepositoryProvider).success(context.t.remove_from_album_action_prompt(count: count));
  }
}
