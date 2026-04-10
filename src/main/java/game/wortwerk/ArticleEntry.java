package game.wortwerk;

public record ArticleEntry(String id,
                           String noun,
                           String article,
                           String imagePath,
                           String nounAudioPath,
                           String phraseAudioPath) {

    public ArticleEntry(String id, String noun, String article, String imagePath) {
        this(id, noun, article, imagePath, defaultNounAudioPath(noun), defaultPhraseAudioPath(article, noun));
    }

    public String articlePhrase() {
        return article + " " + noun;
    }

    public static String defaultNounAudioPath(String noun) {
        return "assets/audio/" + noun + ".mp3";
    }

    public static String defaultPhraseAudioPath(String article, String noun) {
        return "assets/audio/" + article + " " + noun + ".mp3";
    }
}
