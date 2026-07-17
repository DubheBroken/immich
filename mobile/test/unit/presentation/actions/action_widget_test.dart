import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immich_mobile/presentation/actions/action.dart';
import 'package:immich_mobile/presentation/actions/action.widget.dart';
import 'package:immich_ui/immich_ui.dart';

import '../presentation_context.dart';

class _RecordingAction extends BaseAction {
  final void Function() onTap;
  final void Function()? onLong;
  final bool visible;

  const _RecordingAction({required this.onTap, this.onLong, this.visible = true});

  @override
  WidgetAction? resolve(ActionScope scope) {
    if (!visible) {
      return null;
    }
    final onLong = this.onLong;
    return WidgetAction(
      icon: Icons.bug_report_outlined,
      label: 'test',
      onAction: () async => onTap(),
      onSecondaryAction: onLong == null ? null : () async => onLong(),
    );
  }
}

void main() {
  late PresentationContext context;

  setUp(() async {
    context = await PresentationContext.create();
  });

  tearDown(() {
    context.dispose();
  });

  group('ActionIconButtonWidget', () {
    testWidgets('renders nothing when the action is not visible', (tester) async {
      await tester.pumpTestWidget(
        context,
        ActionIconButtonWidget(action: _RecordingAction(onTap: () {}, visible: false)),
      );

      expect(find.byType(ImmichIconButton), findsNothing);
    });

    testWidgets('wires no long press handler when the action has no secondary action', (tester) async {
      await tester.pumpTestWidget(context, ActionIconButtonWidget(action: _RecordingAction(onTap: () {})));

      expect(tester.widget<ImmichIconButton>(find.byType(ImmichIconButton)).onLongPress, isNull);
    });

    testWidgets('tap runs the primary action', (tester) async {
      var taps = 0;
      var longPresses = 0;
      await tester.pumpTestWidget(
        context,
        ActionIconButtonWidget(
          action: _RecordingAction(onTap: () => taps++, onLong: () => longPresses++),
        ),
      );

      await tester.tap(find.byType(ImmichIconButton));
      await tester.pump();

      expect(taps, 1);
      expect(longPresses, 0);
    });

    testWidgets('long press runs the secondary action, not the primary', (tester) async {
      var taps = 0;
      var longPresses = 0;
      await tester.pumpTestWidget(
        context,
        ActionIconButtonWidget(
          action: _RecordingAction(onTap: () => taps++, onLong: () => longPresses++),
        ),
      );

      await tester.longPress(find.byType(ImmichIconButton));
      await tester.pump();

      expect(longPresses, 1);
      expect(taps, 0);
    });
  });
}
