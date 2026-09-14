enum GermanArticle { der, die, das }

class Article {
  const Article({
    required this.id,
    required this.article,
    required this.noun,
    required this.category,
    required this.imagePath,
    required this.nounAudioPath,
    required this.answerAudioPath,
  });

  final String id;
  final GermanArticle article;
  final String noun;
  final String category;
  final String imagePath;
  final String nounAudioPath;
  final String answerAudioPath;
}
