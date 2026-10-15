import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/local_store.dart';
import '../services/achievement_sound.dart';

class Level {
  final String title;
  final int minPoints;
  const Level(this.title, this.minPoints);
}

const levels = [
  Level('Новичок', 0),
  Level('Любитель природы', 50),
  Level('Юный ботаник', 150),
  Level('Натуралист', 300),
  Level('Хранитель флоры', 500),
];

class Achievement {
  final String id;
  final String title;
  final String description;
  final bool unlocked;
  final String? speciesId;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.unlocked,
    this.speciesId,
  });
}

class Points {
  static const identify = 20;
  static const seen = 5;
  static const report = 15;
  static const survey = 20;
  static const quizCorrect = 3;
}

class AchievementNotice {
  final String title;
  final String description;

  const AchievementNotice({required this.title, required this.description});
}

class ProgressController extends ChangeNotifier {
  static const _key = 'progress_v1';
  final LocalStore _store;
  final int totalSpecies;

  final Set<String> identified = {};
  final Map<String, String> seen = {};
  final Set<String> surveyStages = {};
  int reportsCount = 0;
  int quizBest = 0;
  int quizBestTotal = 0;
  int quizAttempts = 0;
  final List<AchievementNotice> notices = [];

  ProgressController(this._store, {required this.totalSpecies}) {
    final j = _store.readJson(_key);
    if (j == null) return;
    identified.addAll(((j['identified'] as List?) ?? const []).cast<String>());
    seen.addAll(((j['seen'] as Map?) ?? const {}).cast<String, String>());
    surveyStages.addAll(((j['surveyStages'] as List?) ?? const []).cast<String>());
    reportsCount = (j['reportsCount'] as int?) ?? 0;
    quizBest = (j['quizBest'] as int?) ?? 0;
    quizBestTotal = (j['quizBestTotal'] as int?) ?? 0;
    quizAttempts = (j['quizAttempts'] as int?) ?? 0;
  }

  Map<String, dynamic> toJson() => {
        'identified': identified.toList(),
        'seen': seen,
        'surveyStages': surveyStages.toList(),
        'reportsCount': reportsCount,
        'quizBest': quizBest,
        'quizBestTotal': quizBestTotal,
        'quizAttempts': quizAttempts,
      };

  Future<void> _save() async {
    notifyListeners();
    await _store.writeJson(_key, toJson());
  }

  int get points =>
      identified.length * Points.identify +
      seen.length * Points.seen +
      reportsCount * Points.report +
      surveyStages.length * Points.survey +
      quizBest * Points.quizCorrect;

  Level get level => levels.lastWhere((l) => points >= l.minPoints);

  Level? get nextLevel {
    final i = levels.indexOf(level);
    return i + 1 < levels.length ? levels[i + 1] : null;
  }

  bool get isFloraExpert => identified.length >= totalSpecies && totalSpecies > 0;

  /// Drops marks for species that are no longer in the catalog.
  Future<void> retainSpecies(Set<String> ids) async {
    final seenBefore = seen.length;
    final identifiedBefore = identified.length;
    seen.removeWhere((id, _) => !ids.contains(id));
    identified.removeWhere((id) => !ids.contains(id));
    if (seen.length != seenBefore || identified.length != identifiedBefore) await _save();
  }

  Future<bool> markIdentified(String speciesId, {String? nameRu}) async {
    final added = identified.add(speciesId);
    if (!added) return false;
    if (isFloraExpert) {
      _announce('Знаток флоры Ленских столбов', 'Определите все $totalSpecies видов');
    } else if (identified.length == 1) {
      _announce('Первый шаг', nameRu == null ? 'Определите первое растение' : 'Определён вид: $nameRu');
    } else {
      _announce(nameRu ?? 'Новый значок', 'Определите вид с помощью определителя');
    }
    await _save();
    return true;
  }

  Future<void> toggleSeen(String speciesId) async {
    final had = seen.containsKey(speciesId);
    if (had) {
      seen.remove(speciesId);
    } else {
      seen[speciesId] = DateTime.now().toIso8601String();
    }
    if (!had && seen.length == 10) _announce('Путешественник', 'Отметьте в чек-листе 10 встреченных видов');
    await _save();
  }

  Future<void> addReport() async {
    final first = reportsCount == 0;
    reportsCount++;
    if (first) _announce('Наблюдатель', 'Отправьте сообщение о находке редкого растения');
    await _save();
  }

  Future<void> completeSurvey(String stage) async {
    final added = surveyStages.add(stage);
    if (added && stage == 'after') _announce('Голос посетителя', 'Пройдите итоговый опрос');
    await _save();
  }

  Future<void> recordQuiz(int correct, int total) async {
    final wasPerfect = quizBestTotal > 0 && quizBest == quizBestTotal;
    quizAttempts++;
    if (correct > quizBest) {
      quizBest = correct;
      quizBestTotal = total;
    }
    final nowPerfect = quizBestTotal > 0 && quizBest == quizBestTotal;
    if (!wasPerfect && nowPerfect) _announce('Эрудит', 'Ответьте верно на все вопросы викторины');
    await _save();
  }

  void _announce(String title, String description) {
    notices.add(AchievementNotice(title: title, description: description));
    unawaited(AchievementSound.play());
  }

  List<Achievement> achievements(Map<String, String> speciesNames) => [
        Achievement(
          id: 'first_id',
          title: 'Первый шаг',
          description: 'Определите первое растение',
          unlocked: identified.isNotEmpty,
        ),
        Achievement(
          id: 'expert',
          title: 'Знаток флоры Ленских столбов',
          description: 'Определите все $totalSpecies видов',
          unlocked: isFloraExpert,
        ),
        Achievement(
          id: 'traveller',
          title: 'Путешественник',
          description: 'Отметьте в чек-листе 10 встреченных видов',
          unlocked: seen.length >= 10,
        ),
        Achievement(
          id: 'observer',
          title: 'Наблюдатель',
          description: 'Отправьте сообщение о находке редкого растения',
          unlocked: reportsCount > 0,
        ),
        Achievement(
          id: 'erudite',
          title: 'Эрудит',
          description: 'Ответьте верно на все вопросы викторины',
          unlocked: quizBestTotal > 0 && quizBest == quizBestTotal,
        ),
        Achievement(
          id: 'voice',
          title: 'Голос посетителя',
          description: 'Пройдите итоговый опрос',
          unlocked: surveyStages.contains('after'),
        ),
        for (final e in speciesNames.entries)
          Achievement(
            id: 'sp_${e.key}',
            title: e.value,
            description: 'Определите вид с помощью определителя',
            unlocked: identified.contains(e.key),
            speciesId: e.key,
          ),
      ];
}
