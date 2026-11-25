import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_app/app/bootstrap.dart';
import 'package:news_app/core/storage/database.dart';
import 'package:news_app/core/storage/prefs.dart';
import 'package:news_app/ui/components/cards.dart';

/// Frames of the feed and of Shorts in a profile build, with the real app and the phone's own storage. It also leaves
/// the news in the cache, which support/scripts/mobile-perf.sh then measures cold starts from.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.benchmarkLive;

  Future<void> until(Finder f) async {
    for (var i = 0; i < 150; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (f.evaluate().isNotEmpty) return;
    }
    fail('never appeared: $f');
  }

  Future<void> rest(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

  testWidgets('frames', (t) async {
    final db = AppDatabase();
    await saveSettings(db, const Settings(), const Settings(onboarded: true));
    await db.close();
    await bootstrap();
    await until(find.byType(CoverCard));
    await until(find.textContaining('kusoma'));
    await rest(3000);

    Future<void> scroll(double dy) async {
      await t.fling(find.byType(CustomScrollView).first, Offset(0, dy), 3000);
      await rest(1200);
    }

    await binding.watchPerformance(() async {
      for (var i = 0; i < 6; i++) {
        await scroll(-500);
      }
      for (var i = 0; i < 6; i++) {
        await scroll(500);
      }
    }, reportKey: 'feed');

    await t.tap(find.text('Video').last);
    await until(find.byType(PageView));
    await rest(1500);
    await binding.watchPerformance(() async {
      for (var i = 0; i < 10; i++) {
        await t.fling(find.byType(PageView).last, const Offset(0, -500), 2000);
        await rest(1200);
      }
    }, reportKey: 'shorts');
  });
}
