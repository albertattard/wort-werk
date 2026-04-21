package game.wortwerk;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.assertj.core.api.Assertions.assertThat;

class OciPrivateRuntimeNetworkTest {

    @Test
    void shouldDeployRuntimeWithoutPublicIpAndSeparateSubnets() throws IOException {
        String runtimeMain = read("infrastructure/oci/runtime/main.tf");
        String runtimeVariables = read("infrastructure/oci/runtime/variables.tf");
        String foundationOutputs = read("infrastructure/oci/foundation/outputs.tf");

        assertThat(runtimeMain).contains("subnet_id             = var.runtime_subnet_id");
        assertThat(runtimeMain).contains("is_public_ip_assigned = false");
        assertThat(runtimeMain).contains("subnet_ids                 = [var.load_balancer_subnet_id]");
        assertThat(runtimeVariables).contains("variable \"runtime_subnet_id\"");
        assertThat(runtimeVariables).contains("variable \"load_balancer_subnet_id\"");
        assertThat(runtimeVariables).contains("variable \"runtime_db_url\"");
        assertThat(runtimeVariables).contains("variable \"runtime_db_username\"");
        assertThat(runtimeVariables).contains("variable \"runtime_db_password_secret_ocid\"");
        assertThat(runtimeVariables).contains("variable \"runtime_db_ssl_root_cert_base64\"");
        assertThat(runtimeVariables).doesNotContain("variable \"runtime_db_url\" {\n  description = \"JDBC URL used by the application runtime.\"\n  type        = string\n  default     = \"\"\n}");
        assertThat(runtimeMain).containsPattern("WORTWERK_DB_URL\\s*=\\s*var\\.runtime_db_url");
        assertThat(runtimeMain).containsPattern("WORTWERK_DB_USERNAME\\s*=\\s*var\\.runtime_db_username");
        assertThat(runtimeMain).containsPattern("WORTWERK_DB_PASSWORD_SECRET_OCID\\s*=\\s*var\\.runtime_db_password_secret_ocid");
        assertThat(runtimeMain).containsPattern("WORTWERK_DB_SSL_ROOT_CERT_BASE64\\s*=\\s*var\\.runtime_db_ssl_root_cert_base64");
        assertThat(runtimeMain).doesNotContain("var.runtime_db_url != \"\" ? {");
        assertThat(foundationOutputs).contains("output \"runtime_subnet_id\"");
        assertThat(foundationOutputs).contains("output \"load_balancer_subnet_id\"");
    }

    @Test
    void shouldProvidePrivateOciServiceAccessForRuntimeStartupDependencies() throws IOException {
        String foundationMain = read("infrastructure/oci/foundation/main.tf");
        String foundationVariables = read("infrastructure/oci/foundation/variables.tf");

        assertThat(foundationMain).contains("resource \"oci_core_service_gateway\"");
        assertThat(foundationMain).contains("resource \"oci_core_subnet\" \"load_balancer\"");
        assertThat(foundationMain).contains("display_name               = local.stack_name");
        assertThat(foundationMain).contains("dns_label                  = \"wortwerk\"");
        assertThat(foundationMain).contains("resource \"oci_core_subnet\" \"runtime\"");
        assertThat(foundationMain).contains("prohibit_public_ip_on_vnic = true");
        assertThat(foundationMain).contains("route_table_id             = oci_core_route_table.runtime.id");
        assertThat(foundationVariables).contains("variable \"runtime_subnet_cidr\"");
        assertThat(foundationVariables).contains("variable \"load_balancer_subnet_cidr\"");
    }

    @Test
    void shouldCentralizeFoundationFreeformTagsForTaggedResources() throws IOException {
        String foundationMain = read("infrastructure/oci/foundation/main.tf");

        assertThat(foundationMain).contains("freeform_tags = {");
        assertThat(foundationMain).contains("group_id = local.stack_name");
        assertThat(foundationMain).contains("resource \"oci_core_vcn\" \"wort_werk\"");
        assertThat(foundationMain).contains("resource \"oci_core_subnet\" \"runtime\"");
        assertThat(foundationMain).contains("resource \"oci_kms_vault\" \"wort_werk\"");
        assertThat(foundationMain).contains("freeform_tags  = local.freeform_tags");
        assertThat(foundationMain).contains("freeform_tags              = local.freeform_tags");
    }

    private String read(String relativePath) throws IOException {
        return Files.readString(Path.of(relativePath), StandardCharsets.UTF_8);
    }
}
