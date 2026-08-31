import 'package:flutter/material.dart';

import '../data/community_sets_repository.dart';
import '../models/community_set.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({
    super.key,
  });

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final CommunitySetsRepository _repository =
      CommunitySetsRepository();

  late Future<List<CommunitySet>> _setsFuture;

  @override
  void initState() {
    super.initState();
    _setsFuture = _repository.getCommunitySets();
  }

  Future<void> refresh() async {
    setState(() {
      _setsFuture = _repository.getCommunitySets();
    });

    await _setsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
      ),
      body: FutureBuilder<List<CommunitySet>>(
        future: _setsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load community sets.\n\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final sets = snapshot.data ?? [];

          if (sets.isEmpty) {
            return const Center(
              child: Text(
                'No community sets yet.',
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sets.length,
              itemBuilder: (context, index) {
                final set = sets[index];

                return Card(
                  child: ListTile(
                    title: Text(set.name),
                    subtitle: Text(
                      '${set.kingdomCardIds.length} Kingdom cards',
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}