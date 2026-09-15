import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wort_werk/content/bundled_article_repository.dart';
import 'package:wort_werk/domain/article.dart';

void main() {
  test('loads typed articles from the declared bundled asset', () async {
    final bundle = _StringAssetBundle(jsonEncode([_validRecord()]));
    final repository = BundledArticleRepository(assetBundle: bundle);

    final articles = await repository.loadArticles();

    expect(bundle.requestedKeys, [BundledArticleRepository.assetPath]);
    expect(articles, hasLength(1));
    expect(articles.single.id, 'apfel');
    expect(articles.single.article, GermanArticle.der);
  });

  test('rejects invalid JSON with the bundled asset path', () async {
    final repository = BundledArticleRepository(
      assetBundle: _StringAssetBundle('{not json'),
    );

    await expectLater(
      repository.loadArticles(),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          allOf(
            contains(BundledArticleRepository.assetPath),
            contains('Could not decode'),
          ),
        ),
      ),
    );
  });

  test('rejects a non-array top-level JSON value', () async {
    final repository = BundledArticleRepository(
      assetBundle: _StringAssetBundle(jsonEncode(_validRecord())),
    );

    await expectLater(
      repository.loadArticles(),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          allOf(
            contains(BundledArticleRepository.assetPath),
            contains('top-level JSON array'),
          ),
        ),
      ),
    );
  });

  test(
    'rejects a non-object array item without returning partial data',
    () async {
      final repository = BundledArticleRepository(
        assetBundle: _StringAssetBundle(
          jsonEncode([_validRecord(), 'not an object']),
        ),
      );

      await expectLater(
        repository.loadArticles(),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('article record 2 must be a JSON object'),
          ),
        ),
      );
    },
  );

  test('loads a valid collection through the validation path', () async {
    final repository = BundledArticleRepository(
      assetBundle: _StringAssetBundle(
        jsonEncode([_validRecord(), _validRecord(id: 'birne', noun: 'Birne')]),
      ),
    );

    final articles = await repository.loadArticles();

    expect(articles.map((article) => article.id), ['apfel', 'birne']);
  });

  test('rejects a blank ID', () async {
    await _expectInvalidCollection(_validRecord(id: ''), property: 'id');
  });

  test('rejects a malformed ID without normalizing it', () async {
    await _expectInvalidCollection(
      _validRecord(id: 'Apfel Pie'),
      property: 'id',
    );
  });

  test('rejects a duplicate ID', () async {
    final repository = BundledArticleRepository(
      assetBundle: _StringAssetBundle(
        jsonEncode([_validRecord(), _validRecord(noun: 'Anderer Apfel')]),
      ),
    );

    await expectLater(
      repository.loadArticles(),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          allOf(contains('Article record 2'), contains('duplicates')),
        ),
      ),
    );
  });

  test(
    'rejects a blank noun while preserving authored non-blank text',
    () async {
      await _expectInvalidCollection(
        _validRecord(noun: '  \t'),
        property: 'noun',
      );
    },
  );

  test('rejects a malformed category without an allow-list', () async {
    await _expectInvalidCollection(
      _validRecord(category: 'Fruit & vegetables'),
      property: 'category',
    );
  });

  test('rejects an invalid image path', () async {
    await _expectInvalidCollection(
      _validRecord(imagePath: 'assets/audio/apfel.mp3'),
      property: 'imagePath',
    );
  });

  test('rejects noun-audio path traversal', () async {
    await _expectInvalidCollection(
      _validRecord(nounAudioPath: 'assets/audio/../images/apfel.mp3'),
      property: 'nounAudioPath',
    );
  });

  test('rejects an absolute media path', () async {
    await _expectInvalidCollection(
      _validRecord(nounAudioPath: '/assets/audio/apfel.mp3'),
      property: 'nounAudioPath',
    );
  });

  test('rejects an answer-audio path with the wrong extension', () async {
    await _expectInvalidCollection(
      _validRecord(answerAudioPath: 'assets/audio/der_apfel.wav'),
      property: 'answerAudioPath',
    );
  });
}

Future<void> _expectInvalidCollection(
  Map<String, String> record, {
  required String property,
}) async {
  final repository = BundledArticleRepository(
    assetBundle: _StringAssetBundle(jsonEncode([record])),
  );

  await expectLater(
    repository.loadArticles(),
    throwsA(
      isA<FormatException>().having(
        (error) => error.message,
        'message',
        allOf(contains('Article record 1'), contains('property "$property"')),
      ),
    ),
  );
}

class _StringAssetBundle extends CachingAssetBundle {
  _StringAssetBundle(this._contents);

  final String _contents;
  final requestedKeys = <String>[];

  @override
  Future<ByteData> load(String key) async {
    requestedKeys.add(key);
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(_contents)));
  }
}

Map<String, String> _validRecord({
  String id = 'apfel',
  String noun = 'Apfel',
  String category = 'food',
  String imagePath = 'assets/images/420/food/Apfel.png',
  String nounAudioPath = 'assets/audio/apfel.mp3',
  String answerAudioPath = 'assets/audio/der_apfel.mp3',
}) => {
  'id': id,
  'noun': noun,
  'article': 'der',
  'category': category,
  'imagePath': imagePath,
  'nounAudioPath': nounAudioPath,
  'answerAudioPath': answerAudioPath,
};
