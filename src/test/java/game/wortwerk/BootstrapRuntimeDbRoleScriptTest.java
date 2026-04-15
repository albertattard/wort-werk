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

class BootstrapRuntimeDbRoleScriptTest {

    @TempDir
    Path tempDir;

    @Test
    void shouldProvisionDedicatedRuntimeRoleFromVaultSecrets() throws Exception {
        TestHarness harness = prepareHarness();

        ProcessResult result = runScript(harness, Map.of());

        assertThat(result.exitCode())
                .withFailMessage("stdout=%s%nstderr=%s", result.stdout(), result.stderr())
                .isZero();

        String psqlArgs = Files.readString(harness.psqlArgsCaptureFile(), StandardCharsets.UTF_8);
        String psqlInput = Files.readString(harness.psqlInputCaptureFile(), StandardCharsets.UTF_8);

        assertThat(psqlArgs).contains("--host=db.internal.example");
        assertThat(psqlArgs).contains("--port=5432");
        assertThat(psqlArgs).contains("--username=wortwerk_admin");
        assertThat(psqlArgs).contains("--dbname=postgres");
        assertThat(psqlArgs).contains("--set=runtime_db_username=wortwerk_app");
        assertThat(psqlArgs).doesNotContain("runtime-secret");
        assertThat(psqlArgs).doesNotContain("runtime_db_password");

        assertThat(psqlInput).contains("GRANT CONNECT, TEMPORARY ON DATABASE");
        assertThat(psqlInput).contains("GRANT USAGE, CREATE ON SCHEMA public");
        assertThat(psqlInput).contains("ALTER TABLE");
        assertThat(psqlInput).contains("ALTER SEQUENCE");
        assertThat(psqlInput).doesNotContain("\\getenv");
        assertThat(psqlInput).contains("\\set runtime_db_password_base64 'cnVudGltZS1zZWNyZXQ='");
        assertThat(psqlInput).contains("SELECT CASE");
        assertThat(psqlInput).contains("convert_from(decode(:'runtime_db_password_base64', 'base64'), 'utf8')");
        assertThat(psqlInput).doesNotContain("DO $bootstrap$");
    }

    @Test
    void shouldAcceptRuntimeCertificateEnvironmentVariableAlias() throws Exception {
        TestHarness harness = prepareHarness();

        ProcessResult result = runScript(harness, Map.of(
                "RUNTIME_DB_SSL_ROOT_CERT_BASE64", "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCg=="));

        assertThat(result.exitCode())
                .withFailMessage("stdout=%s%nstderr=%s", result.stdout(), result.stderr())
                .isZero();
    }

    private TestHarness prepareHarness() throws IOException {
        Path repoRoot = tempDir.resolve("repo");
        Path dataDir = Files.createDirectories(repoRoot.resolve("infrastructure/oci/data"));
        Files.createDirectories(repoRoot.resolve("infrastructure/oci/foundation"));
        Path binDir = Files.createDirectories(tempDir.resolve("bin"));

        Path scriptCopy = dataDir.resolve("bootstrap-runtime-db-role.sh");
        Files.writeString(
                scriptCopy,
                Files.readString(Path.of("infrastructure/oci/data/bootstrap-runtime-db-role.sh"), StandardCharsets.UTF_8),
                StandardCharsets.UTF_8);
        setExecutable(scriptCopy);

        Files.writeString(
                dataDir.resolve("terraform.tfvars"),
                """
                postgresql_admin_password_secret_ocid = "ocid1.secret.oc1..admin"
                runtime_db_password_secret_ocid = "ocid1.secret.oc1..runtime"
                runtime_db_username = "wortwerk_app"
                """,
                StandardCharsets.UTF_8);

        Path terraformStub = binDir.resolve("terraform");
        Files.writeString(
                terraformStub,
                """
                #!/usr/bin/env bash
                set -euo pipefail

                case "${*: -1}" in
                  postgresql_fqdn) printf '%s' 'db.internal.example' ;;
                  postgresql_port) printf '%s' '5432' ;;
                  postgresql_database_name) printf '%s' 'postgres' ;;
                  runtime_db_ssl_root_cert_base64) printf '%s' 'LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCg==' ;;
                  *) echo "unexpected terraform args: $*" >&2; exit 1 ;;
                esac
                """,
                StandardCharsets.UTF_8);
        setExecutable(terraformStub);

        Path ociStub = binDir.resolve("oci");
        Files.writeString(
                ociStub,
                """
                #!/usr/bin/env bash
                set -euo pipefail

                secret_id=''
                while (($#)); do
                  case "$1" in
                    --secret-id)
                      secret_id="$2"
                      shift 2
                      ;;
                    *)
                      shift
                      ;;
                  esac
                done

                case "${secret_id}" in
                  ocid1.secret.oc1..admin) printf '%s' 'YWRtaW4tc2VjcmV0' ;;
                  ocid1.secret.oc1..runtime) printf '%s' 'cnVudGltZS1zZWNyZXQ=' ;;
                  *) echo "unexpected secret id: ${secret_id}" >&2; exit 1 ;;
                esac
                """,
                StandardCharsets.UTF_8);
        setExecutable(ociStub);

        Path psqlArgsCaptureFile = tempDir.resolve("psql-args.txt");
        Path psqlInputCaptureFile = tempDir.resolve("psql-input.sql");
        Path psqlStub = binDir.resolve("psql");
        Files.writeString(
                psqlStub,
                """
                #!/usr/bin/env bash
                set -euo pipefail

                printf '%s\n' "$*" > "${PSQL_ARGS_CAPTURE_FILE:?}"
                cat > "${PSQL_INPUT_CAPTURE_FILE:?}"
                """,
                StandardCharsets.UTF_8);
        setExecutable(psqlStub);

        return new TestHarness(scriptCopy, binDir, psqlArgsCaptureFile, psqlInputCaptureFile);
    }

    private ProcessResult runScript(TestHarness harness, Map<String, String> extraEnvironment) throws Exception {
        ProcessBuilder processBuilder = new ProcessBuilder("bash", harness.script().toString());
        processBuilder.directory(harness.script().getParent().toFile());

        Map<String, String> environment = processBuilder.environment();
        environment.put("PATH", harness.binDir() + ":" + environment.get("PATH"));
        environment.put("PSQL_ARGS_CAPTURE_FILE", harness.psqlArgsCaptureFile().toString());
        environment.put("PSQL_INPUT_CAPTURE_FILE", harness.psqlInputCaptureFile().toString());
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

    private record TestHarness(Path script, Path binDir, Path psqlArgsCaptureFile, Path psqlInputCaptureFile) {
    }

    private record ProcessResult(int exitCode, String stdout, String stderr) {
    }
}
