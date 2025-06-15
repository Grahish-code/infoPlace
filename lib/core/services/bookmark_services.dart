import 'package:hive/hive.dart';
import '../../features/news/models/articles_model.dart';


class BookmarkService {
  static const String _bookmarkBox = 'bookmarks';

  // Initialize Hive box for bookmarks
  static Future<void> init() async {
    if (!Hive.isBoxOpen(_bookmarkBox)) {
      await Hive.openBox<Article>(_bookmarkBox);
    }
  }

  // Save an article to bookmarks
  static Future<void> saveBookmark(Article article) async {
    final box = Hive.box<Article>(_bookmarkBox);
    await box.put(article.url, article);
  }

  // Remove an article from bookmarks
  static Future<void> removeBookmark(String url) async {
    final box = Hive.box<Article>(_bookmarkBox);
    await box.delete(url);
  }

  // Check if an article is bookmarked
  static Future<bool> isBookmarked(String url) async {
    final box = Hive.box<Article>(_bookmarkBox);
    return box.containsKey(url);
  }

  // Get all bookmarked articles
  static Future<List<Article>> getBookmarks() async {
    final box = Hive.box<Article>(_bookmarkBox);
    return box.values.toList();
  }
}