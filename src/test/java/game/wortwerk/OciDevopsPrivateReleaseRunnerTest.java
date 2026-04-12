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
        assertThat(foundationMain).contains("devops_nsg_name");
        assertThat(foundationMain).contains("devops_subnet_name");
        assertThat(foundationMain).contains("resource \"oci_core_network_security_group\" \"devops\"");
        assertThat(foundationMain).contains("resource \"oci_core_subnet\" \"devops\"");
        assertThat(foundationMain).contains("source                    = oci_core_network_security_group.devops.id");
        assertThat(foundationMain).contains("destination               = oci_core_network_security_group.database.id");
        assertThat(foundationMain).contains("route_table_id             = oci_core_route_table.runtime.id");
        assertThat(foundationOutputs).contains("output \"devops_subnet_id\"");
        assertThat(foundationOutputs).contains("output \"devops_nsg_id\"");
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

        String devopsMain = read("infrastructure/oci/devops/main.tf");
        String buildSpec = read("infrastructure/oci/devops/build_spec.yaml");
        String commandSpec = read("infrastructure/oci/devops/command_spec.yaml");
        String runReleaseScript = read("infrastructure/oci/devops/run-release.sh");

        assertThat(devopsMain).contains("resource \"oci_devops_project\"");
        assertThat(devopsMain).contains("resource \"oci_devops_build_pipeline\"");
        assertThat(devopsMain).contains("resource \"oci_devops_deploy_pipeline\"");
        assertThat(devopsMain).contains("resource \"oci_devops_deploy_stage\"");
        assertThat(devopsMain).contains("resource \"oci_devops_build_pipeline_stage\"");
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
        assertThat(commandSpec).contains("ROLLBACK");
        assertThat(commandSpec).contains("terraform");
        assertThat(runReleaseScript).contains("oci devops build-run create");
        assertThat(runReleaseScript).contains("commit_hash");
        assertThat(runReleaseScript).contains("repository_branch");
    }

    private String read(String relativePath) throws IOException {
        return Files.readString(Path.of(relativePath), StandardCharsets.UTF_8);
    }
}
