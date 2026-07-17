import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/presentation/actions/action.widget.dart';
import 'package:immich_mobile/presentation/actions/delete.action.dart';
import 'package:immich_mobile/presentation/actions/download.action.dart';
import 'package:immich_mobile/presentation/actions/lock.action.dart';
import 'package:immich_mobile/presentation/actions/share.action.dart';
import 'package:immich_mobile/presentation/actions/timeline.action.dart';
import 'package:immich_mobile/presentation/widgets/bottom_sheet/base_bottom_sheet.widget.dart';

class LockedFolderBottomSheet extends ConsumerWidget {
  const LockedFolderBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BaseBottomSheet(
      initialChildSize: 0.25,
      maxChildSize: 0.4,
      shouldCloseOnMinExtent: false,
      actions: [
        const ActionColumnButtonWidget(source: .timeline, action: ShareAction()),
        ...const [DownloadAction(), DeleteAction(), LockAction()].map(
          (action) => ActionColumnButtonWidget(
            source: .timeline,
            action: TimelineAction(action: action),
          ),
        ),
      ],
    );
  }
}
