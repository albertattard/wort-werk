package game.wortwerk;

import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.boot.health.contributor.Health;
import org.springframework.boot.health.contributor.HealthIndicator;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.jdbc.core.JdbcOperations;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.RequestPostProcessor;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.redirectedUrl;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(properties = {
        "spring.autoconfigure.exclude=org.springframework.boot.jdbc.autoconfigure.DataSourceAutoConfiguration,org.springframework.boot.flyway.autoconfigure.FlywayAutoConfiguration"
})
@AutoConfigureMockMvc
@Import(QuizControllerTest.TestBeans.class)
class QuizControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void shouldRedirectToLoginWhenAnonymousUserAccessesQuiz() throws Exception {
        mockMvc.perform(get("/"))
                .andExpect(status().is3xxRedirection())
                .andExpect(header().string("Location", "/login"));
    }

    @Test
    void shouldRenderInitialQuizPage() throws Exception {
        MvcResult result = mockMvc.perform(get("/").with(passkeyUser()))
                .andExpect(status().isOk())
                .andReturn();

        String body = result.getResponse().getContentAsString();
        assertThat(body)
                .contains("Wort-Werk")
                .contains("question-noun")
                .contains("der")
                .contains("die")
                .contains("das");
    }

    @Test
    void shouldWaitForNextAfterCorrectAnswer() throws Exception {
        MvcResult initialResult = mockMvc.perform(get("/").with(passkeyUser()))
                .andExpect(status().isOk())
                .andReturn();
        String initialBody = initialResult.getResponse().getContentAsString();

        MvcResult answerResult = mockMvc.perform(post("/answer").with(passkeyUser()).with(csrf()).header("HX-Request", "true").param("article", "der"))
                .andExpect(status().isOk())
                .andReturn();

        String answerBody = answerResult.getResponse().getContentAsString();
        assertThat(answerBody).contains("Runde 1 von 10");
        assertThat(answerBody).contains("question-noun");
        assertThat(answerBody).isNotEqualTo(initialBody);

        MvcResult nextResult = mockMvc.perform(post("/next").with(passkeyUser()).with(csrf()).header("HX-Request", "true"))
                .andExpect(status().isOk())
                .andReturn();
        assertThat(nextResult.getResponse().getContentAsString()).containsAnyOf("Runde 1 von 10", "Runde 2 von 10");
    }

    @Test
    void shouldRestartQuiz() throws Exception {
        mockMvc.perform(get("/").with(passkeyUser()))
                .andExpect(status().isOk());

        MvcResult result = mockMvc.perform(post("/restart").with(passkeyUser()).with(csrf()).header("HX-Request", "true"))
                .andExpect(status().isOk())
                .andReturn();

        assertThat(result.getResponse().getContentAsString()).contains("Runde");
    }

    @Test
    void shouldRedirectOnAnswerWithoutHtmxHeader() throws Exception {
        mockMvc.perform(get("/").with(passkeyUser()))
                .andExpect(status().isOk());

        mockMvc.perform(post("/answer").with(passkeyUser()).with(csrf()).param("article", "der"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/"));
    }

    private RequestPostProcessor passkeyUser() {
        return user("test-user")
                .authorities(
                        new SimpleGrantedAuthority("ROLE_USER"),
                        new SimpleGrantedAuthority("FACTOR_WEBAUTHN"));
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
