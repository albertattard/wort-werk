package game.wortwerk;

import java.io.BufferedReader;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

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

            while ((line = reader.readLine()) != null) {
                String trimmed = line.trim();
                if (trimmed.isEmpty()) {
                    continue;
                }

                String[] parts = trimmed.split(",", 3);
                if (parts.length != 3) {
                    throw new IllegalStateException("Invalid CSV row: " + line);
                }

                String noun = parts[0].trim();
                String article = parts[1].trim();
                String imagePath = parts[2].trim();

                if (noun.isEmpty() || article.isEmpty() || imagePath.isEmpty()) {
                    throw new IllegalStateException("CSV row contains empty fields: " + line);
                }

                if (!isValidArticle(article)) {
                    throw new IllegalStateException("Invalid article '" + article + "' in row: " + line);
                }

                loaded.add(new ArticleEntry(noun, article, imagePath));
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
}
