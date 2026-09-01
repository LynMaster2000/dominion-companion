import 'package:flutter/material.dart';

import '../models/community_filter.dart';

class CommunityFilterDialog extends StatefulWidget {
  final CommunityFilter filter;
  final List<String> availableExpansions;
  final List<String> availableTags;

  const CommunityFilterDialog({
    super.key,
    required this.filter,
    required this.availableExpansions,
    required this.availableTags,
  });

  @override
  State<CommunityFilterDialog> createState() =>
      _CommunityFilterDialogState();
}

class _CommunityFilterDialogState
    extends State<CommunityFilterDialog> {
  late CommunitySort _sort;
  late Set<String> _selectedExpansions;
  late Set<String> _selectedTags;

  @override
  void initState() {
    super.initState();

    _sort = widget.filter.sort;
    _selectedExpansions =
        Set<String>.from(widget.filter.expansions);
    _selectedTags =
        Set<String>.from(widget.filter.tags);
  }

  Future<void> _chooseExpansions() async {
    final tempSelected =
        Set<String>.from(_selectedExpansions);

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select expansions'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final expansion
                        in widget.availableExpansions)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(expansion),
                        value:
                            tempSelected.contains(expansion),
                        onChanged: (selected) {
                          setDialogState(() {
                            if (selected == true) {
                              tempSelected.add(expansion);
                            } else {
                              tempSelected.remove(expansion);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      <String>{},
                    );
                  },
                  child: const Text('Clear'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      tempSelected,
                    );
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    setState(() {
      _selectedExpansions = result;
    });
  }

  Future<void> _chooseTags() async {
    final tempSelected =
        Set<String>.from(_selectedTags);

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select tags'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final tag in widget.availableTags)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(tag),
                        value: tempSelected.contains(tag),
                        onChanged: (selected) {
                          setDialogState(() {
                            if (selected == true) {
                              tempSelected.add(tag);
                            } else {
                              tempSelected.remove(tag);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      <String>{},
                    );
                  },
                  child: const Text('Clear'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      tempSelected,
                    );
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    setState(() {
      _selectedTags = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter & Sort'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 8),

            DropdownButtonFormField<CommunitySort>(
              initialValue: _sort,
              decoration: const InputDecoration(
                labelText: 'Sort by',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: CommunitySort.newest,
                  child: Text('Newest'),
                ),
                DropdownMenuItem(
                  value: CommunitySort.oldest,
                  child: Text('Oldest'),
                ),
                DropdownMenuItem(
                  value: CommunitySort.highestRated,
                  child: Text('Highest rated'),
                ),
                DropdownMenuItem(
                  value: CommunitySort.mostRated,
                  child: Text('Most rated'),
                ),
                DropdownMenuItem(
                  value: CommunitySort.alphabetical,
                  child: Text('A–Z'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _sort = value;
                });
              },
            ),
            const SizedBox(height: 16),

            Text(
              'Expansions',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 16),

            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: _chooseExpansions,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Expansions',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                child: Text(
                  _selectedExpansions.isEmpty
                      ? 'Any expansion'
                      : _selectedExpansions.join(', '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            const SizedBox(height: 16),

            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: _chooseTags,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                child: Text(
                  _selectedTags.isEmpty
                      ? 'Any tag'
                      : _selectedTags.join(', '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _sort = CommunitySort.newest;
              _selectedExpansions.clear();
              _selectedTags.clear();
            });
          },
          child: const Text('Reset'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(
              context,
              widget.filter.copyWith(
                sort: _sort,
                expansions: Set<String>.from(
                  _selectedExpansions,
                ),
                tags: Set<String>.from(
                  _selectedTags,
                ),
              ),
            );
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}