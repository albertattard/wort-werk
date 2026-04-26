package game.wortwerk;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.assertj.core.api.Assertions.assertThat;

class OkeBlueGreenDeployScriptTest {

    @Test
    void shouldKeepPreviousSlotUntilPostSwitchObservationPasses() throws IOException {
        String buildSpec = read("infrastructure/oci/oke-devops/build_spec.yaml");
        String script = read("infrastructure/oci/oke-devops/deploy-bluegreen.sh");
        String commandSpec = read("infrastructure/oci/oke-devops/command_spec.yaml");
        String variables = read("infrastructure/oci/oke-devops/variables.tf");
        String terraform = read("infrastructure/oci/oke-devops/main.tf");

        assertThat(buildSpec).contains("mesa-libgbm");
        assertThat(buildSpec).contains("libX11-xcb");
        assertThat(buildSpec).contains("--file container/Dockerfile");
        assertThat(buildSpec).contains("docker push \"$APP_IMAGE\"");
        assertThat(script).contains("POST_SWITCH_OBSERVATION_SECONDS=\"${POST_SWITCH_OBSERVATION_SECONDS:-120}\"");
        assertThat(script).contains("POST_SWITCH_OBSERVATION_INTERVAL_SECONDS");
        assertThat(script).contains("APP_RESOLVE_IP");
        assertThat(script).contains("curl_args+=(--resolve");
        assertThat(script).contains("oci psql connection-details get");
        assertThat(script).contains("POSTGRESQL_DB_SYSTEM_ID");
        assertThat(script).contains("TLS_PUBLIC_CERTIFICATE_SECRET_OCID");
        assertThat(script).contains("TLS_PRIVATE_KEY_SECRET_OCID");
        assertThat(script).contains("\"${TLS_CA_CERTIFICATE_SECRET_OCID}\" != \"none\"");
        assertThat(script).contains("kubectl create secret tls wortwerk-tls");
        assertThat(script).contains("observe_public_endpoint");
        assertThat(script).contains("rollback_after_failed_observation \"$TARGET_SLOT\" \"$PREVIOUS_SLOT\"");
        assertThat(script).contains("apply_active_service \"$previous_slot\"");
        assertThat(script).contains("stop_slot \"$failed_slot\"");
        assertThat(script.indexOf("if ! observe_public_endpoint; then"))
                .isLessThan(script.indexOf("stop_slot \"$PREVIOUS_SLOT\""));

        assertThat(commandSpec).contains("POST_SWITCH_OBSERVATION_SECONDS: \"${postSwitchObservationSeconds}\"");
        assertThat(commandSpec).contains("POST_SWITCH_OBSERVATION_INTERVAL_SECONDS: \"${postSwitchObservationIntervalSeconds}\"");
        assertThat(commandSpec).contains("APP_RESOLVE_IP: \"${appResolveIp}\"");
        assertThat(commandSpec).contains("COMMIT_SHA: \"${COMMIT_SHA}\"");
        assertThat(commandSpec).contains("git -C \"$WORKDIR\" fetch --depth 1 origin \"$COMMIT_SHA\"");
        assertThat(commandSpec).contains("POSTGRESQL_DB_SYSTEM_ID: \"${postgresqlDbSystemId}\"");
        assertThat(commandSpec).contains("TLS_PUBLIC_CERTIFICATE_SECRET_OCID: \"${tlsPublicCertificateSecretOcid}\"");
        assertThat(commandSpec).contains("TLS_PRIVATE_KEY_SECRET_OCID: \"${tlsPrivateKeySecretOcid}\"");
        assertThat(commandSpec).contains("TLS_CA_CERTIFICATE_SECRET_OCID: \"${tlsCaCertificateSecretOcid}\"");
        assertThat(variables).contains("variable \"post_switch_observation_seconds\"");
        assertThat(variables).contains("variable \"postgresql_db_system_id\"");
        assertThat(variables).contains("variable \"app_resolve_ip\"");
        assertThat(variables).contains("variable \"tls_public_certificate_secret_ocid\"");
        assertThat(variables).contains("variable \"tls_private_key_secret_ocid\"");
        assertThat(variables).contains("variable \"tls_ca_certificate_secret_ocid\"");
        assertThat(variables).contains("default     = 120");
        assertThat(terraform).contains("name          = \"postSwitchObservationSeconds\"");
        assertThat(terraform).contains("name          = \"postSwitchObservationIntervalSeconds\"");
        assertThat(terraform).contains("name          = \"postgresqlDbSystemId\"");
        assertThat(terraform).contains("name          = \"appResolveIp\"");
        assertThat(terraform).contains("name          = \"tlsPublicCertificateSecretOcid\"");
        assertThat(terraform).contains("name          = \"tlsPrivateKeySecretOcid\"");
        assertThat(terraform).contains("name          = \"tlsCaCertificateSecretOcid\"");
        assertThat(terraform).doesNotContain("runtimeDbSslRootCertBase64");
        assertThat(terraform).doesNotContain("name          = \"ociRegion\"");
        assertThat(commandSpec).contains("OCI_REGION: \"${regionRuntime}\"");
        assertThat(terraform).contains("ignore_changes");
        assertThat(terraform).contains("deploy_artifact_source[0].base64encoded_content");
        assertThat(terraform).contains("resource \"terraform_data\" \"command_spec_hash\"");
        assertThat(terraform).contains("input = filesha256(\"${path.module}/command_spec.yaml\")");
        assertThat(terraform).contains("command_spec_artifact_display_name");
        assertThat(terraform).contains("local.tls_ca_certificate_secret_parameter");
        assertThat(terraform).contains("create_before_destroy = true");
        assertThat(terraform).contains("replace_triggered_by");
        assertThat(terraform).contains("terraform_data.command_spec_hash");
    }

    @Test
    void shouldBindNginxIngressToWortwerkTlsSecret() throws IOException {
        String ingress = read("infrastructure/oci/oke-runtime/manifests/ingress.yaml.tpl");

        assertThat(ingress).contains("tls:");
        assertThat(ingress).contains("hosts:");
        assertThat(ingress).contains("- ${APP_HOST}");
        assertThat(ingress).contains("secretName: wortwerk-tls");
    }

    @Test
    void shouldDefineGithubPushTriggerWithDocumentationAndInfrastructurePathExclusions() throws IOException {
        String terraform = read("infrastructure/oci/oke-devops/main.tf");
        String outputs = read("infrastructure/oci/oke-devops/outputs.tf");
        String readme = read("infrastructure/oci/oke-devops/README.md");

        assertThat(terraform).contains("resource \"oci_devops_trigger\" \"github_push\"");
        assertThat(terraform).contains("trigger_source = \"GITHUB\"");
        assertThat(terraform).contains("type              = \"TRIGGER_BUILD_PIPELINE\"");
        assertThat(terraform).contains("events         = [\"PUSH\"]");
        assertThat(terraform).contains("head_ref = var.repository_branch");
        assertThat(terraform).contains("\"docs/**\"");
        assertThat(terraform).contains("\"infrastructure/**\"");
        assertThat(outputs).contains("output \"github_push_trigger_id\"");
        assertThat(readme).contains("GitHub push trigger");
        assertThat(readme).contains("docs/**");
        assertThat(readme).contains("infrastructure/**");
    }

    private String read(String path) throws IOException {
        return Files.readString(Path.of(path), StandardCharsets.UTF_8);
    }
}
