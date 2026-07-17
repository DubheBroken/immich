import 'dart:async';

import 'package:flutter/material.dart';
import 'package:immich_mobile/generated/translations.g.dart';
import 'package:immich_mobile/presentation/actions/action.dart';
import 'package:immich_mobile/providers/cast.provider.dart';
import 'package:immich_mobile/widgets/asset_viewer/cast_dialog.dart';

class CastAction extends BaseAction {
  const CastAction();

  @override
  WidgetAction? resolve(ActionScope scope) {
    final ActionScope(:ref, :context) = scope;
    final casting = ref.watch(castProvider.select((state) => state.isCasting));

    return .new(
      icon: casting ? Icons.cast_connected_rounded : Icons.cast_rounded,
      label: context.t.cast,
      onAction: () async => unawaited(showDialog(context: context, builder: (_) => const CastDialog())),
    );
  }
}
