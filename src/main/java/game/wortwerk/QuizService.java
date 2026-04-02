package game.wortwerk;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import org.springframework.stereotype.Service;

@Service
public class QuizService {

    private static final int TOTAL_ROUNDS = 10;

    private final ArticleRepository articleRepository;

    public QuizService(ArticleRepository articleRepository) {
        this.articleRepository = articleRepository;
    }

    public QuizState startNewQuiz() {
        List<ArticleEntry> allEntries = new ArrayList<>(articleRepository.findAll());
        Collections.shuffle(allEntries);

        int rounds = Math.min(TOTAL_ROUNDS, allEntries.size());
        List<ArticleEntry> selected = List.copyOf(allEntries.subList(0, rounds));

        return new QuizState(selected, rounds);
    }
}
