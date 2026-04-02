package game.wortwerk;

import com.microsoft.playwright.Browser;
import com.microsoft.playwright.BrowserType;
import com.microsoft.playwright.Page;
import com.microsoft.playwright.Playwright;
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
            assertThat(page.getByTestId("answer-der").isVisible()).isTrue();
            assertThat(page.getByTestId("answer-die").isVisible()).isTrue();
            assertThat(page.getByTestId("answer-das").isVisible()).isTrue();
        }
    }

    @Test
    void shouldShowFeedbackAfterAnswer() {
        try (Page page = browser.newPage()) {
            page.navigate(baseUrl());

            postFromPage(page, "answer", "article=der");
            page.reload();
            String feedback = page.getByTestId("feedback").textContent();

            assertThat(feedback).isNotNull();
            assertThat(feedback).satisfiesAnyOf(
                    value -> assertThat(value).contains("Richtig:"),
                    value -> assertThat(value).contains("Falsch.")
            );
        }
    }

    @Test
    void shouldFinishTenRoundsAndRestart() {
        try (Page page = browser.newPage()) {
            page.navigate(baseUrl());

            for (int i = 0; i < 10; i++) {
                postFromPage(page, "answer", "article=der");
                postFromPage(page, "next", "");
            }

            page.reload();
            assertThat(page.getByTestId("results").isVisible()).isTrue();
            assertThat(page.getByTestId("final-score").textContent().contains("Endstand:")).isTrue();

            postFromPage(page, "restart", "");
            page.reload();
            assertThat(page.getByTestId("round-label").textContent().contains("Runde 1 von 10")).isTrue();
        }
    }

    private void postFromPage(Page page, String path, String formBody) {
        page.evaluate("payload => fetch(payload.url, { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: payload.body })",
                Map.of("url", baseUrl() + path, "body", formBody));
    }

    private String baseUrl() {
        return "http://127.0.0.1:" + port + "/";
    }
}
