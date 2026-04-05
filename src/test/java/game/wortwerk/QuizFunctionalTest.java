package game.wortwerk;

import com.microsoft.playwright.Browser;
import com.microsoft.playwright.BrowserType;
import com.microsoft.playwright.Page;
import com.microsoft.playwright.Playwright;
import com.microsoft.playwright.Request;
import org.junit.jupiter.api.*;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import java.util.stream.Collectors;

import static org.assertj.core.api.Assertions.assertThat;

@Tag("e2e")
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class QuizFunctionalTest {

    private Playwright playwright;
    private Browser browser;
    private Map<String, String> articleByNoun;
    private String baseUrl;

    @BeforeAll
    void setUpBrowser() {
        playwright = Playwright.create();
        browser = playwright.chromium().launch(new BrowserType.LaunchOptions().setHeadless(true));
        articleByNoun = loadArticleByNoun(Path.of("assets/articles.csv"));
        baseUrl = resolveBaseUrl();
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
            page.navigate(baseUrl);

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
            page.navigate(baseUrl);

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
            page.navigate(baseUrl);

            String noun = page.getByTestId("question-noun").textContent();
            assertThat(noun).isNotNull();
            String correctArticle = articleByNoun.get(noun);
            assertThat(correctArticle).isNotBlank();
            String wrongArticle = pickWrongArticle(correctArticle);

            clickArticle(page, wrongArticle);
            assertThat(page.getByTestId("question-noun").textContent()).isEqualTo(noun);

            clickArticle(page, correctArticle);
            assertThat(page.getByTestId("question-noun").textContent()).isEqualTo(noun);

            page.waitForFunction("() => document.querySelector('[data-testid=\"next-form\"]') !== null");
            page.waitForResponse(
                    response -> response.url().endsWith("/next")
                            && "POST".equalsIgnoreCase(response.request().method()),
                    () -> page.evaluate("() => document.querySelector('[data-testid=\"audio-correct\"]').dispatchEvent(new Event('ended'))"));
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
            page.navigate(baseUrl);

            int before = ((Number) page.evaluate("() => window.__playCount")).intValue();
            page.getByTestId("noun-replay").click();
            page.waitForTimeout(100);
            int after = ((Number) page.evaluate("() => window.__playCount")).intValue();

            assertThat(after).isGreaterThan(before);
        }
    }

    @Test
    void shouldSubmitAnswerViaHtmxRequest() {
        try (Page page = browser.newPage()) {
            page.navigate(baseUrl);

            String noun = page.getByTestId("question-noun").textContent();
            assertThat(noun).isNotNull();
            String correctArticle = articleByNoun.get(noun);
            assertThat(correctArticle).isNotBlank();
            String wrongArticle = pickWrongArticle(correctArticle);

            Request request = page.waitForRequest(
                    req -> req.url().endsWith("/answer") && "POST".equalsIgnoreCase(req.method()),
                    () -> clickArticle(page, wrongArticle));

            assertThat(request.headerValue("HX-Request")).isEqualToIgnoringCase("true");
        }
    }

    @Test
    void shouldSubmitNextViaHtmxRequestAfterCorrectAudioCompletes() {
        try (Page page = browser.newPage()) {
            page.addInitScript("""
                    HTMLMediaElement.prototype.play = function() {
                      return Promise.resolve();
                    };
                    """);
            page.navigate(baseUrl);

            String noun = page.getByTestId("question-noun").textContent();
            assertThat(noun).isNotNull();
            String correctArticle = articleByNoun.get(noun);
            assertThat(correctArticle).isNotBlank();

            clickArticle(page, correctArticle);
            page.waitForFunction("() => document.querySelector('[data-testid=\"next-form\"]') !== null");

            Request request = page.waitForRequest(
                    req -> req.url().endsWith("/next") && "POST".equalsIgnoreCase(req.method()),
                    () -> page.evaluate("() => document.querySelector('[data-testid=\"audio-correct\"]').dispatchEvent(new Event('ended'))"));

            assertThat(request.headerValue("HX-Request")).isEqualToIgnoringCase("true");
        }
    }

    private void clickArticle(Page page, String article) {
        page.waitForResponse(
                response -> response.url().endsWith("/answer")
                        && "POST".equalsIgnoreCase(response.request().method()),
                () -> page.getByTestId("answer-" + article).click());
        page.waitForSelector("[data-testid='question-noun']");
    }

    private String pickWrongArticle(String correctArticle) {
        if (!"der".equals(correctArticle)) {
            return "der";
        }
        return "die";
    }

    private static String resolveBaseUrl() {
        String externalBaseUrl = System.getProperty("test.base-url", "").trim();
        if (externalBaseUrl.isEmpty()) {
            throw new IllegalStateException("Missing required system property: test.base-url");
        }
        return externalBaseUrl.endsWith("/") ? externalBaseUrl : externalBaseUrl + "/";
    }

    private static Map<String, String> loadArticleByNoun(final Path csvPath) {
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

    private static int indexOf(String[] header, String column) {
        for (int i = 0; i < header.length; i++) {
            if (column.equals(header[i].trim())) {
                return i;
            }
        }
        throw new IllegalStateException("Missing required CSV column: " + column);
    }
}
