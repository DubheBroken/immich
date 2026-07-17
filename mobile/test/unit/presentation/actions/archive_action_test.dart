import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immich_mobile/domain/models/asset/base_asset.model.dart';
import 'package:immich_mobile/generated/translations.g.dart';
import 'package:immich_mobile/presentation/actions/archive.action.dart';
import 'package:immich_mobile/utils/option.dart';
import 'package:mocktail/mocktail.dart';

import '../../../domain/service.mock.dart';
import '../../factories/remote_asset_factory.dart';
import '../presentation_context.dart';

void main() {
  late PresentationContext context;
  late MockAssetService assetService;

  setUp(() async {
    context = await PresentationContext.create();
    assetService = context.service.asset.service;
  });

  tearDown(() {
    context.dispose();
  });

  RemoteAsset owned({AssetVisibility visibility = AssetVisibility.timeline}) =>
      RemoteAssetFactory.create(ownerId: context.currentUser.id, visibility: visibility);

  const action = ArchiveAction();

  group('ArchiveAction', () {
    testWidgets('archives the eligible owned assets', (tester) async {
      final asset = owned();
      final resolved = await tester.runAction(context, action, assets: [asset]);

      expect(resolved!.icon, Icons.archive_outlined);
      expect(resolved.label, StaticTranslations.instance.archive);
      verify(() => assetService.update([asset.id], visibility: const Some(AssetVisibility.archive))).called(1);
    });

    testWidgets('unarchive the eligible owned assets', (tester) async {
      final asset = owned(visibility: .archive);
      final resolved = await tester.runAction(context, action, assets: [asset]);

      expect(resolved!.icon, Icons.unarchive_outlined);
      expect(resolved.label, StaticTranslations.instance.unarchive);
      verify(() => assetService.update([asset.id], visibility: const Some(AssetVisibility.timeline))).called(1);
    });

    testWidgets('dispatches on owned state, ignoring assets owned by others', (tester) async {
      final mine = owned(visibility: .archive);
      final theirs = RemoteAssetFactory.create();
      final resolved = await tester.runAction(context, action, assets: [mine, theirs]);

      expect(resolved!.label, StaticTranslations.instance.unarchive);
      verify(() => assetService.update([mine.id], visibility: const Some(AssetVisibility.timeline))).called(1);
    });

    testWidgets('batches every eligible owned asset into a single call', (tester) async {
      final first = owned();
      final second = owned();

      await tester.runAction(context, action, assets: [first, second]);

      verify(
        () => assetService.update([first.id, second.id], visibility: const Some(AssetVisibility.archive)),
      ).called(1);
    });

    testWidgets('archives only the owned assets not already archived', (tester) async {
      final stale = owned();
      final alreadyArchived = owned(visibility: .archive);

      await tester.runAction(context, action, assets: [stale, alreadyArchived]);

      verify(() => assetService.update([stale.id], visibility: const Some(AssetVisibility.archive))).called(1);
    });

    testWidgets('reports the archived count through the toast repository', (tester) async {
      final toast = context.repository.toast;

      await tester.runAction(context, action, assets: [owned(), owned()]);

      final message = verify(() => toast.success(captureAny())).captured.single as String;
      expect(message, StaticTranslations.instance.archive_action_prompt(count: 2));
    });

    testWidgets('reports the unarchive count through the toast repository', (tester) async {
      final toast = context.repository.toast;

      await tester.runAction(
        context,
        action,
        assets: [
          owned(visibility: .archive),
          owned(visibility: .archive),
        ],
      );

      final message = verify(() => toast.success(captureAny())).captured.single as String;
      expect(message, StaticTranslations.instance.unarchive_action_prompt(count: 2));
    });
  });
}
