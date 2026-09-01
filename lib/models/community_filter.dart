enum CommunitySort {
  newest,
  oldest,
  highestRated,
  mostRated,
  alphabetical,
}

class CommunityFilter {
  final CommunitySort sort;
  final Set<String> expansions;
  final Set<String> tags;

  const CommunityFilter({
    this.sort = CommunitySort.newest,
    this.expansions = const {},
    this.tags = const {},
  });

  CommunityFilter copyWith({
    CommunitySort? sort,
    Set<String>? expansions,
    Set<String>? tags,
  }) {
    return CommunityFilter(
      sort: sort ?? this.sort,
      expansions: expansions ?? this.expansions,
      tags: tags ?? this.tags,
    );
  }

  bool get hasActiveFilters =>
      expansions.isNotEmpty || tags.isNotEmpty;
}