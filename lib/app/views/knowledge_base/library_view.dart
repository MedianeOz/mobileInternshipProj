// lib/app/views/knowledge_base/library_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/knowledge_controller.dart';
import '../../models/knowledge_article.dart';
import '../../routes/app_routes.dart';
import '../../utils/constants.dart';

class LibraryView extends StatefulWidget {
  const LibraryView({super.key});

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  late final TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<KnowledgeController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Obx(() {
              if (!controller.isOffline.value) return const SizedBox.shrink();
              return _OfflineBanner(
                  text: 'Offline · ${controller.offlineCacheAge}');
            }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Library',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Obx(() {
                        final active = controller.showBookmarksOnly.value;
                        return IconButton(
                          onPressed: controller.toggleBookmarksOnly,
                          icon: Icon(
                            active
                                ? Icons.bookmark
                                : Icons.bookmark_border_outlined,
                            color: active
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SearchField(
                    controller: searchController,
                    onChanged: controller.search,
                  ),
                  const SizedBox(height: 22),
                  Obx(() {
                    if (controller.isLoading.value) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    }

                    final showList = controller.showBookmarksOnly.value ||
                        controller.selectedCategory.value != 'All' ||
                        controller.searchQuery.value.isNotEmpty;

                    if (showList) {
                      final bookmarkedIds = controller.bookmarkedIds.toSet();
                      return _ArticleList(
                        title: _currentListTitle(controller),
                        articles: controller.filteredArticles.toList(),
                        bookmarkedIds: bookmarkedIds,
                        controller: controller,
                      );
                    }

                    final categoryCounts = {
                      for (final category in KnowledgeController.categories)
                        category: controller.countForCategory(category),
                    };
                    return _CategoryGrid(
                      controller: controller,
                      categoryCounts: categoryCounts,
                      bookmarkCount: controller.bookmarkCount,
                    );
                  }),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _currentListTitle(KnowledgeController controller) {
    if (controller.showBookmarksOnly.value) return 'Bookmarks';
    if (controller.selectedCategory.value != 'All') {
      return controller.selectedCategory.value;
    }
    return 'Search results';
  }
}

class _OfflineBanner extends StatelessWidget {
  final String text;

  const _OfflineBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        border: const Border(
          bottom: BorderSide(color: AppColors.warning, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.warning,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: 'Search guides...',
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 15),
        prefixIcon: const Icon(
          Icons.search,
          color: AppColors.textMuted,
          size: 18,
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final KnowledgeController controller;
  final Map<String, int> categoryCounts;
  final int bookmarkCount;

  const _CategoryGrid({
    required this.controller,
    required this.categoryCounts,
    required this.bookmarkCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categories',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: [
            for (final category in KnowledgeController.categories)
              _CategoryCard(
                emoji: _categoryEmoji(category),
                title: category,
                subtitle: '${categoryCounts[category] ?? 0} guides',
                onTap: () => controller.filterByCategory(category),
              ),
            _BookmarksCard(
              count: bookmarkCount,
              onTap: controller.toggleBookmarksOnly,
            ),
          ],
        ),
      ],
    );
  }

  static String _categoryEmoji(String category) {
    switch (category) {
      case 'Passwords':
        return '🔒';
      case 'Network':
        return '🌐';
      case 'Phishing':
        return '🎣';
      case 'Mobile':
        return '📱';
      case 'Incident':
        return '🚨';
      default:
        return '📘';
    }
  }
}

class _CategoryCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookmarksCard extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _BookmarksCard({
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.bookmark, color: AppColors.primary, size: 28),
            const Spacer(),
            const Text(
              'Bookmarks',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$count saved',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleList extends StatelessWidget {
  final String title;
  final List<KnowledgeArticle> articles;
  final Set<String> bookmarkedIds;
  final KnowledgeController controller;

  const _ArticleList({
    required this.title,
    required this.articles,
    required this.bookmarkedIds,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (controller.selectedCategory.value != 'All')
              TextButton(
                onPressed: controller.clearCategory,
                child: const Text(
                  'All categories',
                  style: TextStyle(color: AppColors.primary, fontSize: 13),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (articles.isEmpty)
          const _EmptyLibraryState()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: articles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final article = articles[index];
              return _ArticleCard(
                article: article,
                isBookmarked: bookmarkedIds.contains(article.id),
                onTap: () => Get.toNamed(
                  AppRoutes.LIBRARY_ARTICLE,
                  arguments: article,
                ),
                onBookmark: () => controller.toggleBookmark(article.id),
              );
            },
          ),
      ],
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final KnowledgeArticle article;
  final bool isBookmarked;
  final VoidCallback onTap;
  final VoidCallback onBookmark;

  const _ArticleCard({
    required this.article,
    required this.isBookmarked,
    required this.onTap,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              article.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              article.summary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                if (article.isCached) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Cached  ${article.readTimeMinutes} min read',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                  ),
                ] else
                  Text(
                    '${article.readTimeMinutes} min read',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                const Spacer(),
                GestureDetector(
                  onTap: onBookmark,
                  child: Icon(
                    isBookmarked
                        ? Icons.bookmark
                        : Icons.bookmark_border_outlined,
                    color:
                        isBookmarked ? AppColors.primary : AppColors.textMuted,
                    size: 22,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyLibraryState extends StatelessWidget {
  const _EmptyLibraryState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 72),
      child: Center(
        child: Text(
          'No guides found.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      ),
    );
  }
}
