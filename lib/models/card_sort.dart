import 'dominion_card.dart';

enum CardSort {
  alphabetical,
  alphabeticalReverse,
  costLowHigh,
  costHighLow,
  expansion,
  type,
}

void sortCards(
  List<DominionCard> cards,
  CardSort sort,
) {
  switch (sort) {
    case CardSort.alphabetical:
      cards.sort(
        (a, b) => a.name.compareTo(b.name),
      );
      break;

    case CardSort.alphabeticalReverse:
      cards.sort(
        (a, b) => b.name.compareTo(a.name),
      );
      break;

    case CardSort.costLowHigh:
      cards.sort(compareCost);
      break;

    case CardSort.costHighLow:
      cards.sort(
        (a, b) => compareCost(b, a),
      );
      break;

    case CardSort.expansion:
      cards.sort((a, b) {
        final setCompare = a.set.compareTo(b.set);

        if (setCompare != 0) {
          return setCompare;
        }

        return a.name.compareTo(b.name);
      });
      break;

    case CardSort.type:
      cards.sort((a, b) {
        final aType = a.types.isEmpty ? '' : a.types.first;
        final bType = b.types.isEmpty ? '' : b.types.first;

        final typeCompare = aType.compareTo(bType);

        if (typeCompare != 0) {
          return typeCompare;
        }

        return a.name.compareTo(b.name);
      });
      break;
  }
}

int compareCost(
  DominionCard a,
  DominionCard b,
) {
  final coinCompare = a.cost.coins.compareTo(
    b.cost.coins,
  );

  if (coinCompare != 0) {
    return coinCompare;
  }

  final debtCompare = a.cost.debt.compareTo(
    b.cost.debt,
  );

  if (debtCompare != 0) {
    return debtCompare;
  }

  if (a.cost.potion != b.cost.potion) {
    return a.cost.potion ? 1 : -1;
  }

  return a.name.compareTo(b.name);
}