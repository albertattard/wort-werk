package game.wortwerk;

import java.util.List;

public final class QuizState {

    private final List<ArticleEntry> questions;
    private final int totalRounds;

    private int currentIndex;
    private int score;
    private boolean answered;
    private String feedback;

    public QuizState(List<ArticleEntry> questions, int totalRounds) {
        this.questions = questions;
        this.totalRounds = totalRounds;
        this.currentIndex = 0;
        this.score = 0;
        this.answered = false;
        this.feedback = "";
    }

    public int getCurrentRound() {
        return currentIndex + 1;
    }

    public int getTotalRounds() {
        return totalRounds;
    }

    public int getScore() {
        return score;
    }

    public boolean isAnswered() {
        return answered;
    }

    public boolean isFinished() {
        return currentIndex >= totalRounds;
    }

    public ArticleEntry getCurrentQuestion() {
        if (isFinished()) {
            return null;
        }
        return questions.get(currentIndex);
    }

    public String getFeedback() {
        return feedback;
    }

    public void answer(String selectedArticle) {
        if (isFinished() || answered) {
            return;
        }

        ArticleEntry current = getCurrentQuestion();
        boolean correct = current.article().equals(selectedArticle);

        if (correct) {
            score++;
            feedback = "Richtig: " + current.articlePhrase();
        } else {
            feedback = "Falsch. Richtig ist: " + current.articlePhrase();
        }

        answered = true;
    }

    public void nextRound() {
        if (!answered || isFinished()) {
            return;
        }

        currentIndex++;
        answered = false;
        feedback = "";
    }
}
