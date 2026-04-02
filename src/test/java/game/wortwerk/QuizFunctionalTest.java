package game.wortwerk;

import com.microsoft.playwright.Browser;
import com.microsoft.playwright.BrowserType;
import com.microsoft.playwright.Page;
import com.microsoft.playwright.Playwright;
import com.microsoft.playwright.options.LoadState;
import org.junit.jupiter.api.*;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import java.util.stream.Collectors;

import static org.assertj.core.api.Assertions.assertThat;

@Tag("e2e")
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class QuizFunctionalTest {

    @LocalServerPort
    private int port;

    private Playwright playwright;
    private Browser browser;
    private Map<String, String> articleByNoun;

    @BeforeAll
    void setUpBrowser() {
        playwright = Playwright.create();
        browser = playwright.chromium().launch(new BrowserType.LaunchOptions().setHeadless(true));
        articleByNoun = loadArticleByNoun(Path.of("assets/articles.csv"));
    }

    @AfterAll
    void tearDownBrowser() {
        if (browser != null) {
            browser.close();
        }
        if (playwright != null) {
            playwright.close();
        }
    }

    @Test
    void shouldLoadQuizAndShowArticleChoices() {
        try (Page page = browser.newPage()) {
            page.navigate(baseUrl());

            assertThat(page.getByTestId("question-image").isVisible()).isTrue();
            assertThat(page.getByTestId("question-noun").isVisible()).isTrue();
            assertThat(page.getByTestId("noun-replay").isVisible()).isTrue();
            assertThat(page.getByTestId("answer-der").isVisible()).isTrue();
            assertThat(page.getByTestId("answer-die").isVisible()).isTrue();
            assertThat(page.getByTestId("answer-das").isVisible()).isTrue();
        }
    }

    @Test
    void shouldKeepSameObjectAndHighlightCorrectArticleWhenWrongSelected() {
        try (Page page = browser.newPage()) {
            page.navigate(baseUrl());

            String noun = page.getByTestId("question-noun").textContent();
            assertThat(noun).isNotNull();
            String correctArticle = articleByNoun.get(noun);
            assertThat(correctArticle).isNotBlank();

            String wrongArticle = pickWrongArticle(correctArticle);
            clickArticle(page, wrongArticle);

            assertThat(page.getByTestId("question-noun").textContent()).isEqualTo(noun);
            assertThat(page.getByTestId("answer-" + correctArticle).getAttribute("class"))
                    .contains("correct-answer");
        }
    }

    @Test
    void shouldAdvanceOnlyAfterCorrectSelection() {
        try (Page page = browser.newPage()) {
            page.addInitScript("""
                    HTMLMediaElement.prototype.play = function() {
                      return Promise.resolve();
                    };
                    """);
            page.navigate(baseUrl());

            String noun = page.getByTestId("question-noun").textContent();
            assertThat(noun).isNotNull();
            String correctArticle = articleByNoun.get(noun);
            assertThat(correctArticle).isNotBlank();
            String wrongArticle = pickWrongArticle(correctArticle);

            clickArticle(page, wrongArticle);
            assertThat(page.getByTestId("question-noun").textContent()).isEqualTo(noun);

            clickArticle(page, correctArticle);
            assertThat(page.getByTestId("question-noun").textContent()).isEqualTo(noun);

            page.evaluate("() => document.querySelector('[data-testid=\"audio-correct\"]').dispatchEvent(new Event('ended'))");
            page.waitForFunction(
                    "previousNoun => document.querySelector('[data-testid=\"question-noun\"]')?.textContent !== previousNoun",
                    noun);

            String nextNoun = page.getByTestId("question-noun").textContent();
            assertThat(nextNoun).isNotNull();
            assertThat(nextNoun).isNotEqualTo(noun);
        }
    }

    @Test
    void shouldReplayNounAudioWhenSpeakerClicked() {
        try (Page page = browser.newPage()) {
            page.addInitScript("""
                    window.__playCount = 0;
                    const originalPlay = HTMLMediaElement.prototype.play;
                    HTMLMediaElement.prototype.play = function() {
                      window.__playCount++;
                      return Promise.resolve();
                    };
                    """);
            page.navigate(baseUrl());

            int before = ((Number) page.evaluate("() => window.__playCount")).intValue();
            page.getByTestId("noun-replay").click();
            page.waitForTimeout(100);
            int after = ((Number) page.evaluate("() => window.__playCount")).intValue();

            assertThat(after).isGreaterThan(before);
        }
    }

    private void clickArticle(Page page, String article) {
        page.getByTestId("answer-" + article).click();
        page.waitForLoadState(LoadState.DOMCONTENTLOADED);
    }

    private String pickWrongArticle(String correctArticle) {
        if (!"der".equals(correctArticle)) {
            return "der";
        }
        return "die";
    }

    private String baseUrl() {
        return "http://127.0.0.1:" + port + "/";
    }

    private Map<String, String> loadArticleByNoun(final Path csvPath) {
        try {
            var lines = Files.readAllLines(csvPath, StandardCharsets.UTF_8);
            if (lines.isEmpty()) {
                throw new IllegalStateException("CSV is empty: " + csvPath);
            }
            String[] header = lines.getFirst().split(",", -1);
            int nounIndex = indexOf(header, "Noun");
            int articleIndex = indexOf(header, "Article");

            return lines.stream()
                    .skip(1)
                    .map(String::trim)
                    .filter(line -> !line.isEmpty())
                    .map(line -> line.split(",", -1))
                    .collect(Collectors.toMap(
                            parts -> parts[nounIndex].trim(),
                            parts -> parts[articleIndex].trim()
                    ));
        } catch (IOException e) {
            throw new IllegalStateException("Failed reading CSV: " + csvPath, e);
        }
    }

    private int indexOf(String[] header, String column) {
        for (int i = 0; i < header.length; i++) {
            if (column.equals(header[i].trim())) {
                return i;
            }
        }
        throw new IllegalStateException("Missing required CSV column: " + column);
    }
}
