// lib/app/services/storage_service.dart
//
// Hive-backed local storage for the offline security knowledge base.

import 'package:hive/hive.dart';

import '../models/knowledge_article.dart';

class StorageService {
  static const knowledgeArticlesBox = 'knowledge_articles';
  static const bookmarksBox = 'bookmarks';
  static const syncMetaBox = 'sync_meta';
  static const threatCacheBox = 'threat_cache';
  static const profileBox = 'user_profile';
  static const notificationHistoryBox = 'notification_history';

  Box<dynamic>? _articlesBox;
  Box<dynamic>? _bookmarksBox;
  Box<dynamic>? _syncMetaBox;
  Box<dynamic>? _threatCacheBox;
  Box<dynamic>? _profileBox;
  Box<dynamic>? _notificationHistoryBox;

  Future<void> init() async {
    _articlesBox ??= await Hive.openBox<dynamic>(knowledgeArticlesBox);
    _bookmarksBox ??= await Hive.openBox<dynamic>(bookmarksBox);
    _syncMetaBox ??= await Hive.openBox<dynamic>(syncMetaBox);
    _threatCacheBox ??= await Hive.openBox<dynamic>(threatCacheBox);
    _profileBox ??= await Hive.openBox<dynamic>(profileBox);
    _notificationHistoryBox ??=
        await Hive.openBox<dynamic>(notificationHistoryBox);
  }

  Future<void> saveArticles(List<KnowledgeArticle> articles) async {
    await init();
    await _articlesBox!.clear();
    for (final article in articles) {
      await _articlesBox!.put(article.id, article.toJson());
    }
  }

  List<KnowledgeArticle> getCachedArticles() {
    final values = _articlesBox?.values ?? const Iterable<dynamic>.empty();
    return values
        .whereType<Map>()
        .map((item) =>
            KnowledgeArticle.fromJson(Map<String, dynamic>.from(item)))
        .where((article) => article.id.isNotEmpty)
        .toList();
  }

  Future<void> toggleBookmark(String articleId) async {
    await init();
    final isBookmarked = _bookmarksBox!.get(articleId) == true;
    if (isBookmarked) {
      await _bookmarksBox!.delete(articleId);
      return;
    }
    await _bookmarksBox!.put(articleId, true);
  }

  Set<String> getBookmarkedIds() {
    return (_bookmarksBox?.keys ?? const Iterable<dynamic>.empty())
        .map((key) => key.toString())
        .toSet();
  }

  DateTime? getLastSyncTime() {
    final raw = _syncMetaBox?.get('last_sync')?.toString();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> setLastSyncTime(DateTime dt) async {
    await init();
    await _syncMetaBox!.put('last_sync', dt.toIso8601String());
  }

  Future<void> saveThreatPage({
    required String cacheKey,
    required List<Map<String, dynamic>> serialized,
  }) async {
    await init();
    await _threatCacheBox!.put(cacheKey, serialized);
  }

  List<Map<String, dynamic>> getCachedThreatPage(String cacheKey) {
    final exact = _readThreatPage(cacheKey);
    if (exact.isNotEmpty) return exact;

    final matchingKey = _newestMatchingThreatKey(cacheKey);
    if (matchingKey == null) return <Map<String, dynamic>>[];
    return _readThreatPage(matchingKey);
  }

  Future<void> clearThreatCache() async {
    await init();
    await _threatCacheBox!.clear();
  }

  Future<void> saveProfile(Map<String, dynamic> profileJson) async {
    await init();
    await _profileBox!.put('profile', profileJson);
  }

  Map<String, dynamic>? loadProfile() {
    final raw = _profileBox?.get('profile');
    if (raw is! Map) return null;
    return Map<String, dynamic>.from(raw);
  }

  Future<void> saveNotification(Map<String, dynamic> notificationJson) async {
    await init();
    final key = notificationJson['id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();
    await _notificationHistoryBox!.put(key, notificationJson);
  }

  List<Map<String, dynamic>> getNotificationHistory() {
    final values =
        _notificationHistoryBox?.values ?? const Iterable<dynamic>.empty();
    return values
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList()
      ..sort((a, b) {
        final aTime = a['timestamp']?.toString() ?? '';
        final bTime = b['timestamp']?.toString() ?? '';
        return bTime.compareTo(aTime);
      });
  }

  Future<void> markNotificationRead(String id) async {
    await init();
    final raw = _notificationHistoryBox?.get(id);
    if (raw is! Map) return;
    final updated = Map<String, dynamic>.from(raw);
    updated['isRead'] = true;
    await _notificationHistoryBox!.put(id, updated);
  }

  Future<void> markAllNotificationsRead() async {
    await init();
    final keys = _notificationHistoryBox?.keys.toList() ?? [];
    for (final key in keys) {
      final raw = _notificationHistoryBox?.get(key);
      if (raw is! Map) continue;
      final updated = Map<String, dynamic>.from(raw);
      updated['isRead'] = true;
      await _notificationHistoryBox!.put(key, updated);
    }
  }

  Future<void> clearNotificationHistory() async {
    await init();
    await _notificationHistoryBox!.clear();
  }

  int getUnreadNotificationCount() {
    final values =
        _notificationHistoryBox?.values ?? const Iterable<dynamic>.empty();
    return values
        .whereType<Map>()
        .where((item) => item['isRead'] != true)
        .length;
  }

  List<KnowledgeArticle> getStaticArticles() {
    return staticArticleData.map(KnowledgeArticle.fromJson).toList();
  }

  List<Map<String, dynamic>> _readThreatPage(String cacheKey) {
    final raw = _threatCacheBox?.get(cacheKey);
    if (raw is! List) return <Map<String, dynamic>>[];

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String? _newestMatchingThreatKey(String cacheKey) {
    final prefix = _threatFilterPrefix(cacheKey);
    if (prefix == null) return null;

    final keys = _threatCacheBox?.keys ?? const Iterable<dynamic>.empty();
    final matches = keys
        .map((key) => key.toString())
        .where((key) => key.startsWith(prefix))
        .toList()
      ..sort();

    if (matches.isEmpty) return null;
    return matches.last;
  }

  String? _threatFilterPrefix(String cacheKey) {
    final markerIndex = cacheKey.indexOf('|pubStart=');
    if (markerIndex <= 0) return null;
    return '${cacheKey.substring(0, markerIndex)}|';
  }

  static const List<Map<String, dynamic>> staticArticleData = [
    {
      'id': 'pw-001',
      'title': 'How to create a strong master password',
      'category': 'Passwords',
      'readTimeMinutes': 5,
      'summary': 'Build an unbreakable foundation password using passphrases',
      'content': '## What makes a master password strong\n'
          '1. Use a passphrase of 4+ random words\n'
          '2. Insert numbers between words\n'
          '3. Add a special character\n\n'
          '## Quick checklist\n'
          '□ At least 16 characters\n'
          '□ No dictionary words used alone\n'
          '□ Unique - not reused anywhere\n'
          '□ Stored in a password manager',
      'isCached': true,
    },
    {
      'id': 'pw-002',
      'title': 'Why password reuse is dangerous',
      'category': 'Passwords',
      'readTimeMinutes': 4,
      'summary': 'Understand credential stuffing and how one leak spreads',
      'content': '## The reuse problem\n'
          '1. Attackers test leaked passwords across many services\n'
          '2. Automated tools can try thousands of accounts quickly\n'
          '3. A single reused password can expose email, banking, and work apps\n\n'
          '## Quick checklist\n'
          '□ Use a unique password for every account\n'
          '□ Change passwords found in breaches first\n'
          '□ Enable MFA on important accounts',
      'isCached': true,
    },
    {
      'id': 'pw-003',
      'title': 'Password manager setup basics',
      'category': 'Passwords',
      'readTimeMinutes': 5,
      'summary': 'Start using a vault safely without losing access',
      'content': '## First setup\n'
          '1. Pick a reputable password manager\n'
          '2. Create a strong master password\n'
          '3. Store recovery codes in a safe offline place\n\n'
          '## Quick checklist\n'
          '□ Import passwords from your browser\n'
          '□ Replace weak passwords over time\n'
          '□ Lock the vault automatically',
      'isCached': true,
    },
    {
      'id': 'pw-004',
      'title': 'Multi-factor authentication priorities',
      'category': 'Passwords',
      'readTimeMinutes': 4,
      'summary': 'Choose which accounts need MFA first',
      'content': '## Priority order\n'
          '1. Email accounts\n'
          '2. Banking and payment apps\n'
          '3. Cloud storage and work accounts\n\n'
          '## Safer methods\n'
          '□ Authenticator apps are better than SMS\n'
          '□ Hardware keys are strongest for high-risk accounts\n'
          '□ Save backup codes securely',
      'isCached': true,
    },
    {
      'id': 'pw-005',
      'title': 'How to rotate a compromised password',
      'category': 'Passwords',
      'readTimeMinutes': 3,
      'summary': 'Change a leaked password without missing connected accounts',
      'content': '## Rotation steps\n'
          '1. Change the password on the breached service\n'
          '2. Search your vault for reused copies\n'
          '3. Sign out all active sessions\n\n'
          '## Quick checklist\n'
          '□ Update saved passwords on every device\n'
          '□ Review recent account activity\n'
          '□ Turn on MFA after rotating',
      'isCached': true,
    },
    {
      'id': 'pw-006',
      'title': 'Passphrases vs random passwords',
      'category': 'Passwords',
      'readTimeMinutes': 4,
      'summary': 'Know when to use memorable phrases or generated secrets',
      'content': '## Choosing the right format\n'
          '1. Use passphrases for passwords you must type manually\n'
          '2. Use generated random passwords for vault-stored accounts\n'
          '3. Avoid song lyrics, quotes, and predictable substitutions\n\n'
          '## Quick checklist\n'
          '□ Four or more random words for passphrases\n'
          '□ 16+ characters for generated passwords\n'
          '□ Never base passwords on public profile details',
      'isCached': true,
    },
    {
      'id': 'pw-007',
      'title': 'Protecting recovery codes',
      'category': 'Passwords',
      'readTimeMinutes': 3,
      'summary': 'Keep account recovery options from becoming the weakest link',
      'content': '## Recovery risks\n'
          '1. Recovery codes bypass your password and MFA\n'
          '2. Screenshots can sync into cloud galleries\n'
          '3. Email recovery should be protected with MFA\n\n'
          '## Quick checklist\n'
          '□ Print or write codes and store them safely\n'
          '□ Delete screenshots after saving codes\n'
          '□ Review backup email and phone numbers',
      'isCached': true,
    },
    {
      'id': 'pw-008',
      'title': 'Spotting weak password patterns',
      'category': 'Passwords',
      'readTimeMinutes': 3,
      'summary': 'Recognize predictable choices attackers try first',
      'content': '## Common weak patterns\n'
          '1. Seasons and years such as Summer2026\n'
          '2. Keyboard walks such as qwerty or asdf\n'
          '3. Company, pet, school, or team names\n\n'
          '## Quick checklist\n'
          '□ Avoid personal facts\n'
          '□ Avoid single dictionary words\n'
          '□ Let a password manager generate secrets',
      'isCached': true,
    },
    {
      'id': 'net-101',
      'title': 'Secure your home router',
      'category': 'Network',
      'readTimeMinutes': 5,
      'summary': 'Reduce the most common Wi-Fi and router risks',
      'content': '## Router hardening\n'
          '1. Change the admin password\n'
          '2. Install firmware updates\n'
          '3. Use WPA2 or WPA3 encryption\n\n'
          '## Quick checklist\n'
          '□ Disable WPS\n'
          '□ Use a separate guest network\n'
          '□ Rename the default network name',
      'isCached': true,
    },
    {
      'id': 'net-102',
      'title': 'Public Wi-Fi safety checklist',
      'category': 'Network',
      'readTimeMinutes': 4,
      'summary': 'Use shared networks without exposing accounts',
      'content': '## Before connecting\n'
          '1. Confirm the network name with staff\n'
          '2. Avoid banking or sensitive admin work\n'
          '3. Prefer mobile data for critical actions\n\n'
          '## Quick checklist\n'
          '□ Turn off auto-join for public Wi-Fi\n'
          '□ Use HTTPS sites only\n'
          '□ Forget the network after use',
      'isCached': true,
    },
    {
      'id': 'net-103',
      'title': 'What DNS filtering can block',
      'category': 'Network',
      'readTimeMinutes': 3,
      'summary': 'Learn how DNS protection stops known malicious domains',
      'content': '## DNS filtering basics\n'
          '1. Your device asks DNS where a domain lives\n'
          '2. A filter can block known malware or phishing domains\n'
          '3. Filtering works best with browser and device updates\n\n'
          '## Quick checklist\n'
          '□ Use a trusted DNS provider\n'
          '□ Do not ignore browser warnings\n'
          '□ Report suspicious blocked pages',
      'isCached': true,
    },
    {
      'id': 'net-104',
      'title': 'Recognizing rogue access points',
      'category': 'Network',
      'readTimeMinutes': 4,
      'summary': 'Avoid fake hotspots that imitate trusted locations',
      'content': '## Warning signs\n'
          '1. Duplicate network names with small spelling differences\n'
          '2. Login portals asking for unnecessary credentials\n'
          '3. Open networks in places that normally use passwords\n\n'
          '## Quick checklist\n'
          '□ Ask staff for the exact network name\n'
          '□ Avoid unknown captive portals\n'
          '□ Use mobile data when unsure',
      'isCached': true,
    },
    {
      'id': 'net-105',
      'title': 'VPN use without false confidence',
      'category': 'Network',
      'readTimeMinutes': 4,
      'summary': 'Know what a VPN protects and what it cannot fix',
      'content': '## VPN reality\n'
          '1. A VPN hides traffic from the local network operator\n'
          '2. It does not make phishing sites safe\n'
          '3. It does not replace strong account security\n\n'
          '## Quick checklist\n'
          '□ Use a trusted VPN provider\n'
          '□ Keep MFA enabled\n'
          '□ Check domain names before signing in',
      'isCached': true,
    },
    {
      'id': 'net-106',
      'title': 'Basic firewall thinking',
      'category': 'Network',
      'readTimeMinutes': 3,
      'summary': 'Understand inbound and outbound access decisions',
      'content': '## Firewall basics\n'
          '1. Inbound rules control who can reach your device\n'
          '2. Outbound rules control what your device can contact\n'
          '3. The safest rule is to allow only what you need\n\n'
          '## Quick checklist\n'
          '□ Disable unused sharing services\n'
          '□ Remove old allow rules\n'
          '□ Review alerts before approving access',
      'isCached': true,
    },
    {
      'id': 'net-001',
      'title': 'How to identify a phishing email in 30 seconds',
      'category': 'Phishing',
      'readTimeMinutes': 4,
      'summary': 'Learn the key signs of phishing attempts',
      'content': '## What to look for\n'
          '1. Sender domain mismatch\n'
          '2. Urgency or threatening language\n'
          '3. Generic salutation ("Dear customer")\n'
          '4. Suspicious links - hover to preview\n\n'
          '## Quick checklist\n'
          '□ Check sender domain\n'
          '□ Hover all links before clicking\n'
          '□ Never enter credentials on a redirect\n'
          '□ When in doubt - call the sender',
      'isCached': true,
    },
    {
      'id': 'ph-002',
      'title': 'Smishing: phishing by text message',
      'category': 'Phishing',
      'readTimeMinutes': 3,
      'summary': 'Spot malicious delivery, bank, and account SMS messages',
      'content': '## Smishing signs\n'
          '1. Short links with no context\n'
          '2. Claims of urgent delivery or account holds\n'
          '3. Requests for codes, PINs, or payment details\n\n'
          '## Quick checklist\n'
          '□ Do not tap suspicious short links\n'
          '□ Open the official app manually\n'
          '□ Never share one-time codes',
      'isCached': true,
    },
    {
      'id': 'ph-003',
      'title': 'Fake login pages',
      'category': 'Phishing',
      'readTimeMinutes': 4,
      'summary': 'Check domains and browser signals before entering passwords',
      'content': '## Page checks\n'
          '1. Read the full domain carefully\n'
          '2. Watch for misspellings and extra words\n'
          '3. Avoid logging in from links in messages\n\n'
          '## Quick checklist\n'
          '□ Use bookmarks for important sites\n'
          '□ Check password manager autofill behavior\n'
          '□ Close pages that ask for unusual information',
      'isCached': true,
    },
    {
      'id': 'ph-004',
      'title': 'Business email compromise basics',
      'category': 'Phishing',
      'readTimeMinutes': 5,
      'summary': 'Recognize payment and invoice fraud attempts',
      'content': '## Common scenarios\n'
          '1. A vendor asks to change bank details\n'
          '2. An executive requests urgent gift cards\n'
          '3. An invoice arrives from a lookalike domain\n\n'
          '## Quick checklist\n'
          '□ Verify payment changes by phone\n'
          '□ Use known contact numbers\n'
          '□ Slow down urgent financial requests',
      'isCached': true,
    },
    {
      'id': 'ph-005',
      'title': 'Reporting phishing safely',
      'category': 'Phishing',
      'readTimeMinutes': 3,
      'summary': 'Capture useful evidence without increasing risk',
      'content': '## Reporting steps\n'
          '1. Do not forward suspicious attachments casually\n'
          '2. Use the official report phishing button if available\n'
          '3. Include sender, subject, and time received\n\n'
          '## Quick checklist\n'
          '□ Do not click links to investigate\n'
          '□ Report quickly\n'
          '□ Delete only after reporting policy allows it',
      'isCached': true,
    },
    {
      'id': 'mob-001',
      'title': 'Mobile app permission review',
      'category': 'Mobile',
      'readTimeMinutes': 4,
      'summary': 'Reduce data exposure from unnecessary permissions',
      'content': '## Permission review\n'
          '1. Check location, contacts, microphone, and camera access\n'
          '2. Remove permissions that do not match app purpose\n'
          '3. Prefer while-in-use location access\n\n'
          '## Quick checklist\n'
          '□ Review permissions monthly\n'
          '□ Remove apps you no longer use\n'
          '□ Keep sensitive apps behind device lock',
      'isCached': true,
    },
    {
      'id': 'mob-002',
      'title': 'Keep your phone patched',
      'category': 'Mobile',
      'readTimeMinutes': 3,
      'summary': 'Why OS and app updates matter for mobile security',
      'content': '## Patch habits\n'
          '1. Enable automatic OS updates\n'
          '2. Update apps from official stores\n'
          '3. Restart after major updates when requested\n\n'
          '## Quick checklist\n'
          '□ Check update settings\n'
          '□ Remove unsupported devices from sensitive work\n'
          '□ Avoid sideloaded updates',
      'isCached': true,
    },
    {
      'id': 'mob-003',
      'title': 'Lost phone response',
      'category': 'Mobile',
      'readTimeMinutes': 4,
      'summary': 'Act quickly to reduce account and data exposure',
      'content': '## First actions\n'
          '1. Use Find My Device or Find My iPhone\n'
          '2. Lock the device remotely\n'
          '3. Rotate passwords for critical accounts if needed\n\n'
          '## Quick checklist\n'
          '□ Contact your mobile carrier\n'
          '□ Revoke sessions from important apps\n'
          '□ File a report if work data is involved',
      'isCached': true,
    },
    {
      'id': 'mob-004',
      'title': 'Avoid unsafe sideloading',
      'category': 'Mobile',
      'readTimeMinutes': 3,
      'summary': 'Understand why unofficial APKs and profiles are risky',
      'content': '## Sideloading risks\n'
          '1. Apps may be modified with malware\n'
          '2. Updates can bypass store review\n'
          '3. Configuration profiles can grant powerful access\n\n'
          '## Quick checklist\n'
          '□ Install from official stores\n'
          '□ Remove unknown profiles\n'
          '□ Scan app names before trusting links',
      'isCached': true,
    },
    {
      'id': 'inc-001',
      'title': 'First 15 minutes after an account takeover',
      'category': 'Incident',
      'readTimeMinutes': 5,
      'summary': 'Contain damage quickly after suspicious account activity',
      'content': '## Immediate response\n'
          '1. Change the password from a trusted device\n'
          '2. Revoke active sessions\n'
          '3. Enable or reset MFA\n\n'
          '## Quick checklist\n'
          '□ Save suspicious emails or alerts\n'
          '□ Check forwarding rules\n'
          '□ Notify affected contacts if messages were sent',
      'isCached': true,
    },
    {
      'id': 'inc-002',
      'title': 'What evidence to save during an incident',
      'category': 'Incident',
      'readTimeMinutes': 4,
      'summary': 'Preserve useful details without changing too much',
      'content': '## Evidence basics\n'
          '1. Record timestamps and account names\n'
          '2. Capture screenshots of alerts\n'
          '3. Save suspicious sender details and URLs\n\n'
          '## Quick checklist\n'
          '□ Do not delete logs before review\n'
          '□ Keep notes factual\n'
          '□ Share evidence through approved channels',
      'isCached': true,
    },
    {
      'id': 'inc-003',
      'title': 'Personal incident recovery checklist',
      'category': 'Incident',
      'readTimeMinutes': 5,
      'summary': 'Recover accounts and devices after a security scare',
      'content': '## Recovery sequence\n'
          '1. Secure email first\n'
          '2. Rotate important passwords\n'
          '3. Scan devices and remove suspicious apps\n\n'
          '## Quick checklist\n'
          '□ Review bank and payment activity\n'
          '□ Check social account recovery settings\n'
          '□ Monitor for new login alerts',
      'isCached': true,
    },
  ];
}
