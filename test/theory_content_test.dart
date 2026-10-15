import 'package:flutter_test/flutter_test.dart';
import 'package:lenskie_flora/data/theory_content.dart';

void main() {
  test('tourists keep a short base and staff receive the extra lessons', () {
    final tourist = theoryFor('tourist');
    final guide = theoryFor('guide');
    final inspector = theoryFor('inspector');

    expect(tourist.map((lesson) => lesson.id), ['origin', 'red-book', 'key', 'places']);
    expect(guide.length, greaterThan(tourist.length));
    expect(inspector.length, greaterThan(tourist.length));
    expect(guide.map((lesson) => lesson.id), containsAll(tourist.map((lesson) => lesson.id)));
    expect(inspector.map((lesson) => lesson.id), containsAll(tourist.map((lesson) => lesson.id)));
    expect(guide.any((lesson) => lesson.id == 'story'), isTrue);
    expect(inspector.any((lesson) => lesson.id == 'protocol'), isTrue);
    expect(tourist.any((lesson) => lesson.id == 'story' || lesson.id == 'protocol'), isFalse);
  });
}
