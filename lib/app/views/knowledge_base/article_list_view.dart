// lib/app/views/knowledge_base/article_list_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/knowledge_controller.dart';
import '../../models/knowledge_article.dart';
import '../../routes/app_routes.dart';
import '../../utils/constants.dart';

class ArticleListView extends StatelessWidget {
  const ArticleListView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<KnowledgeController>();
    final category = (Get.arguments as String?) ?? 'All';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
        ),
        title: Text(
          category,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Obx(() {
          final articles = category == 'All'
              ? controller.articles.toList()
              : controller.articlesForCategory(category);
          final bookmarkedIds = controller.bookmarkedIds.toSet();

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            itemCount: articles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final article = articles[index];
              return _ArticleCard(
                article: article,
                isBookmarked: bookmarkedIds.contains(article.id),
                onBookmark: () => controller.toggleBookmark(article.id),
                onTap: () => Get.toNamed(
                  AppRoutes.LIBRARY_ARTICLE,
                  arguments: article,
                ),
              );
            },
          );
        }),
      ),
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
