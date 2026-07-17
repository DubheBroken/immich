import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immich_mobile/domain/models/asset/base_asset.model.dart';
import 'package:immich_mobile/generated/translations.g.dart';
import 'package:immich_mobile/presentation/actions/lock.action.dart';
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

  RemoteAsset owned({AssetVisibility visibility = .timeline}) =>
      RemoteAssetFactory.create(ownerId: context.currentUser.id, visibility: visibility);

  const action = LockAction();

  group('LockAction', () {
    testWidgets('locks the eligible owned assets', (tester) async {
      final asset = owned();
      final resolved = await tester.runAction(context, action, assets: [asset]);

      expect(resolved!.icon, Icons.lock_rounded);
      expect(resolved.label, StaticTranslations.instance.move_to_locked_folder);
      verify(() => assetService.update([asset.id], visibility: const Some(.locked))).called(1);
    });

    testWidgets('unlocks the eligible owned assets', (tester) async {
      final asset = owned(visibility: .locked);
      final resolved = await tester.runAction(context, action, assets: [asset]);

      expect(resolved!.icon, Icons.lock_open_rounded);
      expect(resolved.label, StaticTranslations.instance.remove_from_locked_folder);
      verify(() => assetService.update([asset.id], visibility: const Some(.timeline))).called(1);
    });

    testWidgets('dispatches on owned state, ignoring assets owned by others', (tester) async {
      final mine = owned(visibility: .locked);
      final theirs = RemoteAssetFactory.create();
      final resolved = await tester.runAction(context, action, assets: [mine, theirs]);

      expect(resolved!.label, StaticTranslations.instance.remove_from_locked_folder);
      verify(() => assetService.update([mine.id], visibility: const Some(.timeline))).called(1);
    });

    testWidgets('batches every eligible owned asset into a single call', (tester) async {
      final first = owned();
      final second = owned();

      await tester.runAction(context, action, assets: [first, second]);

      verify(() => assetService.update([first.id, second.id], visibility: const Some(.locked))).called(1);
    });

    testWidgets('locks only the owned assets not already locked', (tester) async {
      final stale = owned();
      final alreadyLocked = owned(visibility: .locked);

      await tester.runAction(context, action, assets: [stale, alreadyLocked]);

      verify(() => assetService.update([stale.id], visibility: const Some(.locked))).called(1);
    });

    testWidgets('reports the locked count through the toast repository', (tester) async {
      final toast = context.repository.toast;

      await tester.runAction(context, action, assets: [owned(), owned()]);

      final message = verify(() => toast.success(captureAny())).captured.single as String;
      expect(message, StaticTranslations.instance.move_to_lock_folder_action_prompt(count: 2));
    });

    testWidgets('reports the unlocked count through the toast repository', (tester) async {
      final toast = context.repository.toast;

      await tester.runAction(
        context,
        action,
        assets: [
          owned(visibility: .locked),
          owned(visibility: .locked),
        ],
      );

      final message = verify(() => toast.success(captureAny())).captured.single as String;
      expect(message, StaticTranslations.instance.remove_from_lock_folder_action_prompt(count: 2));
    });
  });
}
