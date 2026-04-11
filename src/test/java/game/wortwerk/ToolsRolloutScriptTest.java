package game.wortwerk;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.attribute.PosixFilePermission;
import java.util.EnumSet;
import java.util.HashMap;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class ToolsRolloutScriptTest {

    @TempDir
    Path tempDir;

    @Test
    void shouldGenerateVerifyCredentialsWhenMissing() throws Exception {
        Path captureFile = prepareTempRepo();

        runRollout(captureFile, Map.of());

        Map<String, String> environment = readCapturedEnvironment(captureFile);
        assertThat(environment.get("VERIFY_DB_USERNAME")).isNotBlank();
        assertThat(environment.get("VERIFY_DB_PASSWORD")).isNotBlank();
    }

    @Test
    void shouldPreserveExplicitVerifyCredentials() throws Exception {
        Path captureFile = prepareTempRepo();

        runRollout(captureFile, Map.of(
                "VERIFY_DB_USERNAME", "manual-user",
                "VERIFY_DB_PASSWORD", "manual-password"));

        Map<String, String> environment = readCapturedEnvironment(captureFile);
        assertThat(environment.get("VERIFY_DB_USERNAME")).isEqualTo("manual-user");
        assertThat(environment.get("VERIFY_DB_PASSWORD")).isEqualTo("manual-password");
    }

    private Path prepareTempRepo() throws IOException {
        Path repoRoot = tempDir.resolve("repo");
        Path toolsDir = Files.createDirectories(repoRoot.resolve("tools"));
        Path ociDir = Files.createDirectories(repoRoot.resolve("infrastructure/oci"));
        Path homeDir = Files.createDirectories(tempDir.resolve("home/.oci"));

        Files.writeString(
                homeDir.resolve("oci.secrets.env"),
                "OCI_USERNAME=test-user\nOCI_AUTH_TOKEN=test-token\n",
                StandardCharsets.UTF_8);

        Path rolloutScript = toolsDir.resolve("rollout");
        Files.writeString(
                rolloutScript,
                Files.readString(Path.of("tools/rollout"), StandardCharsets.UTF_8),
                StandardCharsets.UTF_8);
        setExecutable(rolloutScript);

        Path captureFile = repoRoot.resolve("captured.env");
        Path fakeDeploy = ociDir.resolve("deploy.sh");
        Files.writeString(
                fakeDeploy,
                """
                #!/usr/bin/env bash
                set -euo pipefail

                cat > "${CAPTURE_FILE}" <<EOF
                VERIFY_DB_USERNAME=${VERIFY_DB_USERNAME:-}
                VERIFY_DB_PASSWORD=${VERIFY_DB_PASSWORD:-}
                EOF
                """,
                StandardCharsets.UTF_8);
        setExecutable(fakeDeploy);

        return captureFile;
    }

    private void runRollout(Path captureFile, Map<String, String> extraEnvironment) throws Exception {
        ProcessBuilder processBuilder = new ProcessBuilder("bash", tempDir.resolve("repo/tools/rollout").toString());
        Map<String, String> environment = processBuilder.environment();
        environment.put("HOME", tempDir.resolve("home").toString());
        environment.put("CAPTURE_FILE", captureFile.toString());
        environment.putAll(extraEnvironment);

        Process process = processBuilder.start();
        int exitCode = process.waitFor();

        assertThat(exitCode)
                .withFailMessage(
                        "rollout script exited with %s, stdout=%s, stderr=%s",
                        exitCode,
                        new String(process.getInputStream().readAllBytes(), StandardCharsets.UTF_8),
                        new String(process.getErrorStream().readAllBytes(), StandardCharsets.UTF_8))
                .isZero();
    }

    private Map<String, String> readCapturedEnvironment(Path captureFile) throws IOException {
        Map<String, String> environment = new HashMap<>();
        for (String line : Files.readAllLines(captureFile, StandardCharsets.UTF_8)) {
            int separator = line.indexOf('=');
            environment.put(line.substring(0, separator), line.substring(separator + 1));
        }
        return environment;
    }

    private void setExecutable(Path path) throws IOException {
        Files.setPosixFilePermissions(path, EnumSet.of(
                PosixFilePermission.OWNER_READ,
                PosixFilePermission.OWNER_WRITE,
                PosixFilePermission.OWNER_EXECUTE));
    }
}
