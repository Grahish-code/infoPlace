import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:math' as math;
import 'dart:ui';

import '../models/articles_model.dart';
import '../providers/news_provider.dart';
import 'bookmark.dart';
import 'news_search_screen.dart';
import 'article_webview_screen.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> with TickerProviderStateMixin {
  final categories = ['Business', 'Technology', 'Sports'];
  late AnimationController _backgroundController;
  late AnimationController _pulseController;
  late AnimationController _floatController;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

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

    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Pull-to-refresh handler
  Future<void> _handleRefresh() async {
    final provider = Provider.of<NewsProvider>(context, listen: false);
    await provider.fetchArticles();

    // Show a brief success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('News refreshed successfully!'),
            ],
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NewsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Dynamic Gradient Background with Animated Shapes
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
                    // Floating geometric shapes
                    ...List.generate(6, (index) {
                      return Positioned(
                        left: (index * 100.0) % MediaQuery.of(context).size.width,
                        top: 50 + (index * 80.0) % MediaQuery.of(context).size.height,
                        child: Transform.rotate(
                          angle: _backgroundController.value * 2 * math.pi + index,
                          child: Container(
                            width: 20 + (index * 10).toDouble(),
                            height: 20 + (index * 10).toDouble(),
                            decoration: BoxDecoration(
                              shape: index % 2 == 0 ? BoxShape.circle : BoxShape.rectangle,
                              color: (isDark ? Colors.white : Colors.blue)
                                  .withOpacity(0.1),
                              borderRadius: index % 2 != 0
                                  ? BorderRadius.circular(8)
                                  : null,
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

          // Glassmorphism overlay
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

          // Main Content with RefreshIndicator
          RefreshIndicator(
            onRefresh: _handleRefresh,
            color: const Color(0xFF667EEA),
            backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            strokeWidth: 3,
            displacement: 60, // Position below the app bar
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(), // Ensures pull-to-refresh works even with few items
              slivers: [
                // Custom App Bar - Fixed overflow issue
                SliverAppBar(
                  expandedHeight: 130, // Increased height to prevent overflow
                  floating: true,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(isDark ? 0.1 : 0.8),
                            Colors.white.withOpacity(isDark ? 0.05 : 0.6),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: SafeArea( // Added SafeArea to handle status bar properly
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16), // Adjusted padding
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center, // Center align content
                                children: [
                                  Expanded( // Use Expanded to prevent overflow
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Top Headlines',
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 22, // Slightly reduced font size
                                                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Pull-to-refresh hint icon
                                            if (!provider.isLoading)
                                              GestureDetector(
                                                onTap: _handleRefresh,
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Colors.white.withOpacity(0.2),
                                                  ),
                                                  child: Icon(
                                                    Icons.refresh_rounded,
                                                    size: 16,
                                                    color: isDark ? Colors.white70 : const Color(0xFF1A1A2E).withOpacity(0.7),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ).animate().fadeIn(duration: 600.ms).slideX(),
                                        const SizedBox(height: 4), // Added spacing
                                        Text(
                                          'Stay updated with latest news • Pull to refresh',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13, // Slightly reduced font size
                                            color: (isDark ? Colors.white : const Color(0xFF1A1A2E))
                                                .withOpacity(0.7),
                                          ),
                                        ).animate(delay: 200.ms).fadeIn(duration: 600.ms),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16), // Fixed spacing between text and buttons
                                  Row(
                                    mainAxisSize: MainAxisSize.min, // Prevent row from taking unnecessary space
                                    children: [
                                      _buildGlassButton(
                                        icon: Icons.search_rounded,
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const NewsSearchScreen()),
                                        ),
                                      ).animate(delay: 400.ms).scale(),
                                      const SizedBox(width: 10), // Reduced spacing between buttons
                                      _buildGlassButton(
                                        icon: Icons.bookmark_rounded,
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const BookmarksScreen()),
                                        ),
                                      ).animate(delay: 600.ms).scale(),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Categories Section
                SliverToBoxAdapter(
                  child: Container(
                    height: 80,
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final isSelected = provider.selectedCategory == cat.toLowerCase();
                        return GestureDetector(
                          onTap: () => provider.changeCategory(cat.toLowerCase()),
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: isSelected
                                    ? 1.0 + 0.05 * math.sin(_pulseController.value * math.pi)
                                    : 1.0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? LinearGradient(
                                      colors: [
                                        const Color(0xFF667EEA),
                                        const Color(0xFF764BA2),
                                      ],
                                    )
                                        : null,
                                    color: !isSelected
                                        ? Colors.white.withOpacity(isDark ? 0.1 : 0.8)
                                        : null,
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                      BoxShadow(
                                        color: const Color(0xFF667EEA).withOpacity(0.4),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      )
                                    ]
                                        : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(25),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isSelected
                                                  ? Colors.white
                                                  : const Color(0xFF667EEA),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            cat,
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              color: isSelected
                                                  ? Colors.white
                                                  : (isDark ? Colors.white : const Color(0xFF1A1A2E)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ).animate(delay: (index * 100).ms).slideX().fadeIn();
                      },
                    ),
                  ),
                ),

                // Articles List
                provider.isLoading
                    ? SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildShimmerCard(isDark),
                    childCount: 5,
                  ),
                )
                    : provider.articles.isEmpty
                    ? SliverToBoxAdapter(
                  child: Container(
                    height: 300,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF667EEA).withOpacity(0.3),
                                  const Color(0xFF764BA2).withOpacity(0.3),
                                ],
                              ),
                            ),
                            child: Icon(
                              Icons.article_outlined,
                              size: 40,
                              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "No articles found",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Pull down to refresh",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: (isDark ? Colors.white : const Color(0xFF1A1A2E)).withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                    : SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final article = provider.articles[index];
                      final isBookmarked = provider.isBookmarked(article);
                      return _buildArticleCard(article, isBookmarked, isDark, index, provider);
                    },
                    childCount: provider.articles.length,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, // Slightly reduced size to fit better
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.2),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Icon(
              icon,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF1A1A2E),
              size: 22, // Slightly reduced icon size
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Shimmer.fromColors(
        baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildArticleCard(dynamic article, bool isBookmarked, bool isDark, int index, NewsProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
              offset: Offset(0, 5 * math.sin(_floatController.value * math.pi + index * 0.5)),
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
                                        color: (isDark ? Colors.white : const Color(0xFF1A1A2E))
                                            .withOpacity(0.7),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: () {
                                  provider.toggleBookmark(article);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isBookmarked
                                            ? 'Removed from bookmarks'
                                            : 'Saved to bookmarks',
                                      ),
                                      duration: const Duration(seconds: 1),
                                      backgroundColor: const Color(0xFF667EEA),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: isBookmarked
                                        ? LinearGradient(
                                      colors: [
                                        const Color(0xFF667EEA),
                                        const Color(0xFF764BA2),
                                      ],
                                    )
                                        : null,
                                    color: !isBookmarked
                                        ? Colors.grey.withOpacity(0.2)
                                        : null,
                                    boxShadow: isBookmarked
                                        ? [
                                      BoxShadow(
                                        color: const Color(0xFF667EEA).withOpacity(0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                        : null,
                                  ),
                                  child: Icon(
                                    isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                                    color: isBookmarked ? Colors.white : Colors.grey,
                                    size: 20,
                                  ),
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
                                  'Read more',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF667EEA),
                                  ),
                                ),
                              ),
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