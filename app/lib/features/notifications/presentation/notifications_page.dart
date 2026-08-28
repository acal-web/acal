import 'package:acalapp/core/config/layout_config.dart';
import 'package:acalapp/features/notifications/data/notification_service.dart';
import 'package:acalapp/features/notifications/domain/app_notification.dart';
import 'package:acalapp/features/notifications/presentation/send_notification_page.dart';
import 'package:acalapp/shared/widgets/page_header.dart';
import 'package:acalapp/shared/widgets/table/add_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, this.notificationService});

  final NotificationService? notificationService;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationService _service;
  final _scrollController = ScrollController();
  final List<AppNotification> _all = [];

  int _currentPage = 0;
  final int _pageSize = 20;
  bool _isLoading = false;
  bool _hasMorePages = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = widget.notificationService ?? NotificationService();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFirstPage() async {
    _all.clear();
    _currentPage = 0;
    _hasMorePages = true;
    _errorMessage = null;
    await _loadNextPage();
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_hasMorePages) return;

    if (mounted) setState(() => _isLoading = true);

    try {
      final result = await _service.findAll(page: _currentPage, size: _pageSize);
      if (mounted) {
        setState(() {
          _all.addAll(result.data);
          _hasMorePages = result.pagination.nextPage != null;
          _currentPage++;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro ao carregar notificações';
        });
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 500) {
      _loadNextPage();
    }
  }

  Future<void> _openSendPage() async {
    final sent = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => SendNotificationPage()),
    );
    if (sent == true) await _loadFirstPage();
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < LayoutConfig.narrowBreakpoint;

    return Scaffold(
      body: Padding(
        padding: LayoutConfig.pagePadding(narrow),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              subtitle: 'Histórico de notificações enviadas aos sócios.',
              action: AddButton(label: 'Nova notificação', onPress: _openSendPage),
            ),
            const Divider(),
            Expanded(
              child: _errorMessage != null
                  ? Center(child: Text(_errorMessage!))
                  : _all.isEmpty && !_isLoading
                      ? const Center(child: Text('Nenhuma notificação enviada ainda.'))
                      : ListView.separated(
                          controller: _scrollController,
                          itemCount: _all.length + (_isLoading ? 1 : 0),
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            if (index == _all.length) {
                              return const Center(
                                child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),
                              );
                            }
                            return _NotificationTile(notification: _all[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final scopeParts = [
      if (notification.addressName != null) notification.addressName!,
      if (notification.categoryName != null) notification.categoryName!,
    ];
    final scope = scopeParts.isEmpty ? 'Todos os sócios' : scopeParts.join(' · ');
    final createdAt = notification.createdAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(notification.createdAt!) : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notifications_outlined, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(notification.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  '$scope · ${notification.recipientCount} destinatários'
                  '${notification.sentByName != null ? ' · ${notification.sentByName}' : ''}'
                  '${createdAt.isNotEmpty ? ' · $createdAt' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
