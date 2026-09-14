import '../domain/article.dart';

class JsonArticleRecord {
  const JsonArticleRecord({
    required this.id,
    required this.noun,
    required this.article,
    required this.category,
    required this.imagePath,
    required this.nounAudioPath,
    required this.answerAudioPath,
  });

  factory JsonArticleRecord.fromJson(
    Map<String, Object?> json, {
    required int recordIndex,
  }) {
    for (final property in json.keys) {
      if (!_properties.contains(property)) {
        throw _formatException(
          property: property,
          recordIndex: recordIndex,
          id: json['id'] is String ? json['id'] as String : null,
          reason: 'is not supported',
        );
      }
    }

    String requiredString(String property) {
      final value = json[property];
      if (value is! String) {
        throw _formatException(
          property: property,
          recordIndex: recordIndex,
          id: json['id'] is String ? json['id'] as String : null,
          reason: value == null ? 'is missing' : 'must be a string',
        );
      }
      return value;
    }

    return JsonArticleRecord(
      id: requiredString('id'),
      noun: requiredString('noun'),
      article: requiredString('article'),
      category: requiredString('category'),
      imagePath: requiredString('imagePath'),
      nounAudioPath: requiredString('nounAudioPath'),
      answerAudioPath: requiredString('answerAudioPath'),
    );
  }

  static const _properties = <String>{
    'id',
    'noun',
    'article',
    'category',
    'imagePath',
    'nounAudioPath',
    'answerAudioPath',
  };

  final String id;
  final String noun;
  final String article;
  final String category;
  final String imagePath;
  final String nounAudioPath;
  final String answerAudioPath;
}

class ArticleJsonMapper {
  const ArticleJsonMapper();

  Article map(JsonArticleRecord record) {
    final article = switch (record.article) {
      'der' => GermanArticle.der,
      'die' => GermanArticle.die,
      'das' => GermanArticle.das,
      final unsupported => throw FormatException(
        'Article record with id "${record.id}" has unsupported article '
        'value "$unsupported".',
      ),
    };

    return Article(
      id: record.id,
      article: article,
      noun: record.noun,
      category: record.category,
      imagePath: record.imagePath,
      nounAudioPath: record.nounAudioPath,
      answerAudioPath: record.answerAudioPath,
    );
  }
}

FormatException _formatException({
  required String property,
  required int recordIndex,
  required String? id,
  required String reason,
}) {
  final idDescription = id == null ? '' : ' with id "$id"';
  return FormatException(
    'Article record ${recordIndex + 1}$idDescription: property "$property" '
    '$reason.',
  );
}
