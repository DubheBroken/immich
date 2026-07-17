import 'package:flutter/material.dart';
import 'package:immich_mobile/domain/services/tag.service.dart';
import 'package:immich_mobile/generated/translations.g.dart';
import 'package:immich_mobile/presentation/actions/action.dart';
import 'package:immich_mobile/providers/infrastructure/tag.provider.dart';
import 'package:immich_mobile/providers/infrastructure/toast.provider.dart';
import 'package:immich_mobile/utils/asset_filter.dart';
import 'package:immich_mobile/widgets/common/tag_picker.dart';

class TagAction extends BaseAction {
  const TagAction();

  @override
  WidgetAction? resolve(ActionScope scope) {
    final ActionScope(:ref, :context, :authUser, :assets) = scope;

    final assetIds = AssetFilter(assets).owned(authUser.id).map((asset) => asset.id).toList(growable: false);
    if (assetIds.isEmpty) {
      return null;
    }

    return .new(
      icon: Icons.sell_outlined,
      label: context.t.control_bottom_app_bar_add_tags,
      onAction: () async {
        final results = await showTagPickerModal(context: context);
        if (results == null) {
          return;
        }

        await applyTags(scope, assetIds, selected: results.$1, created: results.$2);
      },
    );
  }

  @visibleForTesting
  Future<void> applyTags(
    ActionScope scope,
    List<String> assetIds, {
    required Set<String> selected,
    required Set<String> created,
  }) async {
    final ActionScope(:ref, :context) = scope;

    final tagService = ref.read(tagServiceProvider);
    final tagIds = {...selected};

    if (created.isNotEmpty) {
      final tags = await tagService.upsertTags(created.toList());
      tagIds.addAll(tags.map((tag) => tag.id));
    }
    if (tagIds.isEmpty) {
      return;
    }

    final count = await tagService.bulkTagAssets(assetIds, tagIds.toList());
    ref.invalidate(tagProvider);
    ref.read(toastRepositoryProvider).success(context.t.tagged_assets(count: count));
  }
}
