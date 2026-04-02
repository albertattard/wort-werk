package game.wortwerk;

import jakarta.servlet.http.HttpSession;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

@Controller
public class QuizController {

    private static final String SESSION_KEY = "quizState";

    private final QuizService quizService;

    public QuizController(QuizService quizService) {
        this.quizService = quizService;
    }

    @GetMapping("/")
    public String index(Model model, HttpSession session) {
        QuizState state = getOrCreateState(session);
        model.addAttribute("state", state);
        return "quiz";
    }

    @PostMapping("/answer")
    public String answer(@RequestParam("article") String article, Model model, HttpSession session) {
        QuizState state = getOrCreateState(session);
        state.answer(article);
        model.addAttribute("state", state);
        return "fragments :: interaction";
    }

    @PostMapping("/next")
    public String next(Model model, HttpSession session) {
        QuizState state = getOrCreateState(session);
        state.nextRound();
        model.addAttribute("state", state);
        return "fragments :: interaction";
    }

    @PostMapping("/restart")
    public String restart(Model model, HttpSession session) {
        QuizState state = quizService.startNewQuiz();
        session.setAttribute(SESSION_KEY, state);
        model.addAttribute("state", state);
        return "fragments :: interaction";
    }

    private QuizState getOrCreateState(HttpSession session) {
        QuizState state = (QuizState) session.getAttribute(SESSION_KEY);
        if (state == null) {
            state = quizService.startNewQuiz();
            session.setAttribute(SESSION_KEY, state);
        }
        return state;
    }
}
