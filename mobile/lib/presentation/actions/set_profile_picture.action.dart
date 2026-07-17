import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:immich_mobile/generated/translations.g.dart';
import 'package:immich_mobile/presentation/actions/action.dart';
import 'package:immich_mobile/routing/router.dart';

class SetProfilePictureAction extends BaseAction {
  const SetProfilePictureAction();

  @override
  WidgetAction? resolve(ActionScope scope) {
    final ActionScope(:context, :assets) = scope;

    if (assets.isEmpty) {
      return null;
    }
    final asset = assets.first;

    return .new(
      icon: Icons.account_circle_outlined,
      label: context.t.set_as_profile_picture,
      onAction: () async => unawaited(context.pushRoute(ProfilePictureCropRoute(asset: asset))),
    );
  }
}
