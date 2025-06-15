
import '../../../../core/services/news_service.dart';
import '../../models/articles_model.dart';


class NewsRepository {
  final NewsService service;

  NewsRepository(this.service);

  Future<List<Article>> getTopHeadlines(String category) {
    return service.fetchTopHeadlines(category);
  }

  Future<List<Article>> searchArticles(String query) {
    return service.searchArticles(query);
  }

}
