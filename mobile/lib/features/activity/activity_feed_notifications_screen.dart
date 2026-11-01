import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/auth_config.dart';
import '../../services/auth_service.dart';

/// Authenticated activity and notification ledger. It intentionally displays
/// only events returned by the API; actions are never credited locally.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1A12),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  _roundButton(Icons.arrow_back_rounded, widget.onBackToSanctuary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('FIELD JOURNAL', style: TextStyle(color: Color(0xFF86EFAC), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.7)),
                        const SizedBox(height: 2),
                        Text('Activity${_unreadCount > 0 ? '  ·  $_unreadCount new' : ''}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  _roundButton(Icons.refresh_rounded, _loadFeed),
                  if (_unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    _roundButton(Icons.done_all_rounded, _markAllRead),
                  ],
                ],
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
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
                    backgroundColor: const Color(0xFF12291B),
                    selectedColor: const Color(0xFF52B96A),
                    labelStyle: TextStyle(color: selected ? const Color(0xFF0B1A12) : Colors.white70, fontWeight: FontWeight.w800, fontSize: 12),
                    side: BorderSide(color: selected ? const Color(0xFF9DE3A7) : Colors.white12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  );
                },
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF86EFAC)))
                  : _error != null
                      ? _statusCard(Icons.cloud_off_rounded, 'Could not sync your journal', _error!, action: 'Retry', onAction: _loadFeed)
                      : _items.isEmpty
                          ? _statusCard(Icons.auto_awesome_rounded, 'Your story starts here', 'Real device logs, completed habits and sanctuary events will appear here as you play.')
                          : RefreshIndicator(
                              color: const Color(0xFF86EFAC),
                              backgroundColor: const Color(0xFF153522),
                              onRefresh: _loadFeed,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                                itemCount: _items.length,
                                itemBuilder: (context, index) => _activityCard(_items[index]),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundButton(IconData icon, VoidCallback onTap) => Material(
        color: const Color(0xFF173923),
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white12), boxShadow: const [BoxShadow(color: Color(0xFF061009), offset: Offset(0, 3))]),
            child: Icon(icon, color: const Color(0xFFE7F7E9), size: 20),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: const Color(0xFF12291B),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: !isRead && item['id'] is String ? () => _markRead(item['id'] as String) : null,
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: isRead ? Colors.white10 : const Color(0xFF52B96A).withValues(alpha: .7)),
              boxShadow: const [BoxShadow(color: Color(0xFF061009), offset: Offset(0, 4)), BoxShadow(color: Color(0x4422C55E), blurRadius: 18, offset: Offset(0, 8))],
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF287447), Color(0xFF163923)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white24), boxShadow: const [BoxShadow(color: Color(0xFF07140B), offset: Offset(0, 3))]), child: Icon(icon, color: const Color(0xFFB8F5A4), size: 24)),
              const SizedBox(width: 13),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Expanded(child: Text(item['title'] as String? ?? 'Eco activity', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14))), if (!isRead) Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF86EFAC), shape: BoxShape.circle))]),
                const SizedBox(height: 5),
                Text(item['message'] as String? ?? '', style: const TextStyle(color: Color(0xFFC6D8CA), fontSize: 12, height: 1.4)),
                const SizedBox(height: 9),
                Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF214A31), borderRadius: BorderRadius.circular(8)), child: Text(category, style: const TextStyle(color: Color(0xFF9DE3A7), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: .7))), const Spacer(), if (createdAt != null) Text(_timeLabel(createdAt), style: const TextStyle(color: Colors.white54, fontSize: 10))]),
                if (item['coinsEarned'] is num || item['co2SavedKg'] is num) ...[
                  const SizedBox(height: 8),
                  Wrap(spacing: 10, children: [if (item['coinsEarned'] is num) _metric(Icons.monetization_on_rounded, '+${(item['coinsEarned'] as num).toInt()}'), if (item['co2SavedKg'] is num) _metric(Icons.co2_rounded, '${(item['co2SavedKg'] as num).toStringAsFixed(2)} kg')]),
                ],
              ])),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _metric(IconData icon, String label) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 13, color: const Color(0xFFF4CA68)), const SizedBox(width: 3), Text(label, style: const TextStyle(color: Color(0xFFF4CA68), fontWeight: FontWeight.w800, fontSize: 10))]);

  Widget _statusCard(IconData icon, String title, String message, {String? action, VoidCallback? onAction}) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: const Color(0xFF12291B), borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white12), boxShadow: const [BoxShadow(color: Color(0xFF061009), offset: Offset(0, 6)), BoxShadow(color: Color(0x3322C55E), blurRadius: 24, offset: Offset(0, 8))]),
            child: Column(mainAxisSize: MainAxisSize.min, children: [Container(width: 62, height: 62, decoration: BoxDecoration(color: const Color(0xFF214A31), borderRadius: BorderRadius.circular(20)), child: Icon(icon, color: const Color(0xFF9DE3A7), size: 30)), const SizedBox(height: 16), Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(height: 8), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFC6D8CA), height: 1.45)), if (action != null) ...[const SizedBox(height: 18), FilledButton(onPressed: onAction, child: Text(action))]]),
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
