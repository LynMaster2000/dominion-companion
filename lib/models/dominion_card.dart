class DominionCard {
  final String name;
  final List<String> types;
  final String purpose;
  final CardCost cost;
  final String set;
  final List<int> editions;
  final int quantity;
  final String image;
  final String instructions;

  const DominionCard({
    required this.name,
    required this.types,
    required this.purpose,
    required this.cost,
    required this.set,
    required this.editions,
    required this.quantity,
    required this.image,
    required this.instructions,
  });

  String get id => '$set::$name';

  factory DominionCard.fromJson(Map<String, dynamic> json) {
    return DominionCard(
      name: json['name'] as String,
      types: List<String>.from(json['types']),
      purpose: json['purpose'] as String,
      cost: CardCost.fromJson(
        json['cost'] as Map<String, dynamic>,
      ),
      set: json['set'] as String,
      editions: List<int>.from(json['editions']),
      quantity: json['quantity'] as int,
      image: json['image'] as String,
      instructions: json['instructions'] as String,
    );
  }
}

class CardCost {
  final int coins;
  final int debt;
  final bool potion;

  const CardCost({
    this.coins = 0,
    this.debt = 0,
    this.potion = false,
  });

  factory CardCost.fromJson(Map<String, dynamic> json) {
    return CardCost(
      coins: json['coins'] as int? ?? 0,
      debt: json['debt'] as int? ?? 0,
      potion: json['potion'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    final parts = <String>[];

    if (coins > 0) {
      parts.add('\$$coins');
    }

    if (debt > 0) {
      parts.add('$debt Debt');
    }

    if (potion) {
      parts.add('Potion');
    }

    if (parts.isEmpty) {
      return '\$0';
    }

    return parts.join(' + ');
  }
}

