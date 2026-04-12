package game.wortwerk;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.assertj.core.api.Assertions.assertThat;

class OciDevopsPrivateReleaseRunnerTest {

    @Test
    void shouldDefineDedicatedPrivateDevopsNetworkBoundary() throws IOException {
        String foundationMain = read("infrastructure/oci/foundation/main.tf");
        String foundationVariables = read("infrastructure/oci/foundation/variables.tf");
        String foundationOutputs = read("infrastructure/oci/foundation/outputs.tf");

        assertThat(foundationVariables).contains("variable \"devops_subnet_cidr\"");
        assertThat(foundationMain).contains("resource \"oci_core_nat_gateway\" \"devops\"");
        assertThat(foundationMain).contains("resource \"oci_core_route_table\" \"devops\"");
        assertThat(foundationMain).contains("devops_nsg_name");
        assertThat(foundationMain).contains("devops_subnet_name");
        assertThat(foundationMain).contains("resource \"oci_core_network_security_group\" \"devops\"");
        assertThat(foundationMain).contains("resource \"oci_core_subnet\" \"devops\"");
        assertThat(foundationMain).contains("source                    = oci_core_network_security_group.devops.id");
        assertThat(foundationMain).contains("destination               = oci_core_network_security_group.database.id");
        assertThat(foundationMain).contains("resource \"oci_core_network_security_group_security_rule\" \"devops_egress_https\"");
        assertThat(foundationMain).contains("destination               = \"0.0.0.0/0\"");
        assertThat(foundationMain).contains("route_table_id             = oci_core_route_table.devops.id");
        assertThat(foundationOutputs).contains("output \"devops_subnet_id\"");
        assertThat(foundationOutputs).contains("output \"devops_nsg_id\"");
    }

    @Test
    void shouldDefineLeastPrivilegeIamForTheDevopsRunner() throws IOException {
        String foundationMain = read("infrastructure/oci/foundation/main.tf");
        String foundationOutputs = read("infrastructure/oci/foundation/outputs.tf");
        String deployScript = read("infrastructure/oci/deploy.sh");
        String devopsMain = read("infrastructure/oci/devops/main.tf");
        String devopsVariables = read("infrastructure/oci/devops/variables.tf");

        assertThat(foundationMain).contains("devops_dynamic_group_name");
        assertThat(foundationMain).contains("resource \"oci_identity_dynamic_group\" \"devops\"");
        assertThat(foundationMain).contains("resource \"oci_identity_policy\" \"devops_runner\"");
        assertThat(foundationMain).contains("Allow dynamic-group ${local.devops_dynamic_group_name} to manage devops-family");
        assertThat(foundationMain).contains("Allow dynamic-group ${local.devops_dynamic_group_name} to use subnets");
        assertThat(foundationMain).contains("Allow dynamic-group ${local.devops_dynamic_group_name} to use vnics");
        assertThat(foundationMain).contains("Allow dynamic-group ${local.devops_dynamic_group_name} to use network-security-groups");
        assertThat(foundationMain).contains("Allow dynamic-group ${local.devops_dynamic_group_name} to read buckets");
        assertThat(foundationMain).contains("Allow dynamic-group ${local.devops_dynamic_group_name} to manage objects");
        assertThat(foundationMain).contains("terraform_state_bucket_name");
        assertThat(foundationMain).contains("Allow dynamic-group ${local.devops_dynamic_group_name} to manage compute-container-instances");
        assertThat(foundationMain).contains("Allow dynamic-group ${local.devops_dynamic_group_name} to manage compute-containers");
        assertThat(foundationMain).contains("Allow dynamic-group ${local.devops_dynamic_group_name} to use dhcp-options");
        assertThat(foundationMain).contains("Allow dynamic-group ${local.devops_dynamic_group_name} to use ons-topics");
        assertThat(foundationOutputs).contains("output \"devops_dynamic_group_name\"");
        assertThat(foundationOutputs).contains("output \"terraform_state_bucket_name\"");
        assertThat(deployScript).contains("devops_dynamic_group_name");

        assertThat(devopsVariables).contains("variable \"home_region\"");
        assertThat(devopsVariables).contains("variable \"devops_dynamic_group_name\"");
        assertThat(devopsVariables).contains("variable \"image_registry_password_secret_ocid\"");
        assertThat(devopsMain).contains("provider \"oci\" {\n  alias  = \"home\"");
        assertThat(devopsMain).contains("resource \"oci_identity_policy\" \"github_connection_secret_read\"");
        assertThat(devopsMain).contains("Allow dynamic-group ${var.devops_dynamic_group_name} to read secret-family");
        assertThat(devopsMain).contains("Allow dynamic-group ${var.devops_dynamic_group_name} to read secret-bundles");
        assertThat(devopsMain).contains("target.secret.id = '${var.github_connection_token_secret_ocid}'");
    }

    @Test
    void shouldProvideAnOciDevopsReleaseStackDrivenByExplicitGitReference() throws IOException {
        assertThat(Path.of("infrastructure/oci/devops/main.tf")).exists();
        assertThat(Path.of("infrastructure/oci/devops/variables.tf")).exists();
        assertThat(Path.of("infrastructure/oci/devops/outputs.tf")).exists();
        assertThat(Path.of("infrastructure/oci/devops/versions.tf")).exists();
        assertThat(Path.of("infrastructure/oci/devops/README.md")).exists();
        assertThat(Path.of("infrastructure/oci/devops/build_spec.yaml")).exists();
        assertThat(Path.of("infrastructure/oci/devops/command_spec.yaml")).exists();
        assertThat(Path.of("infrastructure/oci/devops/run-release.sh")).exists();
        assertThat(Path.of("infrastructure/oci/runtime/versions.tf")).exists();

        String devopsMain = read("infrastructure/oci/devops/main.tf");
        String buildSpec = read("infrastructure/oci/devops/build_spec.yaml");
        String commandSpec = read("infrastructure/oci/devops/command_spec.yaml");
        String runReleaseScript = read("infrastructure/oci/devops/run-release.sh");
        String deployScript = read("infrastructure/oci/deploy.sh");
        String runtimeVersions = read("infrastructure/oci/runtime/versions.tf");

        assertThat(devopsMain).contains("resource \"oci_devops_project\"");
        assertThat(devopsMain).contains("resource \"oci_devops_build_pipeline\"");
        assertThat(devopsMain).contains("resource \"oci_devops_deploy_pipeline\"");
        assertThat(devopsMain).contains("resource \"oci_devops_deploy_stage\"");
        assertThat(devopsMain).contains("resource \"oci_devops_build_pipeline_stage\"");
        assertThat(devopsMain).contains("resource \"oci_objectstorage_bucket\" \"release_handoff\"");
        assertThat(devopsMain).doesNotContain("build_pipeline_stage_type = \"DELIVER_ARTIFACT\"");
        assertThat(devopsMain).doesNotContain("resource \"oci_artifacts_repository\" \"release\"");
        assertThat(devopsMain).contains("resource \"oci_logging_log_group\"");
        assertThat(devopsMain).contains("resource \"oci_logging_log\"");
        assertThat(devopsMain).contains("service     = \"devops\"");
        assertThat(devopsMain).contains("resource    = oci_devops_project.wort_werk.id");
        assertThat(devopsMain).contains("category    = \"all\"");
        assertThat(devopsMain).contains("devops_subnet_id");
        assertThat(devopsMain).contains("devops_nsg_id");
        assertThat(devopsMain).contains("network_channel_type = \"SERVICE_VNIC_CHANNEL\"");
        assertThat(buildSpec).contains("COMMIT_SHA");
        assertThat(buildSpec).contains("IMAGE_TAG");
        assertThat(buildSpec).contains("exportedVariables");
        assertThat(buildSpec).contains("./mvnw clean verify");
        assertThat(buildSpec).contains("docker buildx build");
        assertThat(buildSpec).contains("oci secrets secret-bundle get");
        assertThat(buildSpec).contains("git archive --format=tar.gz --output=release-bundle.tgz \"${release_ref}\"");
        assertThat(buildSpec).contains("oci os object put");
        assertThat(buildSpec).contains(". ./release-metadata.env");
        assertThat(commandSpec).contains("ROLLBACK: \"${ROLLBACK}\"");
        assertThat(commandSpec).contains("RELEASE_VERSION: \"${releaseVersion}\"");
        assertThat(commandSpec).contains("oci os object get");
        assertThat(commandSpec).contains("terraform");
        assertThat(commandSpec).doesNotContain("${NAMESPACE}");
        assertThat(commandSpec).doesNotContain("${BUCKET_NAME}");
        assertThat(runReleaseScript).contains("oci devops build-run create");
        assertThat(runReleaseScript).contains("commit_hash");
        assertThat(runReleaseScript).contains("repository_branch");
        assertThat(runReleaseScript).contains("\"name\": \"imageRepository\"");
        assertThat(runtimeVersions).contains("backend \"oci\"");
        assertThat(deployScript).doesNotContain("\"release\"");
        assertThat(deployScript).doesNotContain("\"rollout\"");
        assertThat(deployScript).contains("devops/run-release.sh");
    }

    private String read(String relativePath) throws IOException {
        return Files.readString(Path.of(relativePath), StandardCharsets.UTF_8);
    }
}
