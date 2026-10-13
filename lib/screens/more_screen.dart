import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/info_content.dart';
import '../state/outbox_controller.dart';
import 'report_screen.dart';
import 'survey_screen.dart';

const _icons = {
  'rules': Icons.rule,
  'leaf': Icons.eco,
  'contacts': Icons.contact_phone_outlined,
  'project': Icons.info_outline,
};

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final outbox = context.watch<OutboxController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Ещё')),
      body: ListView(children: [
        for (final page in infoPages)
          ListTile(
            leading: Icon(_icons[page.icon]),
            title: Text(page.title),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InfoScreen(page: page))),
          ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.add_location_alt_outlined),
          title: const Text('Сообщить о находке'),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen())),
        ),
        ListTile(
          leading: const Icon(Icons.assignment_outlined),
          title: const Text('Опрос посетителя'),
          subtitle: const Text('Входной и итоговый'),
          onTap: () => showModalBottomSheet(
            context: context,
            builder: (ctx) => SafeArea(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                for (final s in SurveyStage.values)
                  ListTile(
                    title: Text(s.title),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => SurveyScreen(stage: s)));
                    },
                  ),
              ]),
            ),
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.cloud_upload_outlined),
          title: const Text('Мои данные'),
          subtitle: Text(outbox.pendingCount == 0
              ? 'Все данные переданы'
              : 'Ожидают отправки: ${outbox.pendingCount}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DataScreen())),
        ),
      ]),
    );
  }
}

class InfoScreen extends StatelessWidget {
  final InfoPage page;
  const InfoScreen({super.key, required this.page});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(page.title)),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          for (final p in page.paragraphs)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(p, style: Theme.of(context).textTheme.bodyLarge),
            ),
        ]),
      );
}

class DataScreen extends StatelessWidget {
  const DataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final outbox = context.watch<OutboxController>();
    final items = outbox.items.reversed.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Мои данные')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(
          outbox.syncEnabled
              ? 'Сообщения и ответы хранятся на телефоне и автоматически передаются в научный отдел парка, '
                  'как только появляется интернет.'
              : 'Сервер парка пока не подключён. Данные хранятся на телефоне — их можно передать файлом.',
        ),
        if (outbox.lastError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Последняя попытка: ${outbox.lastError}', style: const TextStyle(color: Colors.red)),
          ),
        if (outbox.lastSyncAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Последняя синхронизация: ${_fmt(outbox.lastSyncAt!)}'),
          ),
        const SizedBox(height: 12),
        if (outbox.syncEnabled)
          FilledButton.icon(
            icon: outbox.syncing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.sync),
            label: const Text('Отправить сейчас'),
            onPressed: outbox.syncing || outbox.pendingCount == 0 ? null : outbox.syncNow,
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.ios_share),
          label: const Text('Поделиться файлом с данными'),
          onPressed: items.isEmpty
              ? null
              : () async {
                  final file = await outbox.exportToFile();
                  await SharePlus.instance.share(ShareParams(
                    files: [XFile(file.path, mimeType: 'application/json')],
                    subject: 'Данные наблюдений — Флора Ленских столбов',
                  ));
                },
        ),
        const SizedBox(height: 16),
        if (items.isEmpty) const Text('Пока нет сохранённых данных.'),
        for (final i in items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(i.isSynced ? Icons.cloud_done : Icons.cloud_queue,
                color: i.isSynced ? const Color(0xFF2E7D32) : null),
            title: Text(i.type.label),
            subtitle: Text('${_fmt(i.createdAt)} · ${i.isSynced ? 'отправлено' : 'ожидает отправки'}'),
          ),
      ]),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
