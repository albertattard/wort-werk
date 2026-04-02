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
                Noun,Article,Image,Audio,AnswerAudio
                Apfel,der,assets/images/Apfel.png,assets/audio/custom-apfel.mp3,assets/audio/custom-der-apfel.mp3
                """, StandardCharsets.UTF_8);

        ArticleRepository repository = new ArticleRepository(csv.toString());
        List<ArticleEntry> entries = repository.findAll();

        assertThat(entries).hasSize(1);
        assertThat(entries.getFirst().nounAudioPath()).isEqualTo("assets/audio/custom-apfel.mp3");
        assertThat(entries.getFirst().phraseAudioPath()).isEqualTo("assets/audio/custom-der-apfel.mp3");
    }

    @Test
    void shouldFallbackAudioPathsWhenColumnsAreMissing() throws IOException {
        Path csv = tempDir.resolve("articles.csv");
        Files.writeString(csv, """
                Noun,Article,Image
                Banane,die,assets/images/Banane.png
                """, StandardCharsets.UTF_8);

        ArticleRepository repository = new ArticleRepository(csv.toString());
        List<ArticleEntry> entries = repository.findAll();

        assertThat(entries).hasSize(1);
        assertThat(entries.getFirst().nounAudioPath()).isEqualTo("assets/audio/Banane.mp3");
        assertThat(entries.getFirst().phraseAudioPath()).isEqualTo("assets/audio/die Banane.mp3");
    }
}
