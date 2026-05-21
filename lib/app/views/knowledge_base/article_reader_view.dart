// lib/app/views/knowledge_base/article_reader_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/knowledge_controller.dart';
import '../../models/knowledge_article.dart';
import '../../utils/constants.dart';

class ArticleReaderView extends StatelessWidget {
  const ArticleReaderView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<KnowledgeController>();
    final article = Get.arguments as KnowledgeArticle;

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
          article.category,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Obx(() {
            final isBookmarked = controller.isBookmarked(article.id);
            return IconButton(
              onPressed: () => controller.toggleBookmark(article.id),
              icon: Icon(
                isBookmarked ? Icons.bookmark : Icons.bookmark_border_outlined,
                color: isBookmarked ? AppColors.primary : AppColors.textMuted,
              ),
            );
          }),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
          children: [
            Text(
              '${article.category} · ${article.readTimeMinutes} min read',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Text(
              article.title,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),
            if (article.isCached)
              const Row(
                children: [
                  Text(
                    '✓',
                    style: TextStyle(color: AppColors.primary, fontSize: 12),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Cached  ·  Available offline',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 10),
            ..._ArticleContentRenderer.render(article.content),
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Text(
                controller.footerSyncAge,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleContentRenderer {
  _ArticleContentRenderer._();

  static List<Widget> render(String content) {
    return content
        .split('\n')
        .map((line) => _renderLine(line))
        .whereType<Widget>()
        .toList();
  }

  static Widget? _renderLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      return const SizedBox(height: 8);
    }

    if (trimmed.startsWith('## ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(
          trimmed.substring(3),
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final numberedMatch = RegExp(r'^(\d+)\.\s+(.*)$').firstMatch(trimmed);
    if (numberedMatch != null) {
      return Padding(
        padding: const EdgeInsets.only(left: 16, top: 7, bottom: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${numberedMatch.group(1)}.',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                numberedMatch.group(2) ?? '',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (trimmed.startsWith('□ ')) {
      return _ChecklistRow(
        icon: Icons.check_box_outline_blank,
        text: trimmed.substring(2),
        textColor: AppColors.white,
        iconColor: AppColors.textMuted,
      );
    }

    if (trimmed.startsWith('✓ ')) {
      return _ChecklistRow(
        icon: Icons.check_box,
        text: trimmed.substring(2),
        textColor: AppColors.textMuted,
        iconColor: AppColors.primary,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        trimmed,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color textColor;
  final Color iconColor;

  const _ChecklistRow({
    required this.icon,
    required this.text,
    required this.textColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 7, bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: textColor, fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
