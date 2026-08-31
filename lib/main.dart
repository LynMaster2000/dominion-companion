import 'package:flutter/material.dart';

import 'data/card_repository.dart';
import 'models/dominion_card.dart';
import 'screens/randomizer_page.dart';
import 'screens/main_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final repository = CardRepository();
  final cards = await repository.loadAllCards();

  await Supabase.initialize(
    url: 'https://fdhxbdmmmpchuwcuktgm.supabase.co',
    publishableKey: 'sb_publishable_gy7AXrSvVsMc6Whb9RWKPQ_3hcDfW4n',
  );

  final supabase = Supabase.instance.client;

  if (supabase.auth.currentSession == null) {
    await supabase.auth.signInAnonymously();
  }

  debugPrint(
    'Supabase user: ${supabase.auth.currentUser?.id}',
  );

  debugPrint(
    'Anonymous: ${supabase.auth.currentUser?.isAnonymous}',
  );

  runApp(
    DominionApp(
      repository: repository,
      cards: cards,
    ),
  );
}

class DominionApp extends StatelessWidget {
  final CardRepository repository;
  final List<DominionCard> cards;

  const DominionApp({
    super.key,
    required this.repository,
    required this.cards,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dominion Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5D4037),
          brightness: Brightness.light,
        ),

        scaffoldBackgroundColor: const Color(0xFFF4F0E6),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF3E2723),
          foregroundColor: Colors.white,
          centerTitle: false,
        ),

        cardTheme: CardThemeData(
          elevation: 2,
          margin: const EdgeInsets.symmetric(
            vertical: 5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: MainPage(
        repository: repository,
        cards: cards,
      ),
    );
  }
}

