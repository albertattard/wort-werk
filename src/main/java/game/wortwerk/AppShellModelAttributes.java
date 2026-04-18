package game.wortwerk;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ModelAttribute;

@ControllerAdvice
public class AppShellModelAttributes {

    private final String buildLabel;

    public AppShellModelAttributes(@Value("${wortwerk.build-hash}") String buildHash) {
        this.buildLabel = "Build: " + normalize(buildHash);
    }

    @ModelAttribute("buildLabel")
    public String buildLabel() {
        return buildLabel;
    }

    private String normalize(String buildHash) {
        if (buildHash == null) {
            return "dev";
        }

        String normalized = buildHash.trim();
        if (normalized.isBlank()) {
            return "dev";
        }

        return normalized;
    }
}
