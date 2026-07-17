import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/domain/models/asset/base_asset.model.dart';
import 'package:immich_mobile/extensions/platform_extensions.dart';
import 'package:immich_mobile/generated/translations.g.dart';
import 'package:immich_mobile/presentation/actions/action.dart';
import 'package:immich_mobile/providers/infrastructure/asset.provider.dart';
import 'package:immich_mobile/providers/infrastructure/store.provider.dart';
import 'package:immich_mobile/providers/infrastructure/toast.provider.dart';
import 'package:immich_mobile/providers/server_info.provider.dart';
import 'package:immich_mobile/services/cleanup.service.dart';
import 'package:immich_mobile/utils/asset_filter.dart';
import 'package:immich_mobile/widgets/common/confirm_dialog.dart';

class DeleteAction extends BaseAction {
  const DeleteAction();

  @override
  WidgetAction? resolve(ActionScope scope) {
    final ActionScope(:ref, :authUser, :assets, :context) = scope;

    final localIds = <String>[];
    final ownedRemote = <RemoteAsset>[];
    for (final asset in assets) {
      if (asset.localId case final id?) {
        localIds.add(id);
      }
      if (asset case final RemoteAsset remote when remote.ownerId == authUser.id) {
        ownedRemote.add(remote);
      }
    }
    final remoteIds = ownedRemote.map((asset) => asset.id).toList(growable: false);
    if (remoteIds.isEmpty && localIds.isEmpty) {
      return null;
    }

    // Assets already in trash or in locked page should be permanently deleted irrespective of the trash feature being enabled
    final permanentDelete = ownedRemote.every((asset) => asset.isTrashed || asset.isLocked);
    final trash = !permanentDelete && ref.watch(serverInfoProvider.select((state) => state.serverFeatures.trash));

    return .new(
      icon: Icons.delete_outline,
      label: trash ? context.t.trash : context.t.delete,
      onAction: () => _onAction(scope, localIds: localIds, remoteIds: remoteIds, trash: trash),
    );
  }

  Future<void> _onAction(
    ActionScope scope, {
    required List<String> localIds,
    required List<String> remoteIds,
    required bool trash,
  }) async {
    final ActionScope(:ref, :context) = scope;
    final toast = ref.read(toastRepositoryProvider);

    // Local-only
    // Single prompt on iOS & Android (without MANAGE_MEDIA)
    // No prompt on Android (with MANAGE_MEDIA)
    if (remoteIds.isEmpty) {
      if (localIds.isEmpty) {
        return;
      }

      final count = await cleanupLocalAssets(ref, assetIds: localIds);
      if (!context.mounted || count <= 0) {
        return;
      }
      toast.success(context.t.cleanup_deleted_assets(count: count));
      return;
    }

    // Trash
    // No prompt on Android (with MANAGE_MEDIA)
    // Single prompt on iOS & Android (without MANAGE_MEDIA)
    // TODO(shenlong): Handle the native prompt response and skip deleting trash when user cancels the prompt
    if (trash) {
      if (localIds.isNotEmpty) {
        await cleanupLocalAssets(ref, assetIds: localIds);
        if (!context.mounted) {
          return;
        }
      }
      await ref.read(assetServiceProvider).trash(remoteIds);
      toast.success(context.t.trash_action_prompt(count: remoteIds.length));
      return;
    }

    // Permanent delete
    // Single prompt on Android (with MANAGE_MEDIA)
    // Double prompts on iOS & Android (without MANAGE_MEDIA)
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) =>
          const ConfirmDialog(title: 'delete_dialog_title', content: 'delete_dialog_alert', ok: 'delete_permanently'),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    // Perform server deletion first so we don't remove the only local copy if the server delete fails
    await ref.read(assetServiceProvider).delete(remoteIds);
    if (localIds.isNotEmpty && context.mounted) {
      await cleanupLocalAssets(ref, assetIds: localIds, requestPrompt: false);
    }

    if (!context.mounted) {
      return;
    }

    toast.success(context.t.delete_permanently_action_prompt(count: remoteIds.length));
  }
}

class CleanupLocalAction extends BaseAction {
  const CleanupLocalAction();

  @override
  WidgetAction? resolve(ActionScope scope) {
    final ids = AssetFilter(scope.assets).backedUp().map((asset) => asset.localId).nonNulls.toList(growable: false);
    if (ids.isEmpty) {
      return null;
    }

    return .new(
      icon: Icons.no_cell_outlined,
      label: scope.context.t.control_bottom_app_bar_delete_from_local,
      onAction: () => _onAction(scope, ids),
    );
  }

  Future<void> _onAction(ActionScope scope, List<String> ids) async {
    final ActionScope(:ref, :context) = scope;

    final count = await cleanupLocalAssets(ref, assetIds: ids);
    if (!context.mounted || count <= 0) {
      return;
    }
    ref.read(toastRepositoryProvider).success(context.t.cleanup_deleted_assets(count: count));
  }
}

@visibleForTesting
Future<int> cleanupLocalAssets(WidgetRef ref, {required List<String> assetIds, bool requestPrompt = true}) async {
  final context = ref.context;

  /// OS prompts on iOS & Android (without MANAGE_MEDIA)
  /// Custom prompt on Android (with MANAGE_MEDIA)
  final requireUserPrompt =
      requestPrompt && CurrentPlatform.isAndroid && ref.read(storeServiceProvider).get(.manageLocalMediaAndroid, false);
  if (requireUserPrompt) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: context.t.move_to_device_trash,
        content: context.t.free_up_space_description,
        ok: context.t.ok,
      ),
    );

    if (confirmed != true) {
      return 0;
    }
  }

  if (!context.mounted) {
    return 0;
  }

  return await ref.read(cleanupServiceProvider).deleteLocalAssets(assetIds);
}
