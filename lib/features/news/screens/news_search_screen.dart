import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:math' as math;
import 'dart:ui';

import '../providers/news_provider.dart';
import 'article_webview_screen.dart';

class NewsSearchScreen extends StatefulWidget {
  const NewsSearchScreen({super.key});

  @override
  State<NewsSearchScreen> createState() => _NewsSearchScreenState();
}

class _NewsSearchScreenState extends State<NewsSearchScreen> with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late AnimationController _searchController;
  final TextEditingController _searchTextController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;

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

    _searchController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
      if (_isSearchFocused) {
        _searchController.forward();
      } else {
        _searchController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    _searchController.dispose();
    _searchTextController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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
                              color: (isDark ? Colors.white : Colors.blue)
                                  .withOpacity(0.08),
                              borderRadius: index % 3 != 0
                                  ? BorderRadius.circular(6)
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

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Custom Header with Search
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Top Bar with Back Button and Title
                      Row(
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
                                Text(
                                  'Search News',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                                  ),
                                ).animate().fadeIn(duration: 600.ms).slideX(),
                                Text(
                                  'Find articles that matter to you',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: (isDark ? Colors.white : const Color(0xFF1A1A2E))
                                        .withOpacity(0.7),
                                  ),
                                ).animate(delay: 200.ms).fadeIn(duration: 600.ms),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Enhanced Search Bar
                      AnimatedBuilder(
                        animation: _searchController,
                        builder: (context, child) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(isDark ? 0.15 : 0.9),
                                  Colors.white.withOpacity(isDark ? 0.1 : 0.7),
                                ],
                              ),
                              border: Border.all(
                                color: _isSearchFocused
                                    ? const Color(0xFF667EEA).withOpacity(0.6)
                                    : Colors.white.withOpacity(isDark ? 0.2 : 0.3),
                                width: _isSearchFocused ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _isSearchFocused
                                      ? const Color(0xFF667EEA).withOpacity(0.3)
                                      : Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                                  blurRadius: _isSearchFocused ? 20 : 15,
                                  offset: const Offset(0, 8),
                                  spreadRadius: _isSearchFocused ? 2 : 0,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(25),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                  child: Row(
                                    children: [
                                      AnimatedBuilder(
                                        animation: _pulseController,
                                        builder: (context, child) {
                                          return Transform.scale(
                                            scale: _isSearchFocused
                                                ? 1.0 + 0.1 * math.sin(_pulseController.value * math.pi)
                                                : 1.0,
                                            child: Icon(
                                              Icons.search_rounded,
                                              color: _isSearchFocused
                                                  ? const Color(0xFF667EEA)
                                                  : (isDark ? Colors.white : const Color(0xFF1A1A2E))
                                                  .withOpacity(0.6),
                                              size: 24,
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: TextField(
                                          controller: _searchTextController,
                                          focusNode: _searchFocusNode,
                                          onChanged: provider.onQueryChanged,
                                          style: GoogleFonts.poppins(
                                            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Search for breaking news, stories...',
                                            hintStyle: GoogleFonts.poppins(
                                              color: (isDark ? Colors.white : const Color(0xFF1A1A2E))
                                                  .withOpacity(0.5),
                                              fontSize: 16,
                                            ),
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                          ),
                                        ),
                                      ),
                                      if (_searchTextController.text.isNotEmpty)
                                        GestureDetector(
                                          onTap: () {
                                            _searchTextController.clear();
                                            provider.onQueryChanged('');
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.grey.withOpacity(0.3),
                                            ),
                                            child: Icon(
                                              Icons.close_rounded,
                                              size: 16,
                                              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                                            ),
                                          ),
                                        ).animate().scale(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ).animate(delay: 400.ms).fadeIn(duration: 800.ms).slideY(begin: -0.5),
                    ],
                  ),
                ),

                // Search Results Section
                Expanded(
                  child: _buildSearchResults(provider, isDark),
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

  Widget _buildSearchResults(NewsProvider provider, bool isDark) {
    // Initial state - show search suggestions
    if (!provider.isSearching && _searchTextController.text.isEmpty) {
      return _buildSearchSuggestions(isDark, provider);
    }

    // Loading state
    if (provider.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: 5,
        itemBuilder: (context, index) => _buildShimmerCard(isDark, index),
      );
    }

    // No results state
    if (provider.isSearching && provider.searchResults.isEmpty) {
      return _buildNoResults(isDark);
    }

    // Results list
    if (provider.isSearching && provider.searchResults.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: provider.searchResults.length,
        itemBuilder: (context, index) {
          final article = provider.searchResults[index];
          final isBookmarked = provider.isBookmarked(article);
          return _buildArticleCard(article, isBookmarked, isDark, index, provider);
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSearchSuggestions(bool isDark, NewsProvider provider) {
    final suggestions = [
      {'icon': Icons.trending_up_rounded, 'title': 'Trending News', 'subtitle': 'Latest breaking stories'},
      {'icon': Icons.business_rounded, 'title': 'Business Updates', 'subtitle': 'Market & finance news'},
      {'icon': Icons.sports_soccer_rounded, 'title': 'Sports Highlights', 'subtitle': 'Latest scores & updates'},
      {'icon': Icons.computer_rounded, 'title': 'Technology', 'subtitle': 'Tech innovations & reviews'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'Popular Searches',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ).animate().fadeIn(duration: 600.ms),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                return GestureDetector(
                  onTap: () {
                    _searchTextController.text = suggestion['title'] as String;
                    provider.onQueryChanged(suggestion['title'] as String);
                  },
                  child: AnimatedBuilder(
                    animation: _floatController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 3 * math.sin(_floatController.value * math.pi + index * 0.5)),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(isDark ? 0.1 : 0.8),
                                Colors.white.withOpacity(isDark ? 0.05 : 0.6),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(isDark ? 0.2 : 0.3),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Row(
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
                                    ),
                                    child: Icon(
                                      suggestion['icon'] as IconData,
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
                                          suggestion['title'] as String,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          suggestion['subtitle'] as String,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: (isDark ? Colors.white : const Color(0xFF1A1A2E))
                                                .withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: (isDark ? Colors.white : const Color(0xFF1A1A2E))
                                        .withOpacity(0.4),
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ).animate(delay: (index * 150).ms).fadeIn(duration: 600.ms).slideX(begin: 0.3);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + 0.05 * math.sin(_pulseController.value * math.pi),
                child: Container(
                  width: 100,
                  height: 100,
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
                    Icons.search_off_rounded,
                    size: 50,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            "No articles found",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Try searching with different keywords\nor check your spelling",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: (isDark ? Colors.white : const Color(0xFF1A1A2E))
                  .withOpacity(0.6),
            ),
          ),
        ],
      ),
    ).animate()
        .fadeIn(duration: 800.ms)
        .scale(begin: Offset(0.8, 0.8));
  }

  Widget _buildShimmerCard(bool isDark, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
    ).animate(delay: (index * 100).ms).fadeIn();
  }

  Widget _buildArticleCard(dynamic article, bool isBookmarked, bool isDark, int index, NewsProvider provider) {
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