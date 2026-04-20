package game.wortwerk;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.assertj.core.api.Assertions.assertThat;

class OciLeastPrivilegeRuntimeRoleTest {

    @Test
    void shouldDefaultRuntimeUsernameToDedicatedNonAdminRole() throws IOException {
        String dataVariables = read("infrastructure/oci/data/variables.tf");
        String dataMain = read("infrastructure/oci/data/main.tf");
        String dataVersions = read("infrastructure/oci/data/versions.tf");

        assertThat(dataVariables).contains("default     = \"wortwerk_app\"");
        assertThat(dataVariables).contains("variable \"postgresql_instance_ocpu_count\"");
        assertThat(dataVariables).contains("default     = 2");
        assertThat(dataVariables).contains("variable \"postgresql_instance_memory_size_in_gbs\"");
        assertThat(dataVariables).contains("default     = 32");
        assertThat(dataMain).contains("runtime_db_username must be a dedicated non-admin application role");
        assertThat(dataMain).contains("resource \"oci_identity_policy\" \"runtime_secret_read\"");
        assertThat(dataMain).contains("instance_ocpu_count         = var.postgresql_instance_ocpu_count");
        assertThat(dataMain).contains("instance_memory_size_in_gbs = var.postgresql_instance_memory_size_in_gbs");
        assertThat(dataMain).doesNotContain("count          = var.runtime_db_password_secret_ocid != \"\" ? 1 : 0");
        assertThat(dataVersions).contains("backend \"oci\" {}");
    }

    @Test
    void shouldIncludeExplicitRuntimeRoleBootstrapInDeploymentFlow() throws IOException {
        String deployScript = read("infrastructure/oci/deploy.sh");
        String ociReadme = read("infrastructure/oci/README.md");
        String dataReadme = read("infrastructure/oci/data/README.md");

        assertThat(deployScript).contains("bootstrap-runtime-db-role.sh");
        assertThat(ociReadme).contains("bootstrap-runtime-db-role.sh");
        assertThat(dataReadme).contains("bootstrap-runtime-db-role.sh");
    }

    private String read(String relativePath) throws IOException {
        return Files.readString(Path.of(relativePath), StandardCharsets.UTF_8);
    }
}
