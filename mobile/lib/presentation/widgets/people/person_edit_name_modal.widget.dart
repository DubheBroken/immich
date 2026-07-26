import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/domain/models/person.model.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/extensions/translate_extensions.dart';
import 'package:immich_mobile/providers/infrastructure/people.provider.dart';
import 'package:immich_mobile/utils/debug_print.dart';
import 'package:immich_mobile/utils/people.utils.dart';
import 'package:immich_mobile/widgets/common/immich_toast.dart';

class DriftPersonNameEditForm extends ConsumerStatefulWidget {
  final DriftPerson person;

  const DriftPersonNameEditForm({super.key, required this.person});

  @override
  ConsumerState<DriftPersonNameEditForm> createState() => _DriftPersonNameEditFormState();
}

class _DriftPersonNameEditFormState extends ConsumerState<DriftPersonNameEditForm> {
  late TextEditingController _formController;

  @override
  void initState() {
    super.initState();
    _formController = TextEditingController(text: widget.person.name);
  }

  void onEdit(String personId, String newName) async {
    if (newName.isEmpty || newName == widget.person.name) {
      context.pop<String>(null);
      return;
    }

    try {
      final service = ref.read(driftPeopleServiceProvider);
      final existingPeople = await service.getPeopleByName(newName, excludePersonId: personId);

      if (existingPeople.isNotEmpty && context.mounted) {
        final shouldMerge = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              "face_merge_confirmation_title",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ).tr(),
            content: Text("face_merge_confirmation_message".t(args: {'name': newName})),
            actions: [
              TextButton(
                onPressed: () => ctx.pop(false),
                child: Text(
                  "face_merge_keep_separate",
                  style: TextStyle(color: Colors.red[300], fontWeight: FontWeight.bold),
                ).tr(),
              ),
              TextButton(
                onPressed: () => ctx.pop(true),
                child: Text(
                  "face_merge_confirm",
                  style: TextStyle(color: context.primaryColor, fontWeight: FontWeight.bold),
                ).tr(),
              ),
            ],
          ),
        );

        if (shouldMerge == true && context.mounted) {
          final sourceIds = existingPeople.map((p) => p.id).toList();
          await service.mergePerson(personId, sourceIds);
          await service.updateName(personId, newName);
          ref.invalidate(driftGetAllPeopleProvider);
          context.pop(nameEditMergeDone);
        } else if (context.mounted) {
          // User chose to keep separate, proceed with normal rename
          final result = await service.updateName(personId, newName);
          if (result != 0) {
            ref.invalidate(driftGetAllPeopleProvider);
            context.pop<String>(newName);
          }
        }
        return;
      }

      final result = await service.updateName(personId, newName);
      if (result != 0) {
        ref.invalidate(driftGetAllPeopleProvider);
        context.pop<String>(newName);
      }
    } catch (error) {
      dPrint(() => 'Error updating name: $error');

      if (!context.mounted) {
        return;
      }

      ImmichToast.show(
        context: context,
        msg: 'scaffold_body_error_occurred'.t(context: context),
        gravity: ToastGravity.BOTTOM,
        toastType: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("edit_name", style: TextStyle(fontWeight: FontWeight.bold)).tr(),
      content: SingleChildScrollView(
        child: TextFormField(
          controller: _formController,
          textCapitalization: TextCapitalization.words,
          autofocus: true,
          decoration: InputDecoration(hintText: 'name'.tr(), border: const OutlineInputBorder()),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(null),
          child: Text(
            "cancel",
            style: TextStyle(color: Colors.red[300], fontWeight: FontWeight.bold),
          ).tr(),
        ),
        TextButton(
          onPressed: () => onEdit(widget.person.id, _formController.text),
          child: Text(
            "save",
            style: TextStyle(color: context.primaryColor, fontWeight: FontWeight.bold),
          ).tr(),
        ),
      ],
    );
  }
}
