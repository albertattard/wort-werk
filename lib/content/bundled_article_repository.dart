import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/article.dart';
import 'article_content_validator.dart';
import 'json_article_record.dart';

class BundledArticleRepository {
  const BundledArticleRepository({
    required AssetBundle assetBundle,
    ArticleJsonMapper mapper = const ArticleJsonMapper(),
  }) : this._(assetBundle, mapper);

  const BundledArticleRepository._(this._assetBundle, this._mapper)
    : _validator = const ArticleContentValidator();

  static const assetPath = 'assets/articles.json';

  final AssetBundle _assetBundle;
  final ArticleJsonMapper _mapper;
  final ArticleContentValidator _validator;

  Future<List<Article>> loadArticles() async {
    final contents = await _assetBundle.loadString(assetPath);
    final decoded = _decode(contents);

    if (decoded is! List<Object?>) {
      throw FormatException(
        'Bundled article asset "$assetPath" must contain a top-level JSON array.',
      );
    }

    final articles = [
      for (var index = 0; index < decoded.length; index++)
        _mapRecord(decoded[index], index),
    ];
    _validator.validate(articles);
    return articles;
  }

  Object? _decode(String contents) {
    try {
      return jsonDecode(contents);
    } on FormatException catch (error) {
      throw FormatException(
        'Could not decode bundled article asset "$assetPath": '
        '${error.message}',
        error.source,
        error.offset,
      );
    }
  }

  Article _mapRecord(Object? value, int recordIndex) {
    if (value is! Map<String, Object?>) {
      throw FormatException(
        'Bundled article asset "$assetPath": article record '
        '${recordIndex + 1} must be a JSON object.',
      );
    }

    return _mapper.map(
      JsonArticleRecord.fromJson(value, recordIndex: recordIndex),
    );
  }
}
