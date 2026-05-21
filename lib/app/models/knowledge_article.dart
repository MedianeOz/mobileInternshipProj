// lib/app/models/knowledge_article.dart

class KnowledgeArticle {
  final String id;
  final String title;
  final String summary;
  final String category;
  final int readTimeMinutes;
  final String content;
  final bool isCached;

  const KnowledgeArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.category,
    required this.readTimeMinutes,
    required this.content,
    this.isCached = true,
  });

  factory KnowledgeArticle.fromJson(Map<String, dynamic> json) {
    return KnowledgeArticle(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      readTimeMinutes: int.tryParse(json['readTimeMinutes'].toString()) ?? 1,
      content: json['content']?.toString() ?? '',
      isCached: json['isCached'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'category': category,
      'readTimeMinutes': readTimeMinutes,
      'content': content,
      'isCached': isCached,
    };
  }
}
