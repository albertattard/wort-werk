package game.wortwerk;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.MockMvc;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class QuizControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void shouldRenderInitialQuizPage() throws Exception {
        MvcResult result = mockMvc.perform(get("/"))
                .andExpect(status().isOk())
                .andReturn();

        String body = result.getResponse().getContentAsString();
        assertThat(body)
                .contains("Wort-Werk")
                .contains("der")
                .contains("die")
                .contains("das");
    }

    @Test
    void shouldAnswerAndMoveToNextRound() throws Exception {
        mockMvc.perform(get("/"))
                .andExpect(status().isOk());

        MvcResult answerResult = mockMvc.perform(post("/answer").header("HX-Request", "true").param("article", "der"))
                .andExpect(status().isOk())
                .andReturn();

        String answerBody = answerResult.getResponse().getContentAsString();
        assertThat(answerBody.contains("Richtig:") || answerBody.contains("Falsch.")).isTrue();

        MvcResult nextResult = mockMvc.perform(post("/next").header("HX-Request", "true"))
                .andExpect(status().isOk())
                .andReturn();

        assertThat(nextResult.getResponse().getContentAsString()).contains("Runde");
    }

    @Test
    void shouldRestartQuiz() throws Exception {
        mockMvc.perform(get("/"))
                .andExpect(status().isOk());

        MvcResult result = mockMvc.perform(post("/restart").header("HX-Request", "true"))
                .andExpect(status().isOk())
                .andReturn();

        assertThat(result.getResponse().getContentAsString()).contains("Runde");
    }
}
