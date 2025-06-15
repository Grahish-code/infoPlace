import 'package:flutter/material.dart';
import '../models/articles_model.dart';

class OfflineReaderScreen extends StatelessWidget {
  final Article article;

  const OfflineReaderScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(article.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(article.title,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(article.description),
              const SizedBox(height: 16),
              if (article.content != null)
                Text(article.content!)
              else
                const Text(
                    "No offline content available for this article."),
            ],
          ),
        ),
      ),
    );
  }
}
