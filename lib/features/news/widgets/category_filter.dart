import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';

class CategoryFilter extends StatelessWidget {
  final List<String> categories = ["business", "technology", "sports"];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NewsProvider>(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: categories.map((category) {
        final isSelected = provider.selectedCategory == category;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: ChoiceChip(
            label: Text(category.toUpperCase()),
            selected: isSelected,
            onSelected: (_) => provider.changeCategory(category),
          ),
        );
      }).toList(),
    );
  }
}
