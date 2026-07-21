import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/extensions/translate_extensions.dart';
import 'package:immich_mobile/providers/infrastructure/people.provider.dart';
import 'package:immich_mobile/widgets/common/immich_toast.dart';
import 'package:immich_mobile/widgets/common/search_field.dart';
import 'package:immich_mobile/presentation/widgets/images/remote_image_provider.dart';
import 'package:immich_mobile/utils/image_url_builder.dart';

@RoutePage()
class DriftMergePeoplePage extends ConsumerStatefulWidget {
  final String personId;

  const DriftMergePeoplePage({super.key, required this.personId});

  @override
  ConsumerState<DriftMergePeoplePage> createState() => _DriftMergePeoplePageState();
}

class _DriftMergePeoplePageState extends ConsumerState<DriftMergePeoplePage> {
  final List<String> _selectedPersonIds = [];
  String? _search;
  bool _isMerging = false;

  void _toggleSelection(String personId)
  {
    setState(() {
      if (_selectedPersonIds.contains(personId)) {
        _selectedPersonIds.remove(personId);
      } else {
        if (_selectedPersonIds.length < 4) {
          _selectedPersonIds.add(personId);
        } else {
          ImmichToast.show(
            context: context,
            msg: 'merge_people_limit'.t(context: context),
            toastType: ToastType.info,
          );
        }
      }
    });
  }

  Future<void> _mergePeople() async
  {
    if (_selectedPersonIds.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('merge_people'.t(context: dialogContext)),
        content: Text('merge_people_prompt'.t(context: dialogContext)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('cancel'.t(context: dialogContext)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('merge'.t(context: dialogContext)),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isMerging = true;
    });

    try {
      final peopleService = ref.read(driftPeopleServiceProvider);
      final result = await peopleService.mergePerson(widget.personId, _selectedPersonIds);

      if (result && mounted) {
        ref.invalidate(driftGetAllPeopleProvider);
        if (context.mounted) {
          context.router.pop(true);
        }
      } else if (mounted) {
        if (context.mounted) {
          ImmichToast.show(
            context: context,
            msg: 'cannot_merge_people'.t(context: context),
            toastType: ToastType.error,
          );
        }
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ImmichToast.show(
          context: context,
          msg: 'cannot_merge_people'.t(context: context),
          toastType: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isMerging = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final people = ref.watch(driftGetAllPeopleProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('merge_people'.t(context: context)),
        actions: [
          if (_selectedPersonIds.isNotEmpty)
            TextButton(
              onPressed: _isMerging ? null : _mergePeople,
              child: _isMerging
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'merge'.t(context: context),
                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                    ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchField(
              onTapOutside: (_) {},
              onChanged: (value) => setState(() => _search = value),
              filled: true,
              hintText: 'search_people'.t(context: context),
            ),
          ),
          if (_selectedPersonIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                '${_selectedPersonIds.length} / 5',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Expanded(
            child: people.when(
              data: (peopleList) {
                final filteredPeople = _search != null && _search!.isNotEmpty
                    ? peopleList.where((p) => p.name.toLowerCase().contains(_search!.toLowerCase())).toList()
                    : peopleList;

                final selectablePeople = filteredPeople.where((p) => p.id != widget.personId).toList();

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.85,
                  ),
                  padding: const EdgeInsets.all(16),
                  itemCount: selectablePeople.length,
                  itemBuilder: (context, index) {
                    final person = selectablePeople[index];
                    final isSelected = _selectedPersonIds.contains(person.id);

                    return GestureDetector(
                      onTap: () => _toggleSelection(person.id),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Material(
                                shape: CircleBorder(
                                  side: BorderSide(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey.withValues(alpha: 0.3),
                                    width: isSelected ? 3 : 1,
                                  ),
                                ),
                                elevation: isSelected ? 4 : 2,
                                child: CircleAvatar(
                                  maxRadius: 48,
                                  backgroundImage: RemoteImageProvider(url: getFaceThumbnailUrl(person.id)),
                                ),
                              ),
                              if (isSelected)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check, color: Colors.white, size: 16),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            person.name.isNotEmpty ? person.name : 'add_a_name'.t(context: context),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isSelected ? Theme.of(context).colorScheme.primary : null,
                              fontWeight: isSelected ? FontWeight.w600 : null,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              error: (error, stack) => const Text("error"),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }
}
