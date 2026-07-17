import 'package:flutter/material.dart';
import 'package:immich_mobile/generated/translations.g.dart';
import 'package:immich_mobile/presentation/actions/action.dart';
import 'package:immich_mobile/providers/infrastructure/asset.provider.dart';
import 'package:immich_mobile/providers/infrastructure/toast.provider.dart';
import 'package:immich_mobile/utils/asset_filter.dart';

class LockAction extends BaseAction {
  const LockAction();

  @override
  WidgetAction? resolve(ActionScope scope) {
    final owned = AssetFilter(scope.assets).owned(scope.authUser.id);
    final lock = owned.locked(isLocked: false).isNotEmpty;
    final ids = owned.locked(isLocked: !lock).map((asset) => asset.id).toList(growable: false);
    if (ids.isEmpty) {
      return null;
    }

    return .new(
      icon: lock ? Icons.lock_rounded : Icons.lock_open_rounded,
      label: lock ? scope.context.t.move_to_locked_folder : scope.context.t.remove_from_locked_folder,
      onAction: () => _onAction(scope, ids, lock: lock),
    );
  }

  Future<void> _onAction(ActionScope scope, List<String> ids, {required bool lock}) async {
    final ActionScope(:ref, :context) = scope;

    await ref.read(assetServiceProvider).update(ids, visibility: .some(lock ? .locked : .timeline));
    final message = lock
        ? context.t.move_to_lock_folder_action_prompt(count: ids.length)
        : context.t.remove_from_lock_folder_action_prompt(count: ids.length);
    ref.read(toastRepositoryProvider).success(message);
  }
}
