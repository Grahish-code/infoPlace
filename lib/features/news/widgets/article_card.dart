import 'package:flutter/material.dart';
import '../models/articles_model.dart';
import '../screens/article_webview_screen.dart'; // Make sure this import is correct

class ArticleCard extends StatelessWidget {
  final Article article;
  const ArticleCard({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: article.urlToImage.isNotEmpty
            ? Image.network(article.urlToImage, width: 80, fit: BoxFit.cover)
            : null,
        title: Text(article.title),
        subtitle: Text(article.description, maxLines: 2, overflow: TextOverflow.ellipsis),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ArticleWebViewScreen(article: article),
            ),
          );
        },
      ),
    );
  }
}
