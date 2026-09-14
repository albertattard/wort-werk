import 'package:flutter_test/flutter_test.dart';
import 'package:wort_werk/content/json_article_record.dart';
import 'package:wort_werk/domain/article.dart';

void main() {
  const mapper = ArticleJsonMapper();

  test('maps a valid der record into an Article', () {
    final article = mapper.map(_record(article: 'der'));

    expect(article.article, GermanArticle.der);
    expect(article.id, 'apfel');
    expect(article.noun, 'Apfel');
    expect(article.category, 'food');
    expect(article.imagePath, 'assets/images/420/food/Apfel.png');
    expect(article.nounAudioPath, 'assets/audio/apfel.mp3');
    expect(article.answerAudioPath, 'assets/audio/der_apfel.mp3');
  });

  test('maps a valid die record into an Article', () {
    expect(mapper.map(_record(article: 'die')).article, GermanArticle.die);
  });

  test('maps a valid das record into an Article', () {
    expect(mapper.map(_record(article: 'das')).article, GermanArticle.das);
  });

  test('rejects an unsupported article value', () {
    expect(
      () => mapper.map(_record(article: 'den')),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('id "apfel" has unsupported article value "den"'),
        ),
      ),
    );
  });

  test('rejects a missing required property with record and ID context', () {
    final json = _json()..remove('noun');

    expect(
      () => JsonArticleRecord.fromJson(json, recordIndex: 2),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          allOf(contains('Article record 3 with id "apfel"'), contains('property "noun" is missing')),
        ),
      ),
    );
  });

  test('rejects a non-string required property with record and ID context', () {
    final json = _json()..['category'] = 42;

    expect(
      () => JsonArticleRecord.fromJson(json, recordIndex: 0),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          allOf(contains('Article record 1 with id "apfel"'), contains('property "category" must be a string')),
        ),
      ),
    );
  });

  test('rejects an unknown property', () {
    final json = _json()..['unexpected'] = 'value';

    expect(
      () => JsonArticleRecord.fromJson(json, recordIndex: 0),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('property "unexpected" is not supported'),
        ),
      ),
    );
  });
}

JsonArticleRecord _record({required String article}) => JsonArticleRecord.fromJson(
  _json()..['article'] = article,
  recordIndex: 0,
);

Map<String, Object?> _json() => {
  'id': 'apfel',
  'noun': 'Apfel',
  'article': 'der',
  'category': 'food',
  'imagePath': 'assets/images/420/food/Apfel.png',
  'nounAudioPath': 'assets/audio/apfel.mp3',
  'answerAudioPath': 'assets/audio/der_apfel.mp3',
};
