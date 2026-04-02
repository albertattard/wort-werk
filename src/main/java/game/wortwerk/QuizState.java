package game.wortwerk;

import java.util.List;

public final class QuizState {

    private final List<ArticleEntry> questions;
    private final int totalRounds;

    private int currentIndex;
    private int score;
    private String selectedArticle;
    private Boolean lastAnswerCorrect;
    private boolean awaitingCorrectAudioCompletion;
    private String feedback;

    public QuizState(List<ArticleEntry> questions, int totalRounds) {
        this.questions = questions;
        this.totalRounds = totalRounds;
        this.currentIndex = 0;
        this.score = 0;
        this.selectedArticle = null;
        this.lastAnswerCorrect = null;
        this.awaitingCorrectAudioCompletion = false;
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

    public boolean hasFeedback() {
        return feedback != null && !feedback.isBlank();
    }

    public boolean isAwaitingCorrectAudioCompletion() {
        return awaitingCorrectAudioCompletion;
    }

    public String getNounAudioPath() {
        return getCurrentQuestion().nounAudioPath();
    }

    public String getCorrectPhraseAudioPath() {
        return getCurrentQuestion().phraseAudioPath();
    }

    public boolean isCorrectHighlighted(String article) {
        return Boolean.FALSE.equals(lastAnswerCorrect)
                && !isFinished()
                && getCurrentQuestion().article().equals(article);
    }

    public boolean isWrongSelection(String article) {
        return Boolean.FALSE.equals(lastAnswerCorrect)
                && selectedArticle != null
                && selectedArticle.equals(article)
                && !isCorrectHighlighted(article);
    }

    public void answer(String selectedArticle) {
        if (isFinished() || awaitingCorrectAudioCompletion) {
            return;
        }

        ArticleEntry current = getCurrentQuestion();
        boolean correct = current.article().equals(selectedArticle);
        this.selectedArticle = selectedArticle;

        if (correct) {
            score++;
            feedback = "";
            lastAnswerCorrect = true;
            awaitingCorrectAudioCompletion = true;
        } else {
            feedback = "Falsch. Richtig ist: " + current.articlePhrase();
            lastAnswerCorrect = false;
        }
    }

    public void moveToNextQuestion() {
        if (isFinished() || !awaitingCorrectAudioCompletion) {
            return;
        }
        currentIndex++;
        selectedArticle = null;
        lastAnswerCorrect = null;
        awaitingCorrectAudioCompletion = false;
        feedback = "";
    }
}
