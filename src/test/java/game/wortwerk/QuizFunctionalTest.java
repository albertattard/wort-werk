package game.wortwerk;

import com.microsoft.playwright.Browser;
import com.microsoft.playwright.BrowserType;
import com.microsoft.playwright.Page;
import com.microsoft.playwright.Playwright;
import com.microsoft.playwright.options.LoadState;
import org.junit.jupiter.api.*;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

@Tag("e2e")
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class QuizFunctionalTest {

    @LocalServerPort
    private int port;

    private Playwright playwright;
    private Browser browser;
    private static final Map<String, String> ARTICLE_BY_NOUN = Map.ofEntries(
            Map.entry("Apfel", "der"),
            Map.entry("Banane", "die"),
            Map.entry("Bett", "das"),
            Map.entry("Fleisch", "das"),
            Map.entry("Gabel", "die"),
            Map.entry("Hund", "der"),
            Map.entry("Kartoffel", "die"),
            Map.entry("Katze", "die"),
            Map.entry("Käse", "der"),
            Map.entry("Lampe", "die"),
            Map.entry("Löffel", "der"),
            Map.entry("Messer", "das"),
            Map.entry("Orange", "die"),
            Map.entry("Schinken", "der"),
            Map.entry("Sofa", "das"),
            Map.entry("Stuhl", "der"),
            Map.entry("Teppich", "der"),
            Map.entry("Tisch", "der"),
            Map.entry("Tomate", "die"),
            Map.entry("Zwiebel", "die")
    );

    @BeforeAll
    void setUpBrowser() {
        playwright = Playwright.create();
        browser = playwright.chromium().launch(new BrowserType.LaunchOptions().setHeadless(true));
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
            String correctArticle = ARTICLE_BY_NOUN.get(noun);
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
            page.navigate(baseUrl());

            String noun = page.getByTestId("question-noun").textContent();
            assertThat(noun).isNotNull();
            String correctArticle = ARTICLE_BY_NOUN.get(noun);
            assertThat(correctArticle).isNotBlank();
            String wrongArticle = pickWrongArticle(correctArticle);

            clickArticle(page, wrongArticle);
            assertThat(page.getByTestId("question-noun").textContent()).isEqualTo(noun);

            clickArticle(page, correctArticle);

            String nextNoun = page.getByTestId("question-noun").textContent();
            assertThat(nextNoun).isNotNull();
            assertThat(nextNoun).isNotEqualTo(noun);
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
}
