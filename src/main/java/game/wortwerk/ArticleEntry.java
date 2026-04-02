package game.wortwerk;

public record ArticleEntry(String noun, String article, String imagePath) {

    public String articlePhrase() {
        return article + " " + noun;
    }
}
