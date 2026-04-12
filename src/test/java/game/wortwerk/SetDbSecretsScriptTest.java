package game.wortwerk;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.attribute.PosixFilePermission;
import java.time.Duration;
import java.util.EnumSet;
import java.util.Map;
import java.util.concurrent.TimeUnit;

import static org.assertj.core.api.Assertions.assertThat;

class SetDbSecretsScriptTest {

    @TempDir
    Path tempDir;

    @Test
    void shouldFailFastWithoutRuntimePasswordInNonInteractiveMode() throws Exception {
        TestHarness harness = prepareHarness();

        ProcessResult result = runScript(harness, Map.of(
                "POSTGRESQL_ADMIN_PASSWORD", "admin-secret",
                "WORTWERK_NONINTERACTIVE", "1"));

        assertThat(result.timedOut()).isFalse();
        assertThat(result.exitCode()).isNotZero();
        assertThat(result.stderr()).contains("RUNTIME_DB_PASSWORD");
        assertThat(result.stderr()).contains("non-interactive");
        assertThat(Files.exists(harness.ociCaptureFile())).isFalse();
    }

    @Test
    void shouldStoreSeparateAdminAndRuntimePasswords() throws Exception {
        TestHarness harness = prepareHarness();

        ProcessResult result = runScript(harness, Map.of(
                "POSTGRESQL_ADMIN_PASSWORD", "admin-secret",
                "RUNTIME_DB_PASSWORD", "runtime-secret"));

        assertThat(result.exitCode())
                .withFailMessage("stdout=%s%nstderr=%s", result.stdout(), result.stderr())
                .isZero();
        assertThat(Files.readString(harness.ociCaptureFile(), StandardCharsets.UTF_8))
                .contains("wort-werk-db-admin-password=admin-secret")
                .contains("wort-werk-db-runtime-password=runtime-secret");
    }

    private TestHarness prepareHarness() throws IOException {
        Path repoRoot = tempDir.resolve("repo");
        Path dataDir = Files.createDirectories(repoRoot.resolve("infrastructure/oci/data"));
        Files.createDirectories(repoRoot.resolve("infrastructure/oci/foundation"));
        Path binDir = Files.createDirectories(tempDir.resolve("bin"));

        Path scriptCopy = dataDir.resolve("set-db-secrets.sh");
        Files.writeString(
                scriptCopy,
                Files.readString(Path.of("infrastructure/oci/data/set-db-secrets.sh"), StandardCharsets.UTF_8),
                StandardCharsets.UTF_8);
        setExecutable(scriptCopy);

        Path terraformStub = binDir.resolve("terraform");
        Files.writeString(
                terraformStub,
                """
                #!/usr/bin/env bash
                set -euo pipefail

                case "${*: -1}" in
                  compartment_ocid) printf '%s' 'ocid1.compartment.oc1..example' ;;
                  vault_id) printf '%s' 'ocid1.vault.oc1..example' ;;
                  vault_key_id) printf '%s' 'ocid1.key.oc1..example' ;;
                  *) echo "unexpected terraform args: $*" >&2; exit 1 ;;
                esac
                """,
                StandardCharsets.UTF_8);
        setExecutable(terraformStub);

        Path ociCaptureFile = tempDir.resolve("oci-calls.txt");
        Path ociStub = binDir.resolve("oci");
        Files.writeString(
                ociStub,
                """
                #!/usr/bin/env bash
                set -euo pipefail

                CAPTURE_FILE="${OCI_CAPTURE_FILE:?}"

                if [[ "$1 $2 $3" == "vault secret list" ]]; then
                  printf 'null'
                  exit 0
                fi

                if [[ "$1 $2 $3" == "vault secret create-base64" ]]; then
                  secret_name=''
                  secret_value=''
                  while (($#)); do
                    case "$1" in
                      --secret-name)
                        secret_name="$2"
                        shift 2
                        ;;
                      --secret-content-content)
                        secret_value="$(printf '%s' "$2" | base64 --decode)"
                        shift 2
                        ;;
                      *)
                        shift
                        ;;
                    esac
                  done

                  printf '%s=%s\n' "$secret_name" "$secret_value" >> "${CAPTURE_FILE}"
                  printf 'ocid1.vaultsecret.oc1..%s' "$secret_name"
                  exit 0
                fi

                if [[ "$1 $2 $3" == "vault secret update-base64" ]]; then
                  exit 0
                fi

                echo "unexpected oci args: $*" >&2
                exit 1
                """,
                StandardCharsets.UTF_8);
        setExecutable(ociStub);

        return new TestHarness(scriptCopy, binDir, ociCaptureFile);
    }

    private ProcessResult runScript(TestHarness harness, Map<String, String> extraEnvironment) throws Exception {
        ProcessBuilder processBuilder = new ProcessBuilder("bash", harness.script().toString());
        processBuilder.directory(harness.script().getParent().toFile());

        Map<String, String> environment = processBuilder.environment();
        environment.put("PATH", harness.binDir() + ":" + environment.get("PATH"));
        environment.put("OCI_CAPTURE_FILE", harness.ociCaptureFile().toString());
        environment.putAll(extraEnvironment);

        Process process = processBuilder.start();
        boolean finished = process.waitFor(Duration.ofSeconds(3).toMillis(), TimeUnit.MILLISECONDS);
        if (!finished) {
            process.destroyForcibly();
            process.waitFor(Duration.ofSeconds(1).toMillis(), TimeUnit.MILLISECONDS);

            return new ProcessResult(
                    -1,
                    readStream(process.getInputStream()),
                    readStream(process.getErrorStream()),
                    true);
        }
        int exitCode = process.exitValue();

        return new ProcessResult(
                exitCode,
                readStream(process.getInputStream()),
                readStream(process.getErrorStream()),
                false);
    }

    private String readStream(InputStream inputStream) throws IOException {
        try {
            return new String(inputStream.readAllBytes(), StandardCharsets.UTF_8);
        } catch (IOException ignored) {
            return "";
        }
    }

    private void setExecutable(Path path) throws IOException {
        Files.setPosixFilePermissions(path, EnumSet.of(
                PosixFilePermission.OWNER_READ,
                PosixFilePermission.OWNER_WRITE,
                PosixFilePermission.OWNER_EXECUTE));
    }

    private record TestHarness(Path script, Path binDir, Path ociCaptureFile) {
    }

    private record ProcessResult(int exitCode, String stdout, String stderr, boolean timedOut) {
    }
}
