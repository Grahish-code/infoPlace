import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/bookmark_services.dart';
import '../data/repositories/news_repository.dart';
import '../models/articles_model.dart';


class NewsProvider with ChangeNotifier {
  final NewsRepository repository;

  List<Article> _articles = [];
  List<Article> _searchResults = [];
  final List<Article> _bookmarkedArticles = [];
  List<Article> get bookmarkedArticles => _bookmarkedArticles;

  String _selectedCategory = "business";
  bool _isLoading = false;
  bool _isSearching = false;

  Timer? _debounce;

  NewsProvider(this.repository) {
    fetchArticles();
    _loadBookmarks();
  }

  // 🔍 Getters
  List<Article> get articles => _articles;
  List<Article> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;
  bool get isSearching => _isSearching;

  // 🔁 Category switching
  void changeCategory(String category) {
    _selectedCategory = category.toLowerCase();
    fetchArticles();
  }

  // 📥 Fetch top headlines
  Future<void> fetchArticles() async {
    _isLoading = true;
    _isSearching = false;
    notifyListeners();

    _articles = await repository.getTopHeadlines(_selectedCategory);
    _searchResults = [];
    _isLoading = false;
    notifyListeners();
  }

  // 📤 Load bookmarks from BookmarkService
  Future<void> _loadBookmarks() async {
    _bookmarkedArticles.clear();
    _bookmarkedArticles.addAll(await BookmarkService.getBookmarks());
    notifyListeners();
  }

  // ✅ Toggle bookmark using BookmarkService
  Future<void> toggleBookmark(Article article) async {
    final isBookmarked = await BookmarkService.isBookmarked(article.url);
    if (isBookmarked) {
      await BookmarkService.removeBookmark(article.url);
      _bookmarkedArticles.removeWhere((a) => a.url == article.url);
    } else {
      await BookmarkService.saveBookmark(article);
      _bookmarkedArticles.add(article);
    }
    notifyListeners();
  }

  bool isBookmarked(Article article) {
    return _bookmarkedArticles.any((a) => a.url == article.url);
  }

  // 🔎 Search with debounce + top headline match + everything API
  void onQueryChanged(String query) {
    _debounce?.cancel();

    if (query.isEmpty) {
      _isSearching = false;
      _searchResults = [];
      notifyListeners();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      _isLoading = true;
      _isSearching = true;
      notifyListeners();

      List<Article> localMatches = _articles.where((article) {
        final lowerQuery = query.toLowerCase();
        return article.title.toLowerCase().contains(lowerQuery) ||
            article.description.toLowerCase().contains(lowerQuery);
      }).toList();

      List<Article> remoteMatches = await repository.searchArticles(query);

      final merged = [
        ...localMatches,
        ...remoteMatches.where((remote) => !localMatches.any((local) => local.title == remote.title)),
      ];

      _searchResults = merged;
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}