import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/presentation/actions/action.dart';
import 'package:immich_mobile/utils/error_handler.dart';
import 'package:immich_ui/immich_ui.dart';

typedef _ActionWidgetScope = ({
  IconData icon,
  String label,
  FutureOr<void> Function() onAction,
  FutureOr<void> Function()? onSecondaryAction,
});

class _ActionWidget extends ConsumerWidget {
  final BaseAction action;
  final ActionSource? source;
  final Widget Function(_ActionWidgetScope context) builder;

  const _ActionWidget({required this.action, required this.builder, this.source});

  Future<void> _guard(Future<void> Function() handler) async {
    try {
      await handler();
    } catch (error, stackTrace) {
      handleError(error, stack: stackTrace, description: 'Action failed: ${action.runtimeType}');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (action.resolve(ActionScope.of(ref, source)) case final resolved?) {
      final onSecondaryAction = resolved.onSecondaryAction;
      return builder((
        icon: resolved.icon,
        label: resolved.label,
        onAction: () => _guard(resolved.onAction),
        onSecondaryAction: onSecondaryAction == null ? null : () => _guard(onSecondaryAction),
      ));
    }

    return const SizedBox.shrink();
  }
}

class ActionIconButtonWidget extends StatelessWidget {
  final BaseAction action;
  final ActionSource? source;
  final ImmichVariant variant;

  const ActionIconButtonWidget({super.key, required this.action, this.source, this.variant = .ghost});

  @override
  Widget build(BuildContext context) => _ActionWidget(
    action: action,
    source: source,
    builder: (ctx) =>
        ImmichIconButton(icon: ctx.icon, onPressed: ctx.onAction, onLongPress: ctx.onSecondaryAction, variant: variant),
  );
}

class ActionButtonWidget extends StatelessWidget {
  final BaseAction action;
  final ActionSource? source;
  final ImmichVariant variant;

  const ActionButtonWidget({super.key, required this.action, this.source, this.variant = .ghost});

  @override
  Widget build(BuildContext context) => _ActionWidget(
    action: action,
    source: source,
    builder: (ctx) => ImmichTextButton(
      labelText: ctx.label,
      icon: ctx.icon,
      onPressed: ctx.onAction,
      onLongPress: ctx.onSecondaryAction,
      variant: variant,
    ),
  );
}

class ActionColumnButtonWidget extends StatelessWidget {
  final BaseAction action;
  final ActionSource? source;

  const ActionColumnButtonWidget({super.key, required this.action, this.source});

  @override
  Widget build(BuildContext context) => _ActionWidget(
    action: action,
    source: source,
    builder: (ctx) => ImmichColumnButton(
      icon: ctx.icon,
      label: ctx.label,
      onPressed: ctx.onAction,
      onLongPress: ctx.onSecondaryAction,
    ),
  );
}

class ActionMenuItemWidget extends StatelessWidget {
  final BaseAction action;
  final ActionSource? source;

  const ActionMenuItemWidget({super.key, required this.action, this.source});

  @override
  Widget build(BuildContext context) => _ActionWidget(
    action: action,
    source: source,
    builder: (ctx) => ImmichMenuItem(icon: ctx.icon, label: ctx.label, onPressed: ctx.onAction),
  );
}
