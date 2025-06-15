import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/news/models/articles_model.dart';
import '../constants/api_constants.dart';

class NewsService {
  Future<List<Article>> fetchTopHeadlines(String category) async {
    print("Fetching news for category: $category");

    final response = await http.get(Uri.parse(ApiConstants.topHeadlines(category)));
    print("Response status: ${response.statusCode}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final articles = (data['articles'] as List)
          .where((json) =>
      json['content'] != null &&
          json['content'].toString().trim().isNotEmpty)
          .map((json) => Article.fromJson(json))
          .toList();

      print("Filtered articles received: ${articles.length}");
      return articles;
    } else {
      throw Exception("Failed to fetch news");
    }
  }

  Future<List<Article>> searchArticles(String query) async {
    final response = await http.get(Uri.parse(
      '${ApiConstants.baseUrl2}/everything?q=$query&apiKey=${ApiConstants.apiKey2}',
    ));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final articles = (data['articles'] as List)
          .where((json) =>
      json['content'] != null &&
          json['content'].toString().trim().isNotEmpty)
          .map((json) => Article.fromJson(json))
          .toList();

      print("Filtered search articles received: ${articles.length}");
      return articles;
    } else {
      throw Exception("Failed to search articles");
    }
  }
}
