import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:immich_mobile/domain/models/asset/base_asset.model.dart';
import 'package:immich_mobile/generated/translations.g.dart';
import 'package:immich_mobile/presentation/actions/action.dart';
import 'package:immich_mobile/presentation/pages/search/paginated_search.provider.dart';
import 'package:immich_mobile/providers/asset_viewer/asset_viewer.provider.dart';
import 'package:immich_mobile/routing/router.dart';

class SimilarPhotosAction extends BaseAction {
  const SimilarPhotosAction();

  @override
  WidgetAction? resolve(ActionScope scope) {
    final ActionScope(:ref, :context, :assets) = scope;

    if (assets.isEmpty) {
      return null;
    }
    final asset = assets.first;
    if (asset is! RemoteAsset) {
      return null;
    }

    return .new(
      icon: Icons.compare,
      label: context.t.view_similar_photos,
      onAction: () async {
        ref.invalidate(assetViewerProvider);
        ref.invalidate(paginatedSearchProvider);

        ref.read(searchPreFilterProvider.notifier)
          ..clear()
          ..setFilter(
            .new(
              assetId: asset.id,
              people: {},
              location: .new(),
              camera: .new(),
              date: .new(),
              display: .new(isNotInAlbum: false, isArchive: false, isFavorite: false),
              rating: .new(),
              mediaType: .other,
            ),
          );

        unawaited(context.navigateTo(const DriftSearchRoute()));
      },
    );
  }
}
