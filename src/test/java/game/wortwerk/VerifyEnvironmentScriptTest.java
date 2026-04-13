package game.wortwerk;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.attribute.PosixFilePermission;
import java.util.EnumSet;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class VerifyEnvironmentScriptTest {

    @TempDir
    Path tempDir;

    @Test
    void shouldUseDockerComposeBackendByDefault() throws Exception {
        TestHarness harness = prepareHarness();
        Path captureFile = harness.repoRoot().resolve("docker-args.txt");

        Path dockerStub = harness.binDir().resolve("docker");
        Files.writeString(
                dockerStub,
                """
                #!/usr/bin/env bash
                set -euo pipefail
                printf '%s\n' "$*" >> "${VERIFY_CAPTURE_FILE:?}"
                exit 0
                """,
                StandardCharsets.UTF_8);
        setExecutable(dockerStub);

        ProcessResult result = runScript(harness, "down", Map.of(
                "VERIFY_CAPTURE_FILE", captureFile.toString()));

        assertThat(result.exitCode())
                .withFailMessage("stdout=%s%nstderr=%s", result.stdout(), result.stderr())
                .isZero();
        assertThat(Files.readString(captureFile, StandardCharsets.UTF_8))
                .contains("compose --file")
                .contains("compose.verify.yml")
                .contains("--project-name wort-werk-verify down --volumes --remove-orphans");
    }

    @Test
    void shouldUsePodmanBackendWhenRequested() throws Exception {
        TestHarness harness = prepareHarness();
        Path captureFile = harness.repoRoot().resolve("podman-args.txt");

        Path podmanStub = harness.binDir().resolve("podman");
        Files.writeString(
                podmanStub,
                """
                #!/usr/bin/env bash
                set -euo pipefail
                printf '%s\n' "$*" >> "${VERIFY_CAPTURE_FILE:?}"
                if [[ "${1:-}" == "network" && "${2:-}" == "exists" ]]; then
                  exit 1
                fi
                if [[ "${1:-}" == "inspect" ]]; then
                  printf 'healthy'
                  exit 0
                fi
                exit 0
                """,
                StandardCharsets.UTF_8);
        setExecutable(podmanStub);

        ProcessResult result = runScript(harness, "up", Map.of(
                "VERIFY_ENV_BACKEND", "podman",
                "VERIFY_CAPTURE_FILE", captureFile.toString()));

        assertThat(result.exitCode())
                .withFailMessage("stdout=%s%nstderr=%s", result.stdout(), result.stderr())
                .isZero();
        assertThat(Files.readString(captureFile, StandardCharsets.UTF_8))
                .contains("network exists wort-werk-verify")
                .contains("network create wort-werk-verify")
                .contains("run --replace --detach --name wort-werk-verify-db")
                .contains("postgres:17")
                .contains("run --replace --detach --name wort-werk-verify-app")
                .contains("--pull=never")
                .contains("wort-werk:verify-test");
    }

    @Test
    void shouldWireMavenVerifyLifecycleThroughRepositoryHelper() throws IOException {
        String pom = Files.readString(Path.of("pom.xml"), StandardCharsets.UTF_8);

        assertThat(pom).contains("<verify.environment.script>${project.basedir}/tools/verify-environment.sh</verify.environment.script>");
        assertThat(pom).contains("<argument>${verify.environment.script}</argument>");
        assertThat(pom).doesNotContain("docker compose --file '${verify.compose.file}'");
    }

    private TestHarness prepareHarness() throws IOException {
        Path repoRoot = tempDir.resolve("repo");
        Path toolsDir = Files.createDirectories(repoRoot.resolve("tools"));
        Path containerDir = Files.createDirectories(repoRoot.resolve("container"));
        Path binDir = Files.createDirectories(repoRoot.resolve("bin"));

        Path script = toolsDir.resolve("verify-environment.sh");
        Files.writeString(
                script,
                Files.readString(Path.of("tools/verify-environment.sh"), StandardCharsets.UTF_8),
                StandardCharsets.UTF_8);
        setExecutable(script);

        Files.writeString(
                containerDir.resolve("compose.verify.yml"),
                Files.readString(Path.of("container/compose.verify.yml"), StandardCharsets.UTF_8),
                StandardCharsets.UTF_8);

        return new TestHarness(repoRoot, binDir, script);
    }

    private ProcessResult runScript(TestHarness harness, String command, Map<String, String> extraEnvironment)
            throws Exception {
        ProcessBuilder processBuilder = new ProcessBuilder("bash", harness.script().toString(), command);
        processBuilder.directory(harness.repoRoot().toFile());

        Map<String, String> environment = processBuilder.environment();
        environment.put("PATH", harness.binDir() + ":" + environment.get("PATH"));
        environment.put("VERIFY_CONTAINER_IMAGE", "wort-werk:verify-test");
        environment.put("VERIFY_CONTAINER_PORT", "18080");
        environment.put("VERIFY_DB_PORT", "15432");
        environment.put("VERIFY_DB_NAME", "wortwerk_verify");
        environment.put("VERIFY_DB_USERNAME", "wortwerk_verify");
        environment.put("VERIFY_DB_PASSWORD", "wortwerk_verify");
        environment.putAll(extraEnvironment);

        Process process = processBuilder.start();
        int exitCode = process.waitFor();

        return new ProcessResult(
                exitCode,
                new String(process.getInputStream().readAllBytes(), StandardCharsets.UTF_8),
                new String(process.getErrorStream().readAllBytes(), StandardCharsets.UTF_8));
    }

    private void setExecutable(Path path) throws IOException {
        Files.setPosixFilePermissions(path, EnumSet.of(
                PosixFilePermission.OWNER_READ,
                PosixFilePermission.OWNER_WRITE,
                PosixFilePermission.OWNER_EXECUTE));
    }

    private record TestHarness(Path repoRoot, Path binDir, Path script) {
    }

    private record ProcessResult(int exitCode, String stdout, String stderr) {
    }
}
