package game.wortwerk;

import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.boot.health.contributor.Health;
import org.springframework.boot.health.contributor.HealthIndicator;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.jdbc.core.JdbcOperations;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(
        webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT,
        properties = {
                "spring.autoconfigure.exclude=org.springframework.boot.jdbc.autoconfigure.DataSourceAutoConfiguration,org.springframework.boot.flyway.autoconfigure.FlywayAutoConfiguration"
        }
)
@Import(ForwardedHttpsRedirectTest.TestBeans.class)
class ForwardedHttpsRedirectTest {

    @LocalServerPort
    private int port;

    @Test
    void shouldPreserveHttpsOriginInAnonymousRedirectsBehindLoadBalancer() throws IOException, InterruptedException {
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create("http://127.0.0.1:" + port + "/"))
                .header("X-Forwarded-Proto", "https")
                .header("X-Forwarded-Host", "wortwerk.xyz")
                .header("X-Forwarded-Port", "443")
                .GET()
                .build();

        try (HttpClient client = HttpClient.newBuilder()
                .followRedirects(HttpClient.Redirect.NEVER)
                .build()) {
            HttpResponse<Void> response = client.send(request, HttpResponse.BodyHandlers.discarding());

            assertThat(response.statusCode()).isEqualTo(302);
            assertThat(response.headers().firstValue("Location"))
                    .hasValue("https://wortwerk.xyz/login");
        }
    }

    @TestConfiguration
    static class TestBeans {

        @Bean
        JdbcOperations jdbcOperations() {
            return Mockito.mock(JdbcOperations.class);
        }

        @Bean
        HealthIndicator dbHealthIndicator() {
            return () -> Health.up().build();
        }
    }
}
