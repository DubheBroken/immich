import 'package:flutter/material.dart';
import 'package:immich_mobile/domain/services/timeline.service.dart';
import 'package:immich_mobile/entities/store.entity.dart';
import 'package:immich_mobile/generated/translations.g.dart';
import 'package:immich_mobile/presentation/actions/action.dart';
import 'package:url_launcher/url_launcher.dart';

class OpenInBrowserAction extends BaseAction {
  final TimelineOrigin origin;

  const OpenInBrowserAction({required this.origin});

  @override
  WidgetAction? resolve(ActionScope scope) {
    final ActionScope(:context, :assets) = scope;

    if (assets.isEmpty) {
      return null;
    }
    final remoteId = assets.first.remoteId;
    if (remoteId == null) {
      return null;
    }

    return .new(
      icon: Icons.open_in_browser,
      label: context.t.open_in_browser,
      onAction: () async {
        final serverEndpoint = Store.get(.serverEndpoint).replaceFirst('/api', '');
        final originPath = switch (origin) {
          .favorite => '/favorites',
          .trash => '/trash',
          .archive => '/archive',
          _ => '',
        };

        final url = Uri.parse('$serverEndpoint$originPath/photos/$remoteId');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: .externalApplication);
        }
      },
    );
  }
}
