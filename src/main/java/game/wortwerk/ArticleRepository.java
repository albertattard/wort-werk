package game.wortwerk;

import java.io.BufferedReader;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Repository;

@Repository
public class ArticleRepository {

    private final List<ArticleEntry> entries;

    public ArticleRepository(@Value("${wortwerk.articles-csv:assets/articles.csv}") String csvPath) {
        this.entries = loadCsv(Path.of(csvPath));
    }

    public List<ArticleEntry> findAll() {
        return entries;
    }

    private List<ArticleEntry> loadCsv(Path csvPath) {
        if (!Files.exists(csvPath)) {
            throw new IllegalStateException("CSV file does not exist: " + csvPath.toAbsolutePath());
        }

        List<ArticleEntry> loaded = new ArrayList<>();

        try (BufferedReader reader = Files.newBufferedReader(csvPath, StandardCharsets.UTF_8)) {
            String line = reader.readLine(); // header
            if (line == null) {
                throw new IllegalStateException("CSV file is empty: " + csvPath.toAbsolutePath());
            }
            HeaderColumns header = parseHeader(line);

            while ((line = reader.readLine()) != null) {
                String trimmed = line.trim();
                if (trimmed.isEmpty()) {
                    continue;
                }

                String[] parts = trimmed.split(",", -1);
                if (parts.length < 3) {
                    throw new IllegalStateException("Invalid CSV row: " + line);
                }

                String noun = get(parts, header.nounIndex).trim();
                String article = get(parts, header.articleIndex).trim();
                String imagePath = get(parts, header.imageIndex).trim();
                String nounAudioPath = header.audioIndex >= 0 ? get(parts, header.audioIndex).trim() : "";
                String phraseAudioPath = header.answerAudioIndex >= 0 ? get(parts, header.answerAudioIndex).trim() : "";

                if (noun.isEmpty() || article.isEmpty() || imagePath.isEmpty()) {
                    throw new IllegalStateException("CSV row contains empty fields: " + line);
                }

                if (!isValidArticle(article)) {
                    throw new IllegalStateException("Invalid article '" + article + "' in row: " + line);
                }

                if (nounAudioPath.isEmpty()) {
                    nounAudioPath = ArticleEntry.defaultNounAudioPath(noun);
                }
                if (phraseAudioPath.isEmpty()) {
                    phraseAudioPath = ArticleEntry.defaultPhraseAudioPath(article, noun);
                }

                loaded.add(new ArticleEntry(noun, article, imagePath, nounAudioPath, phraseAudioPath));
            }
        } catch (IOException e) {
            throw new IllegalStateException("Failed to read CSV file: " + csvPath.toAbsolutePath(), e);
        }

        if (loaded.isEmpty()) {
            throw new IllegalStateException("CSV did not contain any article entries: " + csvPath.toAbsolutePath());
        }

        return Collections.unmodifiableList(loaded);
    }

    private boolean isValidArticle(String article) {
        return "der".equals(article) || "die".equals(article) || "das".equals(article);
    }

    private HeaderColumns parseHeader(String line) {
        String[] parts = line.split(",", -1);
        Map<String, Integer> index = new HashMap<>();
        for (int i = 0; i < parts.length; i++) {
            index.put(parts[i].trim(), i);
        }

        int nounIndex = requiredColumn(index, "Noun");
        int articleIndex = requiredColumn(index, "Article");
        int imageIndex = requiredColumn(index, "Image");

        int audioIndex = optionalColumn(index, "Audio", "NounAudio");
        int answerAudioIndex = optionalColumn(index, "AnswerAudio", "PhraseAudio");

        return new HeaderColumns(nounIndex, articleIndex, imageIndex, audioIndex, answerAudioIndex);
    }

    private int requiredColumn(Map<String, Integer> columns, String name) {
        Integer index = columns.get(name);
        if (index == null) {
            throw new IllegalStateException("CSV header is missing required column: " + name);
        }
        return index;
    }

    private int optionalColumn(Map<String, Integer> columns, String preferred, String legacy) {
        Integer index = columns.get(preferred);
        if (index != null) {
            return index;
        }
        Integer legacyIndex = columns.get(legacy);
        return legacyIndex == null ? -1 : legacyIndex;
    }

    private String get(String[] parts, int index) {
        if (index < 0 || index >= parts.length) {
            return "";
        }
        return parts[index];
    }

    private record HeaderColumns(int nounIndex,
                                 int articleIndex,
                                 int imageIndex,
                                 int audioIndex,
                                 int answerAudioIndex) {}
}
