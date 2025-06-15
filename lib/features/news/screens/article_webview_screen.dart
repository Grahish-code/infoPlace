import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';
import '../models/articles_model.dart';
import '../providers/news_provider.dart';

class ArticleWebViewScreen extends StatefulWidget {
  final Article article;

  const ArticleWebViewScreen({super.key, required this.article});

  @override
  State<ArticleWebViewScreen> createState() => _ArticleWebViewScreenState();
}

class _ArticleWebViewScreenState extends State<ArticleWebViewScreen>
    with TickerProviderStateMixin {
  String? articleContent;
  bool isLoading = true;
  String? errorMessage;
  bool isBookmarked = false;
  bool isDarkMode = true;
  double fontSize = 16.0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _checkBookmarkStatus();
    _loadArticleContent();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _checkBookmarkStatus() async {
    final provider = Provider.of<NewsProvider>(context, listen: false);
    setState(() {
      isBookmarked = provider.isBookmarked(widget.article);
    });
  }

  String _cleanArticleText(String rawText) {
    // Enhanced content filtering
    String cleaned = rawText
    // Remove multiple whitespaces and line breaks
        .replaceAll(RegExp(r'\s{3,}'), '\n\n')
        .replaceAll(RegExp(r'[\r\n]{3,}'), '\n\n')
    // Remove special characters but keep punctuation
        .replaceAll(RegExp(r'[^\x00-\x7F\u00C0-\u017F\u0100-\u024F]+'), '')
    // Remove common junk patterns
        .replaceAll(RegExp(r'(Advertisement|ADVERTISEMENT|Subscribe|SUBSCRIBE).*'), '')
        .replaceAll(RegExp(r'(Click here|Read more|Share this|Follow us).*'), '')
        .replaceAll(RegExp(r'(Cookie|COOKIE).*policy.*', caseSensitive: false), '')
        .replaceAll(RegExp(r'(Terms|TERMS).*conditions.*', caseSensitive: false), '')
        .replaceAll(RegExp(r'Loading\.\.\.|Please wait\.\.\.|Error \d+'), '')
        .replaceAll(RegExp(r'^\d+\s*$', multiLine: true), '') // Remove standalone numbers
        .replaceAll(RegExp(r'^[^\w\s]{3,}$', multiLine: true), '') // Remove symbol-only lines
        .replaceAll(RegExp(r'(JavaScript|Javascript|js).*disabled.*', caseSensitive: false), '')
        .trim();

    // Split into sentences and filter out junk sentences
    List<String> sentences = cleaned.split(RegExp(r'[.!?]+\s+'));
    sentences = sentences.where((sentence) {
      sentence = sentence.trim();

      // Filter out sentences that are likely junk
      if (sentence.length < 10) return false; // Too short
      if (sentence.length > 500) return false; // Too long (likely junk)
      if (RegExp(r'^[^a-zA-Z]*$').hasMatch(sentence)) return false; // No letters
      if (sentence.split(' ').length < 3) return false; // Too few words
      if (RegExp(r'^\d+$').hasMatch(sentence)) return false; // Only numbers
      if (sentence.toLowerCase().contains(RegExp(r'(advertisement|subscribe|cookie|terms|javascript|loading)'))) return false;

      // Check for reasonable word-to-punctuation ratio
      int wordCount = sentence.split(RegExp(r'\s+')).length;
      int punctCount = sentence.replaceAll(RegExp(r'[a-zA-Z0-9\s]'), '').length;
      if (punctCount > wordCount) return false; // Too much punctuation

      return true;
    }).toList();

    // Rejoin sentences and format paragraphs
    cleaned = sentences.join('. ').trim();

    if (cleaned.isNotEmpty && !cleaned.endsWith('.')) {
      cleaned += '.';
    }

    // Create proper paragraphs
    final lines = cleaned.split('\n');
    final formatted = lines.map((line) {
      line = line.trim();
      if (line.length > 400) {
        // Break long lines into smaller chunks at sentence boundaries
        return line.replaceAllMapped(
          RegExp(r'(.{1,200}[.!?])\s+'),
              (match) => '${match.group(1)}\n\n',
        );
      }
      return line;
    }).where((line) => line.isNotEmpty).join('\n\n');

    return formatted;
  }

  Future<void> _loadArticleContent() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    if (widget.article.htmlData != null && widget.article.htmlData!.isNotEmpty) {
      setState(() {
        articleContent = widget.article.htmlData;
        isLoading = false;
      });
      _fadeController.forward();
      return;
    }

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        errorMessage = 'No internet connection. Please try again later.';
        isLoading = false;
      });
      return;
    }

    try {
      final url = Uri.parse(widget.article.url);
      if (!url.hasScheme) {
        throw Exception('Invalid URL: ${widget.article.url}');
      }

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);

        // Enhanced content extraction
        final contentSelectors = [
          'article',
          '.post-content',
          '.entry-content',
          '.article-content',
          '.story-body',
          '.content',
          'main p',
          '.post-body p',
          '[class*="content"] p',
        ];

        String extractedContent = '';
        for (String selector in contentSelectors) {
          final elements = document.querySelectorAll(selector);
          if (elements.isNotEmpty) {
            extractedContent = elements.map((e) => e.text).join('\n\n').trim();
            if (extractedContent.length > 200) break; // Found substantial content
          }
        }

        if (extractedContent.isEmpty) {
          // Fallback to all paragraphs
          final paragraphs = document.querySelectorAll('p');
          extractedContent = paragraphs.map((e) => e.text).join('\n\n').trim();
        }

        final cleanedContent = _cleanArticleText(extractedContent);

        setState(() {
          articleContent = cleanedContent.isNotEmpty && cleanedContent.length > 100
              ? cleanedContent
              : 'Sorry, the full article content could not be extracted. Please visit the original source to read the complete article.';
          isLoading = false;
        });

        _fadeController.forward();

        if (cleanedContent.isNotEmpty && cleanedContent.length > 100 && isBookmarked) {
          final updatedArticle = Article(
            title: widget.article.title,
            description: widget.article.description,
            url: widget.article.url,
            urlToImage: widget.article.urlToImage,
            publishedAt: widget.article.publishedAt,
            content: widget.article.content,
            source: widget.article.source,
            htmlData: cleanedContent,
          );
          final provider = Provider.of<NewsProvider>(context, listen: false);
          await provider.toggleBookmark(widget.article);
          await provider.toggleBookmark(updatedArticle);
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to load article');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Unable to extract article content from this source.';
        isLoading = false;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    HapticFeedback.lightImpact();
    final provider = Provider.of<NewsProvider>(context, listen: false);
    final updatedArticle = articleContent != null && articleContent!.isNotEmpty
        ? Article(
      title: widget.article.title,
      description: widget.article.description,
      url: widget.article.url,
      urlToImage: widget.article.urlToImage,
      publishedAt: widget.article.publishedAt,
      content: widget.article.content,
      source: widget.article.source,
      htmlData: articleContent,
    )
        : widget.article;

    await provider.toggleBookmark(updatedArticle);
    setState(() {
      isBookmarked = provider.isBookmarked(updatedArticle);
    });
  }

  void _toggleTheme() {
    HapticFeedback.mediumImpact();
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  void _adjustFontSize(bool increase) {
    HapticFeedback.selectionClick();
    setState(() {
      if (increase && fontSize < 24) {
        fontSize += 2;
      } else if (!increase && fontSize > 12) {
        fontSize -= 2;
      }
    });
  }

  ThemeData get currentTheme => isDarkMode
      ? ThemeData.dark().copyWith(
    scaffoldBackgroundColor: const Color(0xFF1A1A1A),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2D2D2D),
      elevation: 0,
    ),
    cardColor: const Color(0xFF2D2D2D),
  )
      : ThemeData.light().copyWith(
    scaffoldBackgroundColor: const Color(0xFFFAFAFA),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      foregroundColor: Colors.black87,
    ),
    cardColor: Colors.white,
  );

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: currentTheme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.article.source.name ?? "News",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          actions: [
            // Font size controls
            IconButton(
              icon: const Icon(Icons.text_decrease),
              onPressed: () => _adjustFontSize(false),
              tooltip: 'Decrease font size',
            ),
            IconButton(
              icon: const Icon(Icons.text_increase),
              onPressed: () => _adjustFontSize(true),
              tooltip: 'Increase font size',
            ),
            // Theme toggle
            IconButton(
              icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: _toggleTheme,
              tooltip: isDarkMode ? 'Light mode' : 'Dark mode',
            ),
            // Bookmark
            IconButton(
              icon: Icon(
                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: isBookmarked ? Colors.amber : null,
              ),
              onPressed: _toggleBookmark,
              tooltip: isBookmarked ? 'Remove bookmark' : 'Add bookmark',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadArticleContent,
          color: isDarkMode ? Colors.white : Colors.blue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: isLoading
                ? _buildLoadingWidget()
                : errorMessage != null
                ? _buildErrorWidget()
                : _buildArticleContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: isDarkMode ? Colors.white70 : Colors.blue,
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          Text(
            "Loading article...",
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white70 : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Please wait while we fetch the content",
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white54 : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 80,
            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            "Sorry! 😔",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "We couldn't extract the full article content from this source.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white70 : Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "But don't worry! You can read the original article using the link below.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white60 : Colors.grey[500],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),

          // Original Article Link Card
          Card(
            elevation: isDarkMode ? 8 : 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.link,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Original Article",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.grey[800]?.withOpacity(0.5)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.article.url,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.white : Colors.grey[700],
                              fontFamily: 'monospace',
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: widget.article.url));
                            HapticFeedback.mediumImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                                    const SizedBox(width: 8),
                                    Text('Link copied to clipboard!'),
                                  ],
                                ),
                                backgroundColor: isDarkMode ? Colors.grey[800] : Colors.black87,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.copy,
                            color: Colors.blue,
                            size: 18,
                          ),
                          tooltip: 'Copy link',
                          padding: EdgeInsets.all(8),
                          constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: widget.article.url));
                            HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                                    const SizedBox(width: 8),
                                    Text('Link copied!'),
                                  ],
                                ),
                                backgroundColor: isDarkMode ? Colors.grey[800] : Colors.black87,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: Icon(Icons.copy, size: 18),
                          label: Text("Copy Link"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _loadArticleContent,
                          icon: Icon(Icons.refresh, size: 18),
                          label: Text("Try Again"),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            side: BorderSide(
                              color: isDarkMode ? Colors.white60 : Colors.grey[400]!,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Helpful tip
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Tip: Copy the link and open it in your browser to read the full article",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Article Header Card
            Card(
              elevation: isDarkMode ? 8 : 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      widget.article.title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Source and Date
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.article.source.name ?? "Unknown",
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (widget.article.publishedAt.isNotEmpty)
                          Text(
                            widget.article.publishedAt,
                            style: TextStyle(
                              color: isDarkMode ? Colors.white60 : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),

                    // Description
                    if (widget.article.description.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.grey[800]?.withOpacity(0.5)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.article.description,
                          style: TextStyle(
                            fontSize: fontSize,
                            height: 1.6,
                            color: isDarkMode ? Colors.white : Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Article Image
            if (widget.article.urlToImage.isNotEmpty)
              Card(
                elevation: isDarkMode ? 8 : 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  height: 220,
                  width: double.infinity,
                  child: Image.network(
                    widget.article.urlToImage,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 220,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 220,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Article Content
            Card(
              elevation: isDarkMode ? 8 : 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Content Header
                    Row(
                      children: [
                        Icon(
                          Icons.article_outlined,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Article Content",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Article paragraphs
                    ...articleContent!.split('\n\n').map((para) {
                      if (para.trim().isEmpty) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          para.trim(),
                          style: TextStyle(
                            fontSize: fontSize,
                            height: 1.8,
                            color: isDarkMode ? Colors.white : Colors.black87,
                            fontFamily: 'Georgia', // Better reading font
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Read more button
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // You can add functionality to open original URL here
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Original URL: ${widget.article.url}'),
                      backgroundColor: isDarkMode ? Colors.grey[800] : Colors.black87,
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text("Read Original Article"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}