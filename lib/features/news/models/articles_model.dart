import 'package:hive/hive.dart';

part 'articles_model.g.dart';

@HiveType(typeId: 1)
class Source {
  @HiveField(0)
  final String name;

  Source({required this.name});

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      name: json['name'] ?? 'Unknown Source',
    );
  }
}

@HiveType(typeId: 0)
class Article {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final String description;

  @HiveField(2)
  final String url;

  @HiveField(3)
  final String urlToImage;

  @HiveField(4)
  final String publishedAt;

  @HiveField(5)
  final String content;

  @HiveField(6)
  final Source source;

  // Stores plain text content extracted from the article for offline display
  @HiveField(7)
  final String? htmlData;

  Article({
    required this.title,
    required this.description,
    required this.url,
    required this.urlToImage,
    required this.publishedAt,
    required this.content,
    required this.source,
    this.htmlData,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      urlToImage: json['urlToImage'] ?? '',
      publishedAt: json['publishedAt'] ?? '',
      content: json['content'] ?? '',
      source: Source.fromJson(json['source'] ?? {}),
      htmlData: null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'url': url,
      'urlToImage': urlToImage,
      'publishedAt': publishedAt,
      'content': content,
      'source': {'name': source.name},
      'htmlData': htmlData,
    };
  }
}