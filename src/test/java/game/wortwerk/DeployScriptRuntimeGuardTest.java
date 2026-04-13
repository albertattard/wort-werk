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

class DeployScriptRuntimeGuardTest {

    @TempDir
    Path tempDir;

    @Test
    void shouldRejectLocalRuntimeApplyOutsideMigrationOrOciDevops() throws Exception {
        Path script = prepareTempRepo();

        ProcessResult result = runScript(script, "runtime", Map.of());

        assertThat(result.exitCode()).isNotZero();
        assertThat(result.stderr()).contains("Production runtime apply is restricted to OCI DevOps");
    }

    private Path prepareTempRepo() throws IOException {
        Path repoRoot = tempDir.resolve("repo");
        Path ociDir = Files.createDirectories(repoRoot.resolve("infrastructure/oci"));
        Files.createDirectories(ociDir.resolve("foundation"));
        Files.createDirectories(ociDir.resolve("data"));
        Files.createDirectories(ociDir.resolve("runtime"));
        Files.createDirectories(ociDir.resolve("devops"));

        Path script = ociDir.resolve("deploy.sh");
        Files.writeString(
                script,
                Files.readString(Path.of("infrastructure/oci/deploy.sh"), StandardCharsets.UTF_8),
                StandardCharsets.UTF_8);
        setExecutable(script);
        return script;
    }

    private ProcessResult runScript(Path script, String mode, Map<String, String> extraEnvironment) throws Exception {
        ProcessBuilder processBuilder = new ProcessBuilder("bash", script.toString(), mode);
        processBuilder.directory(script.getParent().toFile());

        Map<String, String> environment = processBuilder.environment();
        environment.remove("OCI_CLI_AUTH");
        environment.remove("OCI_RESOURCE_PRINCIPAL_VERSION");
        environment.remove("OCI_RESOURCE_PRINCIPAL_REGION");
        environment.remove("OCI_RESOURCE_PRINCIPAL_RPST");
        environment.remove("OCI_RESOURCE_PRINCIPAL_PRIVATE_PEM");
        environment.remove("OCI_RESOURCE_PRINCIPAL_PRIVATE_PEM_PASSPHRASE");
        environment.remove("OCI_RESOURCE_PRINCIPAL_SESSION_TOKEN");
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

    private record ProcessResult(int exitCode, String stdout, String stderr) {
    }
}
