import '../domain/article.dart';

class ArticleContentValidator {
  const ArticleContentValidator();

  static final _slug = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$');

  void validate(List<Article> articles) {
    final ids = <String>{};

    for (var index = 0; index < articles.length; index++) {
      final article = articles[index];
      _validateSlug(article.id, 'id', index, article.id);

      if (!ids.add(article.id)) {
        throw _formatException(
          property: 'id',
          recordIndex: index,
          id: article.id,
          reason: 'duplicates an earlier article record',
        );
      }

      if (article.noun.trim().isEmpty) {
        throw _formatException(
          property: 'noun',
          recordIndex: index,
          id: article.id,
          reason: 'must not be blank',
        );
      }

      _validateSlug(article.category, 'category', index, article.id);
      _validatePath(
        article.imagePath,
        property: 'imagePath',
        prefix: 'assets/images/',
        extension: '.png',
        recordIndex: index,
        id: article.id,
      );
      _validatePath(
        article.nounAudioPath,
        property: 'nounAudioPath',
        prefix: 'assets/audio/',
        extension: '.mp3',
        recordIndex: index,
        id: article.id,
      );
      _validatePath(
        article.answerAudioPath,
        property: 'answerAudioPath',
        prefix: 'assets/audio/',
        extension: '.mp3',
        recordIndex: index,
        id: article.id,
      );
    }
  }

  void _validateSlug(
    String value,
    String property,
    int recordIndex,
    String id,
  ) {
    if (!_slug.hasMatch(value)) {
      throw _formatException(
        property: property,
        recordIndex: recordIndex,
        id: id,
        reason: 'must match the lowercase ASCII slug grammar',
      );
    }
  }

  void _validatePath(
    String value, {
    required String property,
    required String prefix,
    required String extension,
    required int recordIndex,
    required String id,
  }) {
    final hasRequiredPrefix = value.startsWith(prefix);
    final relativePath = hasRequiredPrefix
        ? value.substring(prefix.length)
        : '';
    final containsTraversal = value.split('/').contains('..');

    if (!hasRequiredPrefix ||
        relativePath.isEmpty ||
        !value.endsWith(extension) ||
        containsTraversal) {
      throw _formatException(
        property: property,
        recordIndex: recordIndex,
        id: id,
        reason:
            'must be a relative $prefix path ending in $extension without path traversal',
      );
    }
  }
}

FormatException _formatException({
  required String property,
  required int recordIndex,
  required String id,
  required String reason,
}) => FormatException(
  'Article record ${recordIndex + 1} with id "$id": property "$property" '
  '$reason.',
);
