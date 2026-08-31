import 'package:flutter/material.dart';

import '../data/community_sets_repository.dart';
import '../data/community_tags.dart';
import '../models/dominion_card.dart';
import '../models/saved_set.dart';

Future<bool> showPublishSetDialog(
  BuildContext context, {
  required SavedSet savedSet,
  required List<DominionCard> allCards,
}) async {
  final descriptionController = TextEditingController();
  final selectedTags = <String>{};

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      var isPublishing = false;

      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> publish() async {
            if (isPublishing) return;

            setState(() {
              isPublishing = true;
            });

            try {
              await CommunitySetsRepository().publishSet(
                savedSet,
                allCards,
                description: descriptionController.text.trim().isEmpty
                    ? null
                    : descriptionController.text.trim(),
                tags: selectedTags.toList(),
              );

              if (!dialogContext.mounted) return;

              Navigator.pop(dialogContext, true);
            } catch (error) {
              if (!dialogContext.mounted) return;

              setState(() {
                isPublishing = false;
              });

              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(
                  content: Text(
                    'Could not publish set: $error',
                  ),
                ),
              );
            }
          }

          return AlertDialog(
            title: Text(
              'Publish "${savedSet.name}"',
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Optional',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Tags',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${selectedTags.length} / 5 selected',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final tag in communityTags)
                          FilterChip(
                            label: Text(tag),
                            selected: selectedTags.contains(tag),
                            onSelected: isPublishing
                                ? null
                                : (selected) {
                                    setState(() {
                                      if (selected) {
                                        if (selectedTags.length < 5) {
                                          selectedTags.add(tag);
                                        }
                                      } else {
                                        selectedTags.remove(tag);
                                      }
                                    });
                                  },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isPublishing
                    ? null
                    : () {
                        Navigator.pop(dialogContext, false);
                      },
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: isPublishing ? null : publish,
                icon: isPublishing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.public),
                label: Text(
                  isPublishing ? 'Publishing...' : 'Publish',
                ),
              ),
            ],
          );
        },
      );
    },
  );

  descriptionController.dispose();

  return result ?? false;
}