package game.wortwerk;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class QuizControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void shouldRenderInitialQuizPage() throws Exception {
        mockMvc.perform(get("/"))
                .andExpect(status().isOk())
                .andExpect(content().string(org.hamcrest.Matchers.containsString("Wort-Werk")))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("der")))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("die")))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("das")));
    }

    @Test
    void shouldAnswerAndMoveToNextRound() throws Exception {
        mockMvc.perform(get("/"))
                .andExpect(status().isOk());

        mockMvc.perform(post("/answer").param("article", "der"))
                .andExpect(status().isOk())
                .andExpect(content().string(org.hamcrest.Matchers.anyOf(
                        org.hamcrest.Matchers.containsString("Richtig:"),
                        org.hamcrest.Matchers.containsString("Falsch.")
                )));

        mockMvc.perform(post("/next"))
                .andExpect(status().isOk())
                .andExpect(content().string(org.hamcrest.Matchers.containsString("Runde")));
    }

    @Test
    void shouldRestartQuiz() throws Exception {
        mockMvc.perform(get("/"))
                .andExpect(status().isOk());

        mockMvc.perform(post("/restart"))
                .andExpect(status().isOk())
                .andExpect(content().string(org.hamcrest.Matchers.containsString("Runde")));
    }
}
