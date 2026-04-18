package game.wortwerk;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.attribute.PosixFilePermission;
import java.util.EnumSet;
import java.util.List;
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

    @Test
    void shouldUseValidTerraformInitFlagsForRuntimeStateMigration() throws IOException {
        String script = Files.readString(Path.of("infrastructure/oci/deploy.sh"), StandardCharsets.UTF_8);

        assertThat(script).contains("init -upgrade -migrate-state -force-copy");
        assertThat(script).doesNotContain("init -upgrade -reconfigure -migrate-state");
    }

    @Test
    void shouldResolveRuntimeBackendNamespaceFromOciInsideDevopsRunner() throws Exception {
        Path script = prepareTempRepo();
        Path repoRoot = script.getParent().getParent().getParent();
        Path binDir = Files.createDirectories(tempDir.resolve("bin"));
        Path backendConfigCapture = tempDir.resolve("backend-config.tfvars");
        Path commandLog = tempDir.resolve("commands.log");
        Path releaseVars = repoRoot.resolve("infrastructure/oci/runtime/release.auto.tfvars");

        Files.writeString(
                releaseVars,
                """
                image_tag = "test-image"
                image_registry_username = "ignored"
                image_registry_password = "ignored"
                """,
                StandardCharsets.UTF_8);

        writeExecutable(
                binDir.resolve("terraform"),
                """
                #!/usr/bin/env bash
                set -euo pipefail
                printf 'terraform %s\\n' "$*" >> "$COMMAND_LOG"
                if [[ "$1" == "-chdir="* ]]; then
                  shift
                fi

                if [[ "$1" == "init" ]]; then
                  for arg in "$@"; do
                    case "$arg" in
                      -backend-config=*)
                        cp "${arg#-backend-config=}" "$BACKEND_CONFIG_CAPTURE"
                        ;;
                    esac
                  done
                  exit 0
                fi

                if [[ "$1" == "state" && "$2" == "show" ]]; then
                  exit 1
                fi

                exit 0
                """);
        writeExecutable(
                binDir.resolve("oci"),
                """
                #!/usr/bin/env bash
                set -euo pipefail
                printf 'oci %s\\n' "$*" >> "$COMMAND_LOG"
                if [[ "$1" == "os" && "$2" == "ns" && "$3" == "get" ]]; then
                  printf 'test-namespace'
                  exit 0
                fi

                echo "unexpected oci invocation: $*" >&2
                exit 1
                """);

        ProcessResult result = runScript(
                script,
                "runtime",
                Map.ofEntries(
                        Map.entry("OCI_CLI_AUTH", "resource_principal"),
                        Map.entry("COMMAND_LOG", commandLog.toString()),
                        Map.entry("BACKEND_CONFIG_CAPTURE", backendConfigCapture.toString()),
                        Map.entry("PATH", binDir + ":" + System.getenv("PATH")),
                        Map.entry("REGION", "eu-frankfurt-1"),
                        Map.entry("TENANCY_OCID", "ocid1.tenancy.oc1..example"),
                        Map.entry("COMPARTMENT_OCID", "ocid1.compartment.oc1..example"),
                        Map.entry("RUNTIME_SUBNET_ID", "ocid1.subnet.oc1..runtime"),
                        Map.entry("LOAD_BALANCER_SUBNET_ID", "ocid1.subnet.oc1..lb"),
                        Map.entry("NSG_ID", "ocid1.nsg.oc1..runtime"),
                        Map.entry("LOAD_BALANCER_NSG_ID", "ocid1.nsg.oc1..lb"),
                        Map.entry("LOAD_BALANCER_PUBLIC_IP_ID", "ocid1.publicip.oc1..example"),
                        Map.entry("LOAD_BALANCER_PUBLIC_IP", "203.0.113.10"),
                        Map.entry("RUNTIME_DB_URL", "jdbc:postgresql://db.example/postgres"),
                        Map.entry("RUNTIME_DB_USERNAME", "wortwerk_app"),
                        Map.entry("RUNTIME_DB_PASSWORD_SECRET_OCID", "ocid1.vaultsecret.oc1..runtime"),
                        Map.entry("RUNTIME_DB_SSL_ROOT_CERT_BASE64", "dGVzdA=="),
                        Map.entry("TLS_PUBLIC_CERTIFICATE_SECRET_OCID", "ocid1.vaultsecret.oc1..tls-public"),
                        Map.entry("TLS_PRIVATE_KEY_SECRET_OCID", "ocid1.vaultsecret.oc1..tls-private"),
                        Map.entry("TLS_CA_CERTIFICATE_SECRET_OCID", "ocid1.vaultsecret.oc1..tls-ca"),
                        Map.entry("IMAGE_REPOSITORY", "fra.ocir.io/test/wortwerk"),
                        Map.entry("IMAGE_REGISTRY_ENDPOINT", "fra.ocir.io"),
                        Map.entry("APP_PORT", "8080"),
                        Map.entry("MANAGEMENT_PORT", "8081"),
                        Map.entry("LB_LISTENER_PORT", "80"),
                        Map.entry("HTTPS_LISTENER_PORT", "443"),
                        Map.entry("LOAD_BALANCER_MIN_BANDWIDTH_MBPS", "10"),
                        Map.entry("LOAD_BALANCER_MAX_BANDWIDTH_MBPS", "10"),
                        Map.entry("RUNTIME_STATE_BUCKET_NAME", "wortwerk-runtime-state"),
                        Map.entry("IMAGE_TAG", "test-image")));

        assertThat(result.exitCode()).isZero();
        assertThat(Files.readString(backendConfigCapture, StandardCharsets.UTF_8))
                .contains("namespace = \"test-namespace\"")
                .contains("bucket = \"wortwerk-runtime-state\"")
                .contains("auth = \"ResourcePrincipal\"");

        List<String> commands = Files.readAllLines(commandLog, StandardCharsets.UTF_8);
        assertThat(commands).anyMatch(command -> command.equals("oci os ns get --query data --raw-output"));
        assertThat(commands).noneMatch(command -> command.contains("output -raw ocir_namespace"));
    }

    @Test
    void shouldRejectMalformedOciNamespaceOutputBeforeWritingBackendConfig() throws Exception {
        Path script = prepareTempRepo();
        Path repoRoot = script.getParent().getParent().getParent();
        Path binDir = Files.createDirectories(tempDir.resolve("bin"));
        Path backendConfigCapture = tempDir.resolve("backend-config.tfvars");
        Path commandLog = tempDir.resolve("commands.log");
        Path releaseVars = repoRoot.resolve("infrastructure/oci/runtime/release.auto.tfvars");

        Files.writeString(
                releaseVars,
                """
                image_tag = "test-image"
                image_registry_username = "ignored"
                image_registry_password = "ignored"
                """,
                StandardCharsets.UTF_8);

        writeExecutable(
                binDir.resolve("terraform"),
                """
                #!/usr/bin/env bash
                set -euo pipefail
                printf 'terraform %s\\n' "$*" >> "$COMMAND_LOG"
                if [[ "$1" == "-chdir="* ]]; then
                  shift
                fi
                if [[ "$1" == "state" && "$2" == "show" ]]; then
                  exit 1
                fi
                exit 0
                """);
        writeExecutable(
                binDir.resolve("oci"),
                """
                #!/usr/bin/env bash
                set -euo pipefail
                printf 'oci %s\\n' "$*" >> "$COMMAND_LOG"
                if [[ "$1" == "os" && "$2" == "ns" && "$3" == "get" ]]; then
                  printf 'Warning: No outputs found\\n'
                  exit 0
                fi

                echo "unexpected oci invocation: $*" >&2
                exit 1
                """);

        ProcessResult result = runScript(
                script,
                "runtime",
                Map.ofEntries(
                        Map.entry("OCI_CLI_AUTH", "resource_principal"),
                        Map.entry("COMMAND_LOG", commandLog.toString()),
                        Map.entry("BACKEND_CONFIG_CAPTURE", backendConfigCapture.toString()),
                        Map.entry("PATH", binDir + ":" + System.getenv("PATH")),
                        Map.entry("REGION", "eu-frankfurt-1"),
                        Map.entry("TENANCY_OCID", "ocid1.tenancy.oc1..example"),
                        Map.entry("COMPARTMENT_OCID", "ocid1.compartment.oc1..example"),
                        Map.entry("RUNTIME_SUBNET_ID", "ocid1.subnet.oc1..runtime"),
                        Map.entry("LOAD_BALANCER_SUBNET_ID", "ocid1.subnet.oc1..lb"),
                        Map.entry("NSG_ID", "ocid1.nsg.oc1..runtime"),
                        Map.entry("LOAD_BALANCER_NSG_ID", "ocid1.nsg.oc1..lb"),
                        Map.entry("LOAD_BALANCER_PUBLIC_IP_ID", "ocid1.publicip.oc1..example"),
                        Map.entry("LOAD_BALANCER_PUBLIC_IP", "203.0.113.10"),
                        Map.entry("RUNTIME_DB_URL", "jdbc:postgresql://db.example/postgres"),
                        Map.entry("RUNTIME_DB_USERNAME", "wortwerk_app"),
                        Map.entry("RUNTIME_DB_PASSWORD_SECRET_OCID", "ocid1.vaultsecret.oc1..runtime"),
                        Map.entry("RUNTIME_DB_SSL_ROOT_CERT_BASE64", "dGVzdA=="),
                        Map.entry("TLS_PUBLIC_CERTIFICATE_SECRET_OCID", "ocid1.vaultsecret.oc1..tls-public"),
                        Map.entry("TLS_PRIVATE_KEY_SECRET_OCID", "ocid1.vaultsecret.oc1..tls-private"),
                        Map.entry("TLS_CA_CERTIFICATE_SECRET_OCID", "ocid1.vaultsecret.oc1..tls-ca"),
                        Map.entry("IMAGE_REPOSITORY", "fra.ocir.io/test/wortwerk"),
                        Map.entry("IMAGE_REGISTRY_ENDPOINT", "fra.ocir.io"),
                        Map.entry("APP_PORT", "8080"),
                        Map.entry("MANAGEMENT_PORT", "8081"),
                        Map.entry("LB_LISTENER_PORT", "80"),
                        Map.entry("HTTPS_LISTENER_PORT", "443"),
                        Map.entry("LOAD_BALANCER_MIN_BANDWIDTH_MBPS", "10"),
                        Map.entry("LOAD_BALANCER_MAX_BANDWIDTH_MBPS", "10"),
                        Map.entry("RUNTIME_STATE_BUCKET_NAME", "wortwerk-runtime-state"),
                        Map.entry("IMAGE_TAG", "test-image")));

        assertThat(result.exitCode()).isNotZero();
        assertThat(result.stderr()).contains("Unable to resolve a valid Object Storage namespace from OCI while running under resource principal.");
        assertThat(backendConfigCapture).doesNotExist();

        List<String> commands = Files.readAllLines(commandLog, StandardCharsets.UTF_8);
        assertThat(commands).anyMatch(command -> command.equals("oci os ns get --query data --raw-output"));
        assertThat(commands).noneMatch(command -> command.contains("output -raw ocir_namespace"));
    }

    @Test
    void shouldImportExistingLoadBalancerResourcesBeforeRuntimeApplyWhenStateDrifted() throws Exception {
        Path script = prepareTempRepo();
        Path repoRoot = script.getParent().getParent().getParent();
        Path binDir = Files.createDirectories(tempDir.resolve("bin"));
        Path commandLog = tempDir.resolve("commands.log");
        Path releaseVars = repoRoot.resolve("infrastructure/oci/runtime/release.auto.tfvars");

        Files.writeString(
                releaseVars,
                """
                image_tag = "test-image"
                image_registry_username = "ignored"
                image_registry_password = "ignored"
                """,
                StandardCharsets.UTF_8);

        writeExecutable(
                binDir.resolve("terraform"),
                """
                #!/usr/bin/env bash
                set -euo pipefail
                printf 'terraform %s\\n' "$*" >> "$COMMAND_LOG"
                if [[ "$1" == "-chdir="* ]]; then
                  shift
                fi

                case "$1" in
                  init|fmt|apply)
                    exit 0
                    ;;
                  state)
                    if [[ "$2" == "show" ]]; then
                      case "$4" in
                        oci_container_instances_container_instance.wort_werk)
                          printf 'resource "oci_container_instances_container_instance" "wort_werk" {}'
                          exit 0
                          ;;
                        oci_load_balancer_load_balancer.wort_werk)
                          printf 'resource "oci_load_balancer_load_balancer" "wort_werk" {}'
                          exit 0
                          ;;
                      esac
                      exit 1
                    fi
                    if [[ "$2" == "list" ]]; then
                      printf '%s\\n' \
                        'data.oci_identity_availability_domains.this' \
                        'data.oci_secrets_secretbundle.tls_private_key' \
                        'data.oci_secrets_secretbundle.tls_public_certificate' \
                        'oci_container_instances_container_instance.wort_werk' \
                        'oci_load_balancer_load_balancer.wort_werk'
                      exit 0
                    fi
                    ;;
                  output)
                    if [[ "$2" == "-raw" && "$3" == "load_balancer_id" ]]; then
                      printf 'ocid1.loadbalancer.oc1..existing'
                      exit 0
                    fi
                    ;;
                  import)
                    [[ -f runtime/foundation.auto.tfvars ]] || { echo "missing runtime tfvars before import" >&2; exit 1; }
                    [[ -f runtime/release.auto.tfvars ]] || { echo "missing release vars before import" >&2; exit 1; }
                    exit 0
                    ;;
                esac

                echo "unexpected terraform invocation: $*" >&2
                exit 1
                """);
        writeExecutable(
                binDir.resolve("oci"),
                """
                #!/usr/bin/env bash
                set -euo pipefail
                printf 'oci %s\\n' "$*" >> "$COMMAND_LOG"
                if [[ "$1" == "os" && "$2" == "ns" && "$3" == "get" ]]; then
                  printf 'test-namespace'
                  exit 0
                fi

                if [[ "$1" == "lb" && "$2" == "load-balancer" && "$3" == "get" ]]; then
                  printf '10.10.3.112:8080'
                  exit 0
                fi

                if [[ "$1" == "lb" && "$2" == "certificate" && "$3" == "list" ]]; then
                  printf 'true'
                  exit 0
                fi

                echo "unexpected oci invocation: $*" >&2
                exit 1
                """);

        ProcessResult result = runScript(
                script,
                "runtime",
                Map.ofEntries(
                        Map.entry("OCI_CLI_AUTH", "resource_principal"),
                        Map.entry("COMMAND_LOG", commandLog.toString()),
                        Map.entry("PATH", binDir + ":" + System.getenv("PATH")),
                        Map.entry("REGION", "eu-frankfurt-1"),
                        Map.entry("TENANCY_OCID", "ocid1.tenancy.oc1..example"),
                        Map.entry("COMPARTMENT_OCID", "ocid1.compartment.oc1..example"),
                        Map.entry("RUNTIME_SUBNET_ID", "ocid1.subnet.oc1..runtime"),
                        Map.entry("LOAD_BALANCER_SUBNET_ID", "ocid1.subnet.oc1..lb"),
                        Map.entry("NSG_ID", "ocid1.nsg.oc1..runtime"),
                        Map.entry("LOAD_BALANCER_NSG_ID", "ocid1.nsg.oc1..lb"),
                        Map.entry("LOAD_BALANCER_PUBLIC_IP_ID", "ocid1.publicip.oc1..example"),
                        Map.entry("LOAD_BALANCER_PUBLIC_IP", "203.0.113.10"),
                        Map.entry("RUNTIME_DB_URL", "jdbc:postgresql://db.example/postgres"),
                        Map.entry("RUNTIME_DB_USERNAME", "wortwerk_app"),
                        Map.entry("RUNTIME_DB_PASSWORD_SECRET_OCID", "ocid1.vaultsecret.oc1..runtime"),
                        Map.entry("RUNTIME_DB_SSL_ROOT_CERT_BASE64", "dGVzdA=="),
                        Map.entry("TLS_PUBLIC_CERTIFICATE_SECRET_OCID", "ocid1.vaultsecret.oc1..tls-public"),
                        Map.entry("TLS_PRIVATE_KEY_SECRET_OCID", "ocid1.vaultsecret.oc1..tls-private"),
                        Map.entry("TLS_CA_CERTIFICATE_SECRET_OCID", "ocid1.vaultsecret.oc1..tls-ca"),
                        Map.entry("IMAGE_REPOSITORY", "fra.ocir.io/test/wortwerk"),
                        Map.entry("IMAGE_REGISTRY_ENDPOINT", "fra.ocir.io"),
                        Map.entry("APP_PORT", "8080"),
                        Map.entry("MANAGEMENT_PORT", "8081"),
                        Map.entry("LB_LISTENER_PORT", "80"),
                        Map.entry("HTTPS_LISTENER_PORT", "443"),
                        Map.entry("LOAD_BALANCER_MIN_BANDWIDTH_MBPS", "10"),
                        Map.entry("LOAD_BALANCER_MAX_BANDWIDTH_MBPS", "10"),
                        Map.entry("RUNTIME_STATE_BUCKET_NAME", "wortwerk-runtime-state"),
                        Map.entry("IMAGE_TAG", "test-image")));

        assertThat(result.exitCode())
                .withFailMessage("stdout=%s%nstderr=%s", result.stdout(), result.stderr())
                .isZero();

        List<String> commands = Files.readAllLines(commandLog, StandardCharsets.UTF_8);
        assertThat(commands).anyMatch(command -> command.contains("output -raw load_balancer_id"));
        assertThat(commands).anyMatch(command -> command.contains("oci lb load-balancer get --load-balancer-id ocid1.loadbalancer.oc1..existing"));
        assertThat(commands).noneMatch(command -> command.contains("import -input=false oci_load_balancer_load_balancer.wort_werk ocid1.loadbalancer.oc1..existing"));
        assertThat(commands).anyMatch(command -> command.contains("import -input=false oci_load_balancer_backend_set.wort_werk loadBalancers/ocid1.loadbalancer.oc1..existing/backendSets/wort-werk-backend-set"));
        assertThat(commands).anyMatch(command -> command.contains("import -input=false oci_load_balancer_backend.wort_werk loadBalancers/ocid1.loadbalancer.oc1..existing/backendSets/wort-werk-backend-set/backends/10.10.3.112:8080"));
        assertThat(commands).anyMatch(command -> command.contains("import -input=false oci_load_balancer_listener.http loadBalancers/ocid1.loadbalancer.oc1..existing/listeners/http"));
        assertThat(commands).anyMatch(command -> command.contains("import -input=false oci_load_balancer_listener.https loadBalancers/ocid1.loadbalancer.oc1..existing/listeners/https"));
        assertThat(commands).anyMatch(command -> command.contains("import -input=false oci_load_balancer_certificate.wort_werk_tls loadBalancers/ocid1.loadbalancer.oc1..existing/certificates/wortwerk_xyz_terraform"));
        assertThat(commands).anyMatch(command -> command.contains("import -input=false oci_load_balancer_rule_set.http_to_https loadBalancers/ocid1.loadbalancer.oc1..existing/ruleSets/http_to_https"));
        assertThat(commands).anyMatch(command -> command.endsWith("fmt"));
        assertThat(commands).anyMatch(command -> command.endsWith("apply -auto-approve -input=false"));
    }

    @Test
    void shouldSkipImportForIngressChildrenThatNoLongerExistRemotely() throws Exception {
        Path script = prepareTempRepo();
        Path repoRoot = script.getParent().getParent().getParent();
        Path binDir = Files.createDirectories(tempDir.resolve("bin"));
        Path commandLog = tempDir.resolve("commands.log");
        Path releaseVars = repoRoot.resolve("infrastructure/oci/runtime/release.auto.tfvars");

        Files.writeString(
                releaseVars,
                """
                image_tag = "test-image"
                image_registry_username = "ignored"
                image_registry_password = "ignored"
                """,
                StandardCharsets.UTF_8);

        writeExecutable(
                binDir.resolve("terraform"),
                """
                #!/usr/bin/env bash
                set -euo pipefail
                printf 'terraform %s\\n' "$*" >> "$COMMAND_LOG"
                if [[ "$1" == "-chdir="* ]]; then
                  shift
                fi

                case "$1" in
                  init|fmt|apply)
                    exit 0
                    ;;
                  state)
                    if [[ "$2" == "show" ]]; then
                      case "$4" in
                        oci_container_instances_container_instance.wort_werk)
                          printf 'resource "oci_container_instances_container_instance" "wort_werk" {}'
                          exit 0
                          ;;
                        oci_load_balancer_load_balancer.wort_werk)
                          printf 'resource "oci_load_balancer_load_balancer" "wort_werk" {}'
                          exit 0
                          ;;
                      esac
                      exit 1
                    fi
                    if [[ "$2" == "list" ]]; then
                      printf '%s\\n' \
                        'data.oci_identity_availability_domains.this' \
                        'data.oci_secrets_secretbundle.tls_private_key' \
                        'data.oci_secrets_secretbundle.tls_public_certificate' \
                        'oci_container_instances_container_instance.wort_werk' \
                        'oci_load_balancer_load_balancer.wort_werk'
                      exit 0
                    fi
                    ;;
                  output)
                    if [[ "$2" == "-raw" && "$3" == "load_balancer_id" ]]; then
                      printf 'ocid1.loadbalancer.oc1..existing'
                      exit 0
                    fi
                    ;;
                  import)
                    exit 0
                    ;;
                esac

                echo "unexpected terraform invocation: $*" >&2
                exit 1
                """);
        writeExecutable(
                binDir.resolve("oci"),
                """
                #!/usr/bin/env bash
                set -euo pipefail
                printf 'oci %s\\n' "$*" >> "$COMMAND_LOG"
                if [[ "$1" == "os" && "$2" == "ns" && "$3" == "get" ]]; then
                  printf 'test-namespace'
                  exit 0
                fi

                if [[ "$1" == "lb" && "$2" == "load-balancer" && "$3" == "get" ]]; then
                  if [[ "$*" == *'data."backend-sets"."wort-werk-backend-set".backends[0].name'* ]]; then
                    printf '10.10.3.112:8080'
                    exit 0
                  fi

                  if [[ "$*" == *'data.listeners."http"'* ]] || [[ "$*" == *'data.listeners."https"'* ]] || [[ "$*" == *'data."rule-sets"."http_to_https"'* ]]; then
                    exit 0
                  fi

                  printf '{}'
                  exit 0
                fi

                if [[ "$1" == "lb" && "$2" == "certificate" && "$3" == "list" ]]; then
                  printf 'false'
                  exit 0
                fi

                echo "unexpected oci invocation: $*" >&2
                exit 1
                """);

        ProcessResult result = runScript(
                script,
                "runtime",
                Map.ofEntries(
                        Map.entry("OCI_CLI_AUTH", "resource_principal"),
                        Map.entry("COMMAND_LOG", commandLog.toString()),
                        Map.entry("PATH", binDir + ":" + System.getenv("PATH")),
                        Map.entry("REGION", "eu-frankfurt-1"),
                        Map.entry("TENANCY_OCID", "ocid1.tenancy.oc1..example"),
                        Map.entry("COMPARTMENT_OCID", "ocid1.compartment.oc1..example"),
                        Map.entry("RUNTIME_SUBNET_ID", "ocid1.subnet.oc1..runtime"),
                        Map.entry("LOAD_BALANCER_SUBNET_ID", "ocid1.subnet.oc1..lb"),
                        Map.entry("NSG_ID", "ocid1.nsg.oc1..runtime"),
                        Map.entry("LOAD_BALANCER_NSG_ID", "ocid1.nsg.oc1..lb"),
                        Map.entry("LOAD_BALANCER_PUBLIC_IP_ID", "ocid1.publicip.oc1..example"),
                        Map.entry("LOAD_BALANCER_PUBLIC_IP", "203.0.113.10"),
                        Map.entry("RUNTIME_DB_URL", "jdbc:postgresql://db.example/postgres"),
                        Map.entry("RUNTIME_DB_USERNAME", "wortwerk_app"),
                        Map.entry("RUNTIME_DB_PASSWORD_SECRET_OCID", "ocid1.vaultsecret.oc1..runtime"),
                        Map.entry("RUNTIME_DB_SSL_ROOT_CERT_BASE64", "dGVzdA=="),
                        Map.entry("TLS_PUBLIC_CERTIFICATE_SECRET_OCID", "ocid1.vaultsecret.oc1..tls-public"),
                        Map.entry("TLS_PRIVATE_KEY_SECRET_OCID", "ocid1.vaultsecret.oc1..tls-private"),
                        Map.entry("TLS_CA_CERTIFICATE_SECRET_OCID", "ocid1.vaultsecret.oc1..tls-ca"),
                        Map.entry("IMAGE_REPOSITORY", "fra.ocir.io/test/wortwerk"),
                        Map.entry("IMAGE_REGISTRY_ENDPOINT", "fra.ocir.io"),
                        Map.entry("APP_PORT", "8080"),
                        Map.entry("MANAGEMENT_PORT", "8081"),
                        Map.entry("LB_LISTENER_PORT", "80"),
                        Map.entry("HTTPS_LISTENER_PORT", "443"),
                        Map.entry("LOAD_BALANCER_MIN_BANDWIDTH_MBPS", "10"),
                        Map.entry("LOAD_BALANCER_MAX_BANDWIDTH_MBPS", "10"),
                        Map.entry("RUNTIME_STATE_BUCKET_NAME", "wortwerk-runtime-state"),
                        Map.entry("IMAGE_TAG", "test-image")));

        assertThat(result.exitCode())
                .withFailMessage("stdout=%s%nstderr=%s", result.stdout(), result.stderr())
                .isZero();

        List<String> commands = Files.readAllLines(commandLog, StandardCharsets.UTF_8);
        assertThat(commands).noneMatch(command -> command.contains("import -input=false oci_load_balancer_listener.http"));
        assertThat(commands).noneMatch(command -> command.contains("import -input=false oci_load_balancer_listener.https"));
        assertThat(commands).noneMatch(command -> command.contains("import -input=false oci_load_balancer_certificate.wort_werk_tls"));
        assertThat(commands).noneMatch(command -> command.contains("import -input=false oci_load_balancer_rule_set.http_to_https"));
        assertThat(commands).anyMatch(command -> command.contains("import -input=false oci_load_balancer_backend_set.wort_werk"));
        assertThat(commands).anyMatch(command -> command.contains("import -input=false oci_load_balancer_backend.wort_werk"));
        assertThat(commands).anyMatch(command -> command.endsWith("apply -auto-approve -input=false"));
    }

    @Test
    void shouldTreatAlreadyManagedTerraformImportAsIdempotentDuringRuntimeStateRepair() throws Exception {
        Path script = prepareTempRepo();
        Path repoRoot = script.getParent().getParent().getParent();
        Path binDir = Files.createDirectories(tempDir.resolve("bin"));
        Path commandLog = tempDir.resolve("commands.log");
        Path releaseVars = repoRoot.resolve("infrastructure/oci/runtime/release.auto.tfvars");

        Files.writeString(
                releaseVars,
                """
                image_tag = "test-image"
                image_registry_username = "ignored"
                image_registry_password = "ignored"
                """,
                StandardCharsets.UTF_8);

        writeExecutable(
                binDir.resolve("terraform"),
                """
                #!/usr/bin/env bash
                set -euo pipefail
                printf 'terraform %s\\n' "$*" >> "$COMMAND_LOG"
                if [[ "$1" == "-chdir="* ]]; then
                  shift
                fi

                case "$1" in
                  init|fmt|apply)
                    exit 0
                    ;;
                  state)
                    if [[ "$2" == "show" ]]; then
                      case "$4" in
                        oci_container_instances_container_instance.wort_werk)
                          printf 'resource "oci_container_instances_container_instance" "wort_werk" {}'
                          exit 0
                          ;;
                        oci_load_balancer_load_balancer.wort_werk)
                          printf 'resource "oci_load_balancer_load_balancer" "wort_werk" {}'
                          exit 0
                          ;;
                        oci_load_balancer_backend_set.wort_werk)
                          printf 'resource "oci_load_balancer_backend_set" "wort_werk" {}'
                          exit 0
                          ;;
                      esac
                      exit 1
                    fi
                    if [[ "$2" == "list" ]]; then
                      printf '%s\\n' \
                        'data.oci_identity_availability_domains.this' \
                        'data.oci_secrets_secretbundle.tls_private_key' \
                        'data.oci_secrets_secretbundle.tls_public_certificate' \
                        'oci_container_instances_container_instance.wort_werk' \
                        'oci_load_balancer_load_balancer.wort_werk' \
                        'oci_load_balancer_backend_set.wort_werk'
                      exit 0
                    fi
                    ;;
                  output)
                    if [[ "$2" == "-raw" && "$3" == "load_balancer_id" ]]; then
                      printf 'ocid1.loadbalancer.oc1..existing'
                      exit 0
                    fi
                    ;;
                  import)
                    if [[ "$3" == oci_load_balancer_backend.wort_werk ]]; then
                      cat >&2 <<'EOF'
Error: Resource already managed by Terraform

Terraform is already managing a remote object for
oci_load_balancer_backend.wort_werk. To import to this address you must
first remove the existing object from the state.
EOF
                      exit 1
                    fi
                    exit 0
                    ;;
                esac

                echo "unexpected terraform invocation: $*" >&2
                exit 1
                """);
        writeExecutable(
                binDir.resolve("oci"),
                """
                #!/usr/bin/env bash
                set -euo pipefail
                printf 'oci %s\\n' "$*" >> "$COMMAND_LOG"
                if [[ "$1" == "os" && "$2" == "ns" && "$3" == "get" ]]; then
                  printf 'test-namespace'
                  exit 0
                fi

                if [[ "$1" == "lb" && "$2" == "load-balancer" && "$3" == "get" ]]; then
                  printf '10.10.3.112:8080'
                  exit 0
                fi

                if [[ "$1" == "lb" && "$2" == "certificate" && "$3" == "list" ]]; then
                  printf 'true'
                  exit 0
                fi

                echo "unexpected oci invocation: $*" >&2
                exit 1
                """);

        ProcessResult result = runScript(
                script,
                "runtime",
                Map.ofEntries(
                        Map.entry("OCI_CLI_AUTH", "resource_principal"),
                        Map.entry("COMMAND_LOG", commandLog.toString()),
                        Map.entry("PATH", binDir + ":" + System.getenv("PATH")),
                        Map.entry("REGION", "eu-frankfurt-1"),
                        Map.entry("TENANCY_OCID", "ocid1.tenancy.oc1..example"),
                        Map.entry("COMPARTMENT_OCID", "ocid1.compartment.oc1..example"),
                        Map.entry("RUNTIME_SUBNET_ID", "ocid1.subnet.oc1..runtime"),
                        Map.entry("LOAD_BALANCER_SUBNET_ID", "ocid1.subnet.oc1..lb"),
                        Map.entry("NSG_ID", "ocid1.nsg.oc1..runtime"),
                        Map.entry("LOAD_BALANCER_NSG_ID", "ocid1.nsg.oc1..lb"),
                        Map.entry("LOAD_BALANCER_PUBLIC_IP_ID", "ocid1.publicip.oc1..example"),
                        Map.entry("LOAD_BALANCER_PUBLIC_IP", "203.0.113.10"),
                        Map.entry("RUNTIME_DB_URL", "jdbc:postgresql://db.example/postgres"),
                        Map.entry("RUNTIME_DB_USERNAME", "wortwerk_app"),
                        Map.entry("RUNTIME_DB_PASSWORD_SECRET_OCID", "ocid1.vaultsecret.oc1..runtime"),
                        Map.entry("RUNTIME_DB_SSL_ROOT_CERT_BASE64", "dGVzdA=="),
                        Map.entry("TLS_PUBLIC_CERTIFICATE_SECRET_OCID", "ocid1.vaultsecret.oc1..tls-public"),
                        Map.entry("TLS_PRIVATE_KEY_SECRET_OCID", "ocid1.vaultsecret.oc1..tls-private"),
                        Map.entry("TLS_CA_CERTIFICATE_SECRET_OCID", "ocid1.vaultsecret.oc1..tls-ca"),
                        Map.entry("IMAGE_REPOSITORY", "fra.ocir.io/test/wortwerk"),
                        Map.entry("IMAGE_REGISTRY_ENDPOINT", "fra.ocir.io"),
                        Map.entry("APP_PORT", "8080"),
                        Map.entry("MANAGEMENT_PORT", "8081"),
                        Map.entry("LB_LISTENER_PORT", "80"),
                        Map.entry("HTTPS_LISTENER_PORT", "443"),
                        Map.entry("LOAD_BALANCER_MIN_BANDWIDTH_MBPS", "10"),
                        Map.entry("LOAD_BALANCER_MAX_BANDWIDTH_MBPS", "10"),
                        Map.entry("RUNTIME_STATE_BUCKET_NAME", "wortwerk-runtime-state"),
                        Map.entry("IMAGE_TAG", "test-image")));

        assertThat(result.exitCode())
                .withFailMessage("stdout=%s%nstderr=%s", result.stdout(), result.stderr())
                .isZero();

        List<String> commands = Files.readAllLines(commandLog, StandardCharsets.UTF_8);
        assertThat(commands).anyMatch(command -> command.contains("import -input=false oci_load_balancer_backend.wort_werk"));
        assertThat(commands).anyMatch(command -> command.endsWith("apply -auto-approve -input=false"));
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

    private void writeExecutable(Path path, String content) throws IOException {
        Files.writeString(path, content, StandardCharsets.UTF_8);
        setExecutable(path);
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
