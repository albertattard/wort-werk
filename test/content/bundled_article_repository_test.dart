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

Map<String, String> _validRecord() => {
  'id': 'apfel',
  'noun': 'Apfel',
  'article': 'der',
  'category': 'food',
  'imagePath': 'assets/images/420/food/Apfel.png',
  'nounAudioPath': 'assets/audio/apfel.mp3',
  'answerAudioPath': 'assets/audio/der_apfel.mp3',
};
