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
        String script = read("infrastructure/oci/oke-devops/deploy-bluegreen.sh");
        String commandSpec = read("infrastructure/oci/oke-devops/command_spec.yaml");
        String variables = read("infrastructure/oci/oke-devops/variables.tf");
        String terraform = read("infrastructure/oci/oke-devops/main.tf");

        assertThat(script).contains("POST_SWITCH_OBSERVATION_SECONDS=\"${POST_SWITCH_OBSERVATION_SECONDS:-120}\"");
        assertThat(script).contains("POST_SWITCH_OBSERVATION_INTERVAL_SECONDS");
        assertThat(script).contains("observe_public_endpoint");
        assertThat(script).contains("rollback_after_failed_observation \"$TARGET_SLOT\" \"$PREVIOUS_SLOT\"");
        assertThat(script).contains("apply_active_service \"$previous_slot\"");
        assertThat(script).contains("stop_slot \"$failed_slot\"");
        assertThat(script.indexOf("if ! observe_public_endpoint; then"))
                .isLessThan(script.indexOf("stop_slot \"$PREVIOUS_SLOT\""));

        assertThat(commandSpec).contains("POST_SWITCH_OBSERVATION_SECONDS: \"${postSwitchObservationSeconds}\"");
        assertThat(commandSpec).contains("POST_SWITCH_OBSERVATION_INTERVAL_SECONDS: \"${postSwitchObservationIntervalSeconds}\"");
        assertThat(variables).contains("variable \"post_switch_observation_seconds\"");
        assertThat(variables).contains("default     = 120");
        assertThat(terraform).contains("name          = \"postSwitchObservationSeconds\"");
        assertThat(terraform).contains("name          = \"postSwitchObservationIntervalSeconds\"");
    }

    @Test
    void shouldDefineGithubPushTriggerWithDocumentationAndInfrastructurePathExclusions() throws IOException {
        String terraform = read("infrastructure/oci/oke-devops/main.tf");
        String outputs = read("infrastructure/oci/oke-devops/outputs.tf");
        String readme = read("infrastructure/oci/oke-devops/README.md");

        assertThat(terraform).contains("resource \"oci_devops_trigger\" \"github_push\"");
        assertThat(terraform).contains("trigger_source  = \"GITHUB\"");
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
