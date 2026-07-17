import 'package:flutter/material.dart';
import 'package:immich_mobile/generated/translations.g.dart';
import 'package:immich_mobile/presentation/actions/action.dart';
import 'package:immich_mobile/providers/infrastructure/asset.provider.dart';
import 'package:immich_mobile/providers/infrastructure/toast.provider.dart';
import 'package:immich_mobile/utils/asset_filter.dart';

class ArchiveAction extends BaseAction {
  const ArchiveAction();

  @override
  WidgetAction? resolve(ActionScope scope) {
    final ActionScope(:context, :authUser, :assets) = scope;
    final owned = AssetFilter(assets).owned(authUser.id);

    final archive = owned.archived(isArchived: false).isNotEmpty;
    final ids = owned.archived(isArchived: !archive).map((asset) => asset.id).toList(growable: false);
    if (ids.isEmpty) {
      return null;
    }

    return .new(
      icon: archive ? Icons.archive_outlined : Icons.unarchive_outlined,
      label: archive ? context.t.archive : context.t.unarchive,
      onAction: () => _onAction(scope, ids, archive: archive),
    );
  }

  Future<void> _onAction(ActionScope scope, List<String> ids, {required bool archive}) async {
    final ActionScope(:ref, :context) = scope;

    await ref.read(assetServiceProvider).update(ids, visibility: .some(archive ? .archive : .timeline));
    final message = archive
        ? context.t.archive_action_prompt(count: ids.length)
        : context.t.unarchive_action_prompt(count: ids.length);
    ref.read(toastRepositoryProvider).success(message);
  }
}
