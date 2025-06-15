import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math' as math;
import 'dart:ui';

import '../models/articles_model.dart';
import '../providers/news_provider.dart';
import 'article_webview_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late AnimationController _headerController;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NewsProvider>(context);
    final bookmarks = provider.bookmarkedArticles;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                      const Color(0xFF0F0F23),
                      const Color(0xFF1A1A2E),
                      const Color(0xFF16213E),
                    ]
                        : [
                      const Color(0xFFF8FAFF),
                      const Color(0xFFE8F4FD),
                      const Color(0xFFF0F8FF),
                    ],
                    stops: [
                      0.0,
                      0.5 + 0.3 * math.sin(_backgroundController.value * 2 * math.pi),
                      1.0,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    ...List.generate(8, (index) {
                      return Positioned(
                        left: (index * 80.0) % MediaQuery.of(context).size.width,
                        top: 100 + (index * 90.0) % MediaQuery.of(context).size.height,
                        child: Transform.rotate(
                          angle: _backgroundController.value * 2 * math.pi + index,
                          child: Container(
                            width: 15 + (index * 8).toDouble(),
                            height: 15 + (index * 8).toDouble(),
                            decoration: BoxDecoration(
                              shape: index % 3 == 0 ? BoxShape.circle : BoxShape.rectangle,
                              color: (isDark ? Colors.white : Colors.blue).withOpacity(0.08),
                              borderRadius: index % 3 != 0 ? BorderRadius.circular(6) : null,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(isDark ? 0.05 : 0.7),
                  Colors.transparent,
                  Colors.white.withOpacity(isDark ? 0.02 : 0.3),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      _buildGlassButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => Navigator.pop(context),
                      ).animate().scale(delay: 200.ms),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: 1.0 + 0.05 * math.sin(_pulseController.value * math.pi),
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              const Color(0xFF667EEA),
                                              const Color(0xFF764BA2),
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF667EEA).withOpacity(0.4),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.bookmark_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'My Bookmarks',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                                  ),
                                ).animate().fadeIn(duration: 600.ms).slideX(),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${bookmarks.length} saved articles',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: (isDark ? Colors.white : const Color(0xFF1A1A2E)).withOpacity(0.7),
                              ),
                            ).animate(delay: 200.ms).fadeIn(duration: 600.ms),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: bookmarks.isEmpty
                      ? _buildEmptyState(isDark)
                      : _buildBookmarksList(bookmarks, provider, isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({required IconData icon, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(isDark ? 0.15 : 0.2),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Icon(
              icon,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 10 * math.sin(_floatController.value * math.pi)),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF667EEA).withOpacity(0.3),
                        const Color(0xFF764BA2).withOpacity(0.3),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667EEA).withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.bookmark_outline_rounded,
                    size: 60,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            "No bookmarks yet",
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Start saving articles you love\nto read them later",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: (isDark ? Colors.white : const Color(0xFF1A1A2E)).withOpacity(0.6),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF667EEA),
                    const Color(0xFF764BA2),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Text(
                "Explore News",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildBookmarksList(List<Article> bookmarks, NewsProvider provider, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final article = bookmarks[index];
        return _buildBookmarkCard(article, provider, isDark, index);
      },
    );
  }

  Widget _buildBookmarkCard(Article article, NewsProvider provider, bool isDark, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArticleWebViewScreen(article: article),
          ),
        ),
        child: AnimatedBuilder(
          animation: _floatController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 3 * math.sin(_floatController.value * math.pi + index * 0.3)),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(isDark ? 0.1 : 0.9),
                      Colors.white.withOpacity(isDark ? 0.05 : 0.7),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(isDark ? 0.2 : 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF667EEA),
                                      const Color(0xFF764BA2),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF667EEA).withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.bookmark_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      article.title,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      article.description,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: (isDark ? Colors.white : const Color(0xFF1A1A2E)).withOpacity(0.7),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: const Color(0xFF667EEA).withOpacity(0.1),
                                ),
                                child: Text(
                                  'Read article',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF667EEA),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => Share.share('${article.title}\n\nRead more: ${article.url}'),
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.grey.withOpacity(0.1),
                                      ),
                                      child: Icon(
                                        Icons.share_rounded,
                                        size: 18,
                                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      provider.toggleBookmark(article);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text('Removed from bookmarks'),
                                          duration: const Duration(seconds: 2),
                                          backgroundColor: const Color(0xFF667EEA),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.red.withOpacity(0.1),
                                      ),
                                      child: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ).animate(delay: (index * 100).ms).fadeIn(duration: 600.ms).slideY(begin: 0.3),
    );
  }
}