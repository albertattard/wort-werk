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

    private String read(String relativePath) throws IOException {
        return Files.readString(Path.of(relativePath), StandardCharsets.UTF_8);
    }
}
