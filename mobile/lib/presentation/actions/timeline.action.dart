import 'package:immich_mobile/presentation/actions/action.dart';
import 'package:immich_mobile/providers/timeline/multiselect.provider.dart';

/// Decorates an action so the multi-select is cleared after it runs.
class TimelineAction extends BaseAction {
  final BaseAction action;

  const TimelineAction({required this.action});

  @override
  WidgetAction? resolve(ActionScope scope) {
    final resolved = action.resolve(scope);
    if (resolved == null) {
      return null;
    }

    void reset() => scope.ref.read(multiSelectProvider.notifier).reset();
    final onSecondaryAction = resolved.onSecondaryAction;

    return WidgetAction(
      icon: resolved.icon,
      label: resolved.label,
      onAction: () async {
        await resolved.onAction();
        reset();
      },
      onSecondaryAction: onSecondaryAction == null
          ? null
          : () async {
              await onSecondaryAction();
              reset();
            },
    );
  }
}
