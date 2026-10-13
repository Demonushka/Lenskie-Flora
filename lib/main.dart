import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/content_repository.dart';
import 'data/local_store.dart';
import 'services/sync_service.dart';
import 'state/outbox_controller.dart';
import 'state/progress_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final content = await ContentRepository.load();
  final store = await LocalStore.open();
  final progress = ProgressController(store, totalSpecies: content.species.length);
  final outbox = OutboxController(store, SyncService())..startAutoSync();

  runApp(MultiProvider(
    providers: [
      Provider.value(value: content),
      ChangeNotifierProvider.value(value: progress),
      ChangeNotifierProvider.value(value: outbox),
    ],
    child: const LenskieFloraApp(),
  ));
}
