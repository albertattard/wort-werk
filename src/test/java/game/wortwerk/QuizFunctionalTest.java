package game.wortwerk;

import com.microsoft.playwright.Browser;
import com.microsoft.playwright.BrowserContext;
import com.microsoft.playwright.BrowserType;
import com.microsoft.playwright.CDPSession;
import com.microsoft.playwright.Page;
import com.microsoft.playwright.Playwright;
import com.microsoft.playwright.Request;
import com.microsoft.playwright.Response;
import com.microsoft.playwright.TimeoutError;
import com.google.gson.JsonObject;
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
    private Map<String, String> articleByImagePath;
    private String baseUrl;

    @BeforeAll
    void setUpBrowser() {
        playwright = Playwright.create();
        browser = playwright.chromium().launch(new BrowserType.LaunchOptions().setHeadless(true));
        articleByImagePath = loadArticleByImagePath(Path.of("assets/articles.csv"));
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
    void shouldRequireLoginBeforeAccessingQuiz() {
        try (BrowserContext context = browser.newContext(); Page page = context.newPage()) {
            page.navigate(baseUrl);
            page.waitForURL(url -> url.contains("/login"));

            assertThat(page.getByTestId("login-title").isVisible()).isTrue();
            assertThat(page.getByTestId("login-passkey-submit").isVisible()).isTrue();
        }
    }

    @Test
    void shouldShowBuildFooterOnLoginRegistrationAndQuizPages() {
        try (BrowserContext context = browser.newContext(); Page page = context.newPage()) {
            enableVirtualAuthenticator(context, page);
            String expectedBuildLabel = "Build: " + resolveExpectedBuildHash();
            page.navigate(baseUrl);
            page.waitForURL(url -> url.contains("/login"));

            assertThat(page.getByTestId("app-footer").isVisible()).isTrue();
            assertThat(page.getByTestId("build-label").textContent()).isEqualTo(expectedBuildLabel);

            page.navigate(baseUrl + "register");
            assertThat(page.getByTestId("app-footer").isVisible()).isTrue();
            assertThat(page.getByTestId("build-label").textContent()).isEqualTo(expectedBuildLabel);

            login(page);

            assertThat(page.getByTestId("app-footer").isVisible()).isTrue();
            assertThat(page.getByTestId("build-label").textContent()).isEqualTo(expectedBuildLabel);
        }
    }

    @Test
    void shouldAllowRegisterAndThenLogin() {
        try (BrowserContext context = browser.newContext(); Page page = context.newPage()) {
            enableVirtualAuthenticator(context, page);
            String username = "user_" + System.currentTimeMillis();
            registerWithPasskey(page, username);
            loginWithPasskey(page);

            assertThat(page.getByTestId("question-image").isVisible()).isTrue();
        }
    }

    @Test
    void shouldLoadQuizAndShowArticleChoices() {
        try (BrowserContext context = browser.newContext(); Page page = context.newPage()) {
            enableVirtualAuthenticator(context, page);
            login(page);

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
        try (BrowserContext context = browser.newContext(); Page page = context.newPage()) {
            enableVirtualAuthenticator(context, page);
            login(page);

            String noun = page.getByTestId("question-noun").textContent();
            assertThat(noun).isNotNull();
            String correctArticle = articleByImagePath.get(currentImagePath(page));
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
        try (BrowserContext context = browser.newContext(); Page page = context.newPage()) {
            enableVirtualAuthenticator(context, page);
            page.addInitScript("""
                    HTMLMediaElement.prototype.play = function() {
                      return Promise.resolve();
                    };
                    """);
            login(page);

            String noun = page.getByTestId("question-noun").textContent();
            assertThat(noun).isNotNull();
            String correctArticle = articleByImagePath.get(currentImagePath(page));
            assertThat(correctArticle).isNotBlank();
            String wrongArticle = pickWrongArticle(correctArticle);

            clickArticle(page, wrongArticle);
            assertThat(page.getByTestId("question-noun").textContent()).isEqualTo(noun);

            clickArticle(page, correctArticle);
            assertThat(page.getByTestId("question-noun").textContent()).isEqualTo(noun);

            page.waitForFunction("() => document.querySelector('[data-testid=\"next-form\"]') !== null");
            page.evaluate("""
                    () => {
                      const nextForm = document.querySelector('[data-testid="next-form"]');
                      if (!nextForm) {
                        throw new Error("next form not found");
                      }
                      if (window.htmx) {
                        htmx.ajax('POST', nextForm.getAttribute('hx-post') || '/next', {
                          source: nextForm,
                          target: nextForm.getAttribute('hx-target') || '#quiz-interaction',
                          swap: nextForm.getAttribute('hx-swap') || 'outerHTML',
                          values: Object.fromEntries(new FormData(nextForm).entries())
                        });
                        return;
                      }
                      nextForm.requestSubmit();
                    }
                    """);
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
        try (BrowserContext context = browser.newContext(); Page page = context.newPage()) {
            enableVirtualAuthenticator(context, page);
            page.addInitScript("""
                    window.__playCount = 0;
                    const originalPlay = HTMLMediaElement.prototype.play;
                    HTMLMediaElement.prototype.play = function() {
                      window.__playCount++;
                      return Promise.resolve();
                    };
                    """);
            login(page);

            int before = ((Number) page.evaluate("() => window.__playCount")).intValue();
            page.getByTestId("noun-replay").click();
            page.waitForTimeout(100);
            int after = ((Number) page.evaluate("() => window.__playCount")).intValue();

            assertThat(after).isGreaterThan(before);
        }
    }

    @Test
    void shouldSubmitAnswerViaHtmxRequest() {
        try (BrowserContext context = browser.newContext(); Page page = context.newPage()) {
            enableVirtualAuthenticator(context, page);
            login(page);

            String noun = page.getByTestId("question-noun").textContent();
            assertThat(noun).isNotNull();
            String correctArticle = articleByImagePath.get(currentImagePath(page));
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
        try (BrowserContext context = browser.newContext(); Page page = context.newPage()) {
            enableVirtualAuthenticator(context, page);
            page.addInitScript("""
                    HTMLMediaElement.prototype.play = function() {
                      return Promise.resolve();
                    };
                    """);
            login(page);

            String noun = page.getByTestId("question-noun").textContent();
            assertThat(noun).isNotNull();
            String correctArticle = articleByImagePath.get(currentImagePath(page));
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

    private void login(Page page) {
        String username = "user_" + System.nanoTime();
        registerWithPasskey(page, username);
        loginWithPasskey(page);
    }

    private void registerWithPasskey(Page page, String username) {
        page.navigate(baseUrl + "register");
        page.getByTestId("register-username").fill(username);
        page.getByTestId("register-passkey-label").fill("E2E Geraet");
        Response sessionResponse;
        Response optionsResponse;
        Response registerResponse;

        try {
            sessionResponse = page.waitForResponse(
                    response -> response.url().endsWith("/passkey/register/session"),
                    new Page.WaitForResponseOptions().setTimeout(10_000),
                    () -> page.getByTestId("register-submit").click());
        } catch (TimeoutError timeoutError) {
            String errorText = page.getByTestId("register-error").textContent();
            throw new AssertionError("Passkey registration did not call /passkey/register/session. UI error: " + errorText, timeoutError);
        }

        try {
            optionsResponse = page.waitForResponse(
                    response -> response.url().endsWith("/webauthn/register/options"),
                    new Page.WaitForResponseOptions().setTimeout(10_000),
                    () -> {
                    });
        } catch (TimeoutError timeoutError) {
            String errorText = page.getByTestId("register-error").textContent();
            throw new AssertionError(
                    "Passkey registration did not call /webauthn/register/options after session call (status "
                            + sessionResponse.status() + "). UI error: " + errorText,
                    timeoutError);
        }

        try {
            registerResponse = page.waitForResponse(
                    response -> response.url().endsWith("/webauthn/register"),
                    new Page.WaitForResponseOptions().setTimeout(20_000),
                    () -> {
                    });
        } catch (TimeoutError timeoutError) {
            String errorText = page.getByTestId("register-error").textContent();
            throw new AssertionError(
                    "Passkey registration did not call /webauthn/register after options call (status "
                            + optionsResponse.status() + "). UI error: " + errorText,
                    timeoutError);
        }

        try {
            page.waitForURL(url -> url.contains("/login?registered"), new Page.WaitForURLOptions().setTimeout(10_000));
        } catch (TimeoutError timeoutError) {
            String errorText = page.getByTestId("register-error").textContent();
            String currentUrl = page.url();
            String registerResponseBody = registerResponse.text();
            throw new AssertionError(
                    "Passkey registration did not redirect. URL: " + currentUrl
                            + ", statuses: session=" + sessionResponse.status()
                            + ", options=" + optionsResponse.status()
                            + ", register=" + registerResponse.status()
                            + ", registerBody=" + registerResponseBody
                            + ", UI error: " + errorText,
                    timeoutError);
        }
    }

    private void loginWithPasskey(Page page) {
        page.getByTestId("login-passkey-submit").click();
        page.waitForURL(url -> !url.contains("/login"));
    }

    private void enableVirtualAuthenticator(BrowserContext context, Page page) {
        CDPSession cdp = context.newCDPSession(page);
        cdp.send("WebAuthn.enable");

        JsonObject options = new JsonObject();
        options.addProperty("protocol", "ctap2");
        options.addProperty("transport", "internal");
        options.addProperty("hasResidentKey", true);
        options.addProperty("hasUserVerification", true);
        options.addProperty("isUserVerified", true);
        options.addProperty("automaticPresenceSimulation", true);

        JsonObject payload = new JsonObject();
        payload.add("options", options);
        cdp.send("WebAuthn.addVirtualAuthenticator", payload);
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

    private static String resolveExpectedBuildHash() {
        try {
            Process process = new ProcessBuilder("git", "rev-parse", "--short=7", "HEAD")
                    .redirectErrorStream(true)
                    .start();
            int exitCode = process.waitFor();
            String output = new String(process.getInputStream().readAllBytes(), StandardCharsets.UTF_8).trim();
            if (exitCode != 0 || output.isBlank()) {
                throw new IllegalStateException("Failed to resolve git build hash: " + output);
            }
            return output;
        } catch (IOException | InterruptedException e) {
            throw new IllegalStateException("Failed to resolve git build hash", e);
        }
    }

    private static Map<String, String> loadArticleByImagePath(final Path csvPath) {
        try {
            var lines = Files.readAllLines(csvPath, StandardCharsets.UTF_8);
            if (lines.isEmpty()) {
                throw new IllegalStateException("CSV is empty: " + csvPath);
            }
            String[] header = lines.getFirst().split(",", -1);
            int articleIndex = indexOf(header, "Article");
            int imageIndex = indexOf(header, "Image");

            return lines.stream()
                    .skip(1)
                    .map(String::trim)
                    .filter(line -> !line.isEmpty())
                    .map(line -> line.split(",", -1))
                    .collect(Collectors.toMap(
                            parts -> "/" + parts[imageIndex].trim(),
                            parts -> parts[articleIndex].trim()
                    ));
        } catch (IOException e) {
            throw new IllegalStateException("Failed reading CSV: " + csvPath, e);
        }
    }

    private static String currentImagePath(final Page page) {
        String imageSrc = page.getByTestId("question-image").getAttribute("src");
        assertThat(imageSrc).isNotBlank();
        return imageSrc;
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
