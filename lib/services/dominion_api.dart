import 'dart:convert';
import 'package:http/http.dart' as http;

class DominionApi {
  static const String baseUrl =
      'https://wiki.dominionstrategy.com/index.php';

  Future<void> testExpansions() async {
    final uri = Uri.parse(baseUrl).replace(
      queryParameters: {
        'title': 'Special:CargoExport',
        'tables': 'Expansions',
        'fields': 'Name,Ordering,Latest',
        'limit': '20',
        'format': 'json',
      },
    );

    print('Requesting: $uri');

    final response = await http.get(uri);

    print('Status: ${response.statusCode}');
    print(response.body);
  }
}