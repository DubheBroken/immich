import 'package:flutter/material.dart';
import 'package:immich_mobile/domain/models/asset/base_asset.model.dart';
import 'package:immich_mobile/generated/translations.g.dart';
import 'package:immich_mobile/presentation/actions/action.dart';
import 'package:immich_mobile/providers/infrastructure/asset.provider.dart';
import 'package:immich_mobile/providers/infrastructure/asset_viewer/asset.provider.dart';
import 'package:immich_mobile/providers/infrastructure/toast.provider.dart';
import 'package:immich_mobile/widgets/common/location_picker.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class EditLocationAction extends BaseAction {
  const EditLocationAction();

  @override
  WidgetAction? resolve(ActionScope scope) {
    final ActionScope(:authUser, :assets, :context) = scope;
    final owned = assets
        .whereType<RemoteAsset>()
        .where((asset) => asset.ownerId == authUser.id)
        .toList(growable: false);
    final ids = owned.map((asset) => asset.id).toList(growable: false);
    if (ids.isEmpty) {
      return null;
    }

    return .new(
      icon: Icons.edit_location_alt_outlined,
      label: context.t.control_bottom_app_bar_edit_location,
      onAction: () => _onAction(scope, ids, owned.length == 1 ? owned.first : null),
    );
  }

  Future<void> _onAction(ActionScope scope, List<String> ids, RemoteAsset? origin) async {
    final ActionScope(:ref, :context) = scope;

    LatLng? initialLatLng;
    final seed = origin;
    if (seed != null) {
      final exif = await ref.read(remoteAssetRepositoryProvider).getExif(seed.id);
      if (exif?.latitude != null && exif?.longitude != null) {
        initialLatLng = LatLng(exif!.latitude!, exif.longitude!);
      }
    }

    if (!context.mounted) {
      return;
    }

    final location = await showLocationPicker(context: context, initialLatLng: initialLatLng);
    if (location == null) {
      return;
    }

    await save(scope, ids, location);
  }

  @visibleForTesting
  Future<void> save(ActionScope scope, List<String> ids, LatLng location) async {
    final ActionScope(:ref, :context) = scope;
    await ref.read(assetServiceProvider).update(ids, location: .some(location));
    ref.invalidate(assetExifProvider);
    ref.read(toastRepositoryProvider).success(context.t.edit_location_action_prompt(count: ids.length));
  }
}
