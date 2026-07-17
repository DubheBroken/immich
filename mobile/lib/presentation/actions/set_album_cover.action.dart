import 'package:flutter/material.dart';
import 'package:immich_mobile/generated/translations.g.dart';
import 'package:immich_mobile/presentation/actions/action.dart';
import 'package:immich_mobile/providers/infrastructure/album.provider.dart';
import 'package:immich_mobile/providers/infrastructure/toast.provider.dart';
import 'package:immich_mobile/utils/asset_filter.dart';

class SetAlbumCoverAction extends BaseAction {
  final String albumId;

  const SetAlbumCoverAction({required this.albumId});

  @override
  WidgetAction? resolve(ActionScope scope) {
    final ActionScope(:context, :assets) = scope;
    final ids = AssetFilter(assets).map((asset) => asset.remoteId).nonNulls.toList(growable: false);
    if (ids.length != 1) {
      return null;
    }

    return .new(
      icon: Icons.image_outlined,
      label: context.t.set_as_album_cover,
      onAction: () => _onAction(scope, ids.first),
    );
  }

  Future<void> _onAction(ActionScope scope, String assetId) async {
    final ActionScope(:ref, :context) = scope;
    await ref.read(remoteAlbumServiceProvider).updateAlbum(albumId, thumbnailAssetId: assetId);
    ref.read(toastRepositoryProvider).success(context.t.album_cover_updated);
  }
}
