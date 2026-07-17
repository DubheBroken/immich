import 'package:flutter/material.dart';
import 'package:immich_mobile/domain/models/asset/base_asset.model.dart';
import 'package:immich_mobile/generated/translations.g.dart';
import 'package:immich_mobile/presentation/actions/action.dart';
import 'package:immich_mobile/providers/infrastructure/asset.provider.dart';
import 'package:immich_mobile/providers/infrastructure/asset_viewer/asset.provider.dart';
import 'package:immich_mobile/providers/infrastructure/toast.provider.dart';
import 'package:immich_mobile/utils/asset_filter.dart';
import 'package:immich_mobile/utils/timezone.dart';
import 'package:immich_mobile/widgets/common/date_time_picker.dart';

class EditDateTimeAction extends BaseAction {
  const EditDateTimeAction();

  @override
  WidgetAction? resolve(ActionScope scope) {
    final ActionScope(:authUser, :assets, :context) = scope;
    final owned = AssetFilter(assets).owned(authUser.id);
    final ids = owned.map((asset) => asset.id).toList(growable: false);
    if (ids.isEmpty) {
      return null;
    }

    return .new(
      icon: Icons.edit_calendar_outlined,
      label: context.t.control_bottom_app_bar_edit_time,
      onAction: () => _onAction(scope, ids, owned.firstOrNull),
    );
  }

  Future<void> _onAction(ActionScope scope, List<String> ids, RemoteAsset? origin) async {
    final ActionScope(:ref, :context) = scope;

    DateTime? initialDate;
    String? timeZone;
    Duration? offset;

    final seed = origin;
    if (seed != null) {
      final exif = await ref.read(remoteAssetRepositoryProvider).getExif(seed.id);

      // Use EXIF timezone information if available (matching web app and display behavior)
      DateTime dt = seed.createdAt.toLocal();
      offset = dt.timeZoneOffset;
      if (exif?.dateTimeOriginal != null) {
        timeZone = exif!.timeZone;
        (dt, offset) = applyTimezoneOffset(dateTime: exif.dateTimeOriginal!, timeZone: exif.timeZone);
      }
      initialDate = dt;
    }

    if (!context.mounted) {
      return;
    }

    final dateTime = await showDateTimePicker(
      context: context,
      initialDateTime: initialDate,
      initialTZ: timeZone,
      initialTZOffset: offset,
    );
    if (dateTime == null) {
      return;
    }

    await save(scope, ids, dateTime);
  }

  @visibleForTesting
  Future<void> save(ActionScope scope, List<String> ids, String dateTime) async {
    final ActionScope(:ref, :context) = scope;
    await ref.read(assetServiceProvider).update(ids, dateTime: .some(dateTime));
    ref.invalidate(assetExifProvider);
    ref.read(toastRepositoryProvider).success(context.t.edit_date_and_time_action_prompt(count: ids.length));
  }
}
