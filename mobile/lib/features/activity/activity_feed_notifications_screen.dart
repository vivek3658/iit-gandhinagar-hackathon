import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/auth_config.dart';
import '../../services/auth_service.dart';

/// Clean White-Theme Activity Feed & System Notification Center
/// Matches hackathon judge design and wireframe specifications:
/// - Grouped by Time (Today, Yesterday, Earlier)
/// - Crisp White cards with Slate typography & Emerald accents
/// - Unread badge tracking and live backend sync
class ActivityFeedNotificationsScreen extends StatefulWidget {
  final VoidCallback onBackToSanctuary;

  const ActivityFeedNotificationsScreen({
    super.key,
    required this.onBackToSanctuary,
  });

  @override
  State<ActivityFeedNotificationsScreen> createState() =>
      _ActivityFeedNotificationsScreenState();
}

class _ActivityFeedNotificationsScreenState
    extends State<ActivityFeedNotificationsScreen> {
  static const _filters = <(String, String)>[
    ('All', 'ALL'),
    ('Habits', 'HABIT'),
    ('Sanctuary', 'SANCTUARY'),
    ('Community', 'COMMUNITY'),
    ('Alerts', 'ALERT'),
  ];

  final HttpClient _http = HttpClient()
    ..connectionTimeout = const Duration(seconds: 8);
  String _category = 'ALL';
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  @override
  void dispose() {
    _http.close(force: true);
    super.dispose();
  }

  Future<Map<String, dynamic>> _request(String path, {String method = 'GET'}) async {
    final token = AuthService.instance.accessToken;
    if (token == null || token.isEmpty) {
      throw Exception('Sign in to load your activity.');
    }
    final uri = Uri.parse('${AuthConfig.apiBaseUrl}$path');
    final request = await _http.openUrl(method, uri);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    request.headers.contentType = ContentType.json;
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Activity request failed (${response.statusCode}).');
    }
    return body.isEmpty ? <String, dynamic>{} : jsonDecode(body) as Map<String, dynamic>;
  }

  Future<void> _loadFeed() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _request('/activity?category=$_category&limit=50');
      final rows = (data['activities'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
      if (!mounted) return;
      setState(() {
        _items = rows;
        _unreadCount = (data['unreadCount'] as num?)?.toInt() ?? 0;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _markRead(String id) async {
    try {
      await _request('/activity/$id/read', method: 'POST');
      if (!mounted) return;
      setState(() {
        final index = _items.indexWhere((item) => item['id'] == id);
        if (index >= 0) _items[index] = {..._items[index], 'isRead': true};
        if (_unreadCount > 0) _unreadCount--;
      });
    } catch (error) {
      if (mounted) _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _request('/activity/read-all', method: 'POST');
      if (!mounted) return;
      setState(() {
        _items = _items.map((item) => {...item, 'isRead': true}).toList();
        _unreadCount = 0;
      });
    } catch (error) {
      if (mounted) _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Map<String, List<Map<String, dynamic>>> _groupItemsByTime() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<Map<String, dynamic>>> groups = {
      'TODAY': [],
      'YESTERDAY': [],
      'EARLIER THIS WEEK': [],
    };

    for (final item in _items) {
      final date = DateTime.tryParse(item['createdAt'] as String? ?? '')?.toLocal();
      if (date == null) {
        groups['TODAY']!.add(item);
        continue;
      }
      final itemDay = DateTime(date.year, date.month, date.day);
      if (itemDay.isAtSameMomentAs(today)) {
        groups['TODAY']!.add(item);
      } else if (itemDay.isAtSameMomentAs(yesterday)) {
        groups['YESTERDAY']!.add(item);
      } else {
        groups['EARLIER THIS WEEK']!.add(item);
      }
    }

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupItemsByTime();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Crisp Slate-50 background
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  _roundButton(
                    Icons.arrow_back_rounded,
                    widget.onBackToSanctuary,
                    tooltip: 'Back to Mascot',
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MISSION LiFE NOTIFICATIONS',
                          style: TextStyle(
                            color: Color(0xFF16A34A),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Activity Feed${_unreadCount > 0 ? '  ·  $_unreadCount new' : ''}',
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _roundButton(
                    Icons.refresh_rounded,
                    _loadFeed,
                    tooltip: 'Refresh',
                  ),
                  if (_unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    _roundButton(
                      Icons.done_all_rounded,
                      _markAllRead,
                      tooltip: 'Mark All Read',
                    ),
                  ],
                ],
              ),
            ),

            // Category Filter Chips
            SizedBox(
              height: 46,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final selected = _category == filter.$2;
                  return ChoiceChip(
                    label: Text(filter.$1),
                    selected: selected,
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setState(() => _category = filter.$2);
                      _loadFeed();
                    },
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFF16A34A),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF334155),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: selected ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  );
                },
              ),
            ),

            // Activity List Grouped by Time
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF16A34A)))
                  : _error != null
                      ? _statusCard(
                          Icons.cloud_off_rounded,
                          'Could not sync your journal',
                          _error!,
                          action: 'Retry',
                          onAction: _loadFeed,
                        )
                      : _items.isEmpty
                          ? _statusCard(
                              Icons.auto_awesome_rounded,
                              'No activity records yet',
                              'Real device logs, completed habits, and sanctuary events will appear here as you play.',
                            )
                          : RefreshIndicator(
                              color: const Color(0xFF16A34A),
                              backgroundColor: Colors.white,
                              onRefresh: _loadFeed,
                              child: ListView(
                                padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                                children: [
                                  for (final entry in grouped.entries)
                                    if (entry.value.isNotEmpty) ...[
                                      _buildTimeHeader(entry.key),
                                      for (final item in entry.value)
                                        _activityCard(item),
                                      const SizedBox(height: 8),
                                    ],
                                ],
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontWeight: FontWeight.w800,
                fontSize: 10,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
        ],
      ),
    );
  }

  Widget _roundButton(IconData icon, VoidCallback onTap, {String? tooltip}) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A0F172A),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: const Color(0xFF334155), size: 19),
          ),
        ),
      );

  Widget _activityCard(Map<String, dynamic> item) {
    final isRead = item['isRead'] == true;
    final category = (item['category'] as String? ?? 'HABIT').toUpperCase();
    final icon = switch (item['icon'] as String? ?? '') {
      'zap' || 'solar' => Icons.bolt_rounded,
      'tree' || 'leaf' => Icons.eco_rounded,
      'bird' || 'spark' => Icons.pets_rounded,
      _ => category == 'ALERT' ? Icons.notifications_active_rounded : Icons.auto_awesome_rounded,
    };
    final createdAt = DateTime.tryParse(item['createdAt'] as String? ?? '')?.toLocal();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: !isRead && item['id'] is String ? () => _markRead(item['id'] as String) : null,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isRead ? const Color(0xFFE2E8F0) : const Color(0xFF86EFAC),
                width: isRead ? 1.0 : 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A0F172A),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isRead ? const Color(0xFFF1F5F9) : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isRead ? const Color(0xFFE2E8F0) : const Color(0xFF86EFAC),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: isRead ? const Color(0xFF64748B) : const Color(0xFF16A34A),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item['title'] as String? ?? 'Eco activity',
                              style: TextStyle(
                                color: const Color(0xFF0F172A),
                                fontWeight: isRead ? FontWeight.w700 : FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF16A34A),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['message'] as String? ?? '',
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              category,
                              style: const TextStyle(
                                color: Color(0xFF475569),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .6,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (createdAt != null)
                            Text(
                              _timeLabel(createdAt),
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      if (item['coinsEarned'] is num || item['co2SavedKg'] is num) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (item['coinsEarned'] is num)
                              _metric(Icons.monetization_on_rounded, '+${(item['coinsEarned'] as num).toInt()} 🪙', const Color(0xFFD97706)),
                            if (item['co2SavedKg'] is num)
                              _metric(Icons.eco_rounded, '${(item['co2SavedKg'] as num).toStringAsFixed(2)} kg CO2e', const Color(0xFF16A34A)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metric(IconData icon, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );

  Widget _statusCard(
    IconData icon,
    String title,
    String message, {
    String? action,
    VoidCallback? onAction,
  }) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A0F172A),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: const Color(0xFF16A34A), size: 28),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: onAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(action),
                  ),
                ],
              ],
            ),
          ),
        ),
      );

  String _timeLabel(DateTime time) {
    final delta = DateTime.now().difference(time);
    if (delta.inMinutes < 1) return 'Just now';
    if (delta.inHours < 1) return '${delta.inMinutes}m ago';
    if (delta.inDays < 1) return '${delta.inHours}h ago';
    return '${time.day}/${time.month}/${time.year}';
  }
}
