import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/dominion_card.dart';

class CardRepository {
  static const List<String> _cardFiles = [
    'adventures.json',
    'alchemy.json',
    'allies.json',
    'base.json',
    'cornucopia_guilds.json',
    'dark_ages.json',
    'empires.json',
    'hinterlands.json',
    'intrigue.json',
    'menagerie.json',
    'nocturne.json',
    'plunder.json',
    'prosperity.json',
    'renaissance.json',
    'rising_sun.json',
    'seaside.json',
  ];

  Future<List<DominionCard>> loadAllCards() async {
    final List<DominionCard> allCards = [];

    for (final fileName in _cardFiles) {
      final cards = await loadCards(fileName);
      allCards.addAll(cards);
    }

    return allCards;
  }

  Future<List<DominionCard>> loadCards(String fileName) async {
    final jsonString = await rootBundle.loadString(
      'assets/cards/$fileName',
    );

    final List<dynamic> jsonCards = jsonDecode(jsonString);

    return jsonCards
        .map(
          (json) => DominionCard.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  List<DominionCard> getCardsByExpansion(
    List<DominionCard> cards,
    String expansion,
  ) {
    return cards
        .where((card) => card.set == expansion)
        .toList();
  }

  List<DominionCard> getKingdomCards(
    List<DominionCard> cards,
  ) {
    return cards
        .where((card) => card.purpose == 'Kingdom Pile')
        .toList();
  }

  List<DominionCard> generateKingdom(
    List<DominionCard> cards,
  ) {
    final kingdomCards = getKingdomCards(cards);

    kingdomCards.shuffle();

    return kingdomCards.take(10).toList();
  }
}