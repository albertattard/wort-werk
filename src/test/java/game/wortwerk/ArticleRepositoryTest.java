package game.wortwerk;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class ArticleRepositoryTest {

    @TempDir
    Path tempDir;

    @Test
    void shouldReadAudioPathsFromCsv() throws IOException {
        Path csv = tempDir.resolve("articles.csv");
        Files.writeString(csv, """
                Id,Noun,Article,Category,Image,Audio,AnswerAudio
                apfel,Apfel,der,food,assets/images/420/food/apfel.png,assets/audio/custom-apfel.mp3,assets/audio/custom-der-apfel.mp3
                """, StandardCharsets.UTF_8);

        ArticleRepository repository = new ArticleRepository(csv.toString());
        List<ArticleEntry> entries = repository.findAll();

        assertThat(entries).hasSize(1);
        assertThat(entries.getFirst().id()).isEqualTo("apfel");
        assertThat(entries.getFirst().nounAudioPath()).isEqualTo("assets/audio/custom-apfel.mp3");
        assertThat(entries.getFirst().phraseAudioPath()).isEqualTo("assets/audio/custom-der-apfel.mp3");
    }

    @Test
    void shouldFallbackAudioPathsWhenColumnsAreMissing() throws IOException {
        Path csv = tempDir.resolve("articles.csv");
        Files.writeString(csv, """
                Id,Noun,Article,Category,Image
                banane,Banane,die,food,assets/images/420/food/banane.png
                """, StandardCharsets.UTF_8);

        ArticleRepository repository = new ArticleRepository(csv.toString());
        List<ArticleEntry> entries = repository.findAll();

        assertThat(entries).hasSize(1);
        assertThat(entries.getFirst().nounAudioPath()).isEqualTo("assets/audio/Banane.mp3");
        assertThat(entries.getFirst().phraseAudioPath()).isEqualTo("assets/audio/die Banane.mp3");
    }

    @Test
    void shouldUseAsciiSafeAssetPathsInProductionCsv() {
        ArticleRepository repository = new ArticleRepository("assets/articles.csv");
        List<ArticleEntry> entries = repository.findAll();

        assertThat(entries).isNotEmpty();
        assertThat(entries)
                .allSatisfy(entry -> {
                    assertThat(entry.id()).matches("\\A[a-z0-9-]+\\z");
                    assertThat(entry.imagePath()).matches("\\A\\p{ASCII}+\\z");
                    assertThat(entry.nounAudioPath()).matches("\\A\\p{ASCII}+\\z");
                    assertThat(entry.phraseAudioPath()).matches("\\A\\p{ASCII}+\\z");
                });
    }

    @Test
    void shouldUseCsvAsTheAssetCatalogSourceOfTruth() {
        ArticleRepository repository = new ArticleRepository("assets/articles.csv");
        List<ArticleEntry> entries = repository.findAll();

        assertThat(entries).isNotEmpty();
        assertThat(entries)
                .allSatisfy(entry -> {
                    assertThat(entry.id()).isNotBlank();
                    assertThat(entry.noun()).isNotBlank();
                    assertThat(entry.article()).isIn("der", "die", "das");
                    assertThat(entry.imagePath()).startsWith("assets/images/420/").containsPattern("assets/images/420/[a-z0-9-]+/.+\\.png");
                });
        assertThat(entries)
                .extracting(ArticleEntry::id)
                .doesNotHaveDuplicates();
        assertThat(entries)
                .extracting(ArticleEntry::imagePath)
                .doesNotHaveDuplicates();
    }
}
