import 'dart:async';

import 'package:acalapp/core/config/layout_config.dart';
import 'package:acalapp/features/addresses/data/address_service.dart';
import 'package:acalapp/features/categories/data/category_service.dart';
import 'package:acalapp/features/notifications/data/notification_service.dart';
import 'package:acalapp/features/notifications/widget/modal/confirm_send_notification.dart';
import 'package:acalapp/features/notifications/widget/notification_recipients_filter.dart';
import 'package:acalapp/shared/widgets/page_header.dart';
import 'package:acalapp/shared/widgets/toast/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

const _titleMaxLength = 65;
const _bodyMaxLength = 1000;

class SendNotificationPage extends StatefulWidget {
  const SendNotificationPage({super.key, this.notificationService, this.addressService, this.categoryService});

  final NotificationService? notificationService;
  final AddressService? addressService;
  final CategoryService? categoryService;

  @override
  State<SendNotificationPage> createState() => _SendNotificationPageState();
}

class _SendNotificationPageState extends State<SendNotificationPage> {
  late final NotificationService _service;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  RecipientFilters _filters = (addressId: null, categoryId: null, status: 'active');
  int? _recipientCount;
  bool _loadingCount = false;
  bool _sending = false;
  Timer? _countDebounce;

  @override
  void initState() {
    super.initState();
    _service = widget.notificationService ?? NotificationService();
    _refreshCount();
  }

  @override
  void dispose() {
    _countDebounce?.cancel();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _onFiltersChanged(RecipientFilters filters) {
    _filters = filters;
    _countDebounce?.cancel();
    _countDebounce = Timer(const Duration(milliseconds: 400), _refreshCount);
  }

  Future<void> _refreshCount() async {
    setState(() => _loadingCount = true);
    try {
      final count = await _service.recipientsCount(
        addressId: _filters.addressId,
        categoryId: _filters.categoryId,
        status: _filters.status,
      );
      if (mounted) setState(() => _recipientCount = count);
    } catch (_) {
      if (mounted) setState(() => _recipientCount = null);
    } finally {
      if (mounted) setState(() => _loadingCount = false);
    }
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final count = _recipientCount ?? 0;
    if (count == 0) {
      AppToast.warning(context, 'Nenhum sócio corresponde aos filtros selecionados.');
      return;
    }

    final confirmed = await showConfirmSendNotificationDialog(context: context, recipientCount: count);
    if (!confirmed) return;

    setState(() => _sending = true);
    try {
      await _service.send(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        addressId: _filters.addressId,
        categoryId: _filters.categoryId,
        status: _filters.status,
      );
      if (mounted) {
        AppToast.success(context, 'Notificação enviada.');
        context.pop(true);
      }
    } catch (_) {
      if (mounted) AppToast.error(context, 'Erro ao enviar a notificação.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Widget _counter(BuildContext context, int current, int? max, bool focused) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text('$current/$max', style: Theme.of(context).textTheme.bodySmall),
      );

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < LayoutConfig.narrowBreakpoint;

    return Scaffold(
      body: Padding(
        padding: LayoutConfig.pagePadding(narrow),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(subtitle: 'Envie um aviso por push notification para os sócios.'),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FTextFormField(
                          control: FTextFieldControl.managed(controller: _titleController),
                          maxLength: _titleMaxLength,
                          counterBuilder: _counter,
                          label: const Text('Título'),
                          hint: 'Ex.: Manutenção programada',
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                        ),
                        const SizedBox(height: 16),
                        FTextFormField.multiline(
                          control: FTextFieldControl.managed(controller: _bodyController),
                          maxLength: _bodyMaxLength,
                          maxLines: 6,
                          counterBuilder: _counter,
                          label: const Text('Mensagem'),
                          hint: 'Digite o texto da notificação...',
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                        ),
                        const SizedBox(height: 24),
                        Text('Destinatários', style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        NotificationRecipientsFilter(
                          onChanged: _onFiltersChanged,
                          addressService: widget.addressService,
                          categoryService: widget.categoryService,
                        ),
                        const SizedBox(height: 12),
                        _RecipientCountBanner(loading: _loadingCount, count: _recipientCount),
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FButton(
                            onPress: _sending ? null : _send,
                            child: Text(_sending ? 'Enviando...' : 'Enviar notificação'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipientCountBanner extends StatelessWidget {
  const _RecipientCountBanner({required this.loading, required this.count});

  final bool loading;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = loading
        ? 'Calculando destinatários...'
        : count == null
            ? 'Não foi possível calcular os destinatários.'
            : count == 1
                ? '1 sócio receberá esta notificação.'
                : '$count sócios receberão esta notificação.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.groups_outlined, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
