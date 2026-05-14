import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  final int kullaniciId;

  const NotificationsScreen({
    super.key,
    required this.kullaniciId,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const Color kPrimary = Color(0xFF2563EB);
  static const Color kBackground = Color(0xFFF8F9FC);
  static const Color kTextDark = Color(0xFF1E293B);
  static const Color kTextGrey = Color(0xFF64748B);
  static const Color kDivider = Color(0xFFE2E8F0);

  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      final data = await NotificationService.getNotificationsByUserId(
        widget.kullaniciId,
      );

      if (!mounted) return;

      setState(() {
        _notifications = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bildirimler yüklenemedi: $e')),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    await NotificationService.markAllAsRead(widget.kullaniciId);
    await _loadNotifications();
  }

  Future<void> _markAsRead(Map<String, dynamic> item) async {
    final id = int.tryParse(item['bildirimId'].toString());

    if (id == null) return;

    await NotificationService.markAsRead(id);
    await _loadNotifications();
  }

  String _formatDate(String raw) {
    final d = DateTime.tryParse(raw);

    if (d == null) return '-';

    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) {
      return n['okunduMu'] == false;
    }).length;

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: kTextDark,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bildirimler',
          style: TextStyle(
            color: kTextDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Tümünü okundu yap',
                style: TextStyle(
                  color: kPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: kPrimary),
      )
          : RefreshIndicator(
        onRefresh: _loadNotifications,
        color: kPrimary,
        child: _notifications.isEmpty
            ? ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            Icon(
              Icons.notifications_none_outlined,
              size: 56,
              color: Color(0xFF94A3B8),
            ),
            SizedBox(height: 12),
            Center(
              child: Text(
                'Henüz bildiriminiz yok.',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _notifications.length,
          itemBuilder: (context, index) {
            final item = _notifications[index];
            final isUnread = item['okunduMu'] == false;

            return _notificationCard(item, isUnread);
          },
        ),
      ),
    );
  }

  Widget _notificationCard(
      Map<String, dynamic> item,
      bool isUnread,
      ) {
    return InkWell(
      onTap: () => _markAsRead(item),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread ? kPrimary.withValues(alpha:0.25) : kDivider,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor:
              isUnread ? kPrimary.withValues(alpha:0.12) : const Color(0xFFF1F5F9),
              child: Icon(
                Icons.notifications_outlined,
                color: isUnread ? kPrimary : kTextGrey,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['baslik']?.toString() ?? 'Bildirim',
                    style: TextStyle(
                      color: kTextDark,
                      fontSize: 14,
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['mesaj']?.toString() ?? '',
                    style: const TextStyle(
                      color: kTextGrey,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(item['olusturmaTarihi']?.toString() ?? ''),
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}