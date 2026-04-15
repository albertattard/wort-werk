package game.wortwerk;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.assertj.core.api.Assertions.assertThat;

class ContainerDockerfileBaseImageTest {

    @Test
    void shouldUsePinnedOracleNoFeeBuilderAndOracleLinuxRuntimeBase() throws IOException {
        String dockerfile = Files.readString(Path.of("container/Dockerfile"), StandardCharsets.UTF_8);

        assertThat(dockerfile).contains("FROM container-registry.oracle.com/java/jdk-no-fee-term:25.0.2-oraclelinux9 AS builder");
        assertThat(dockerfile).contains("FROM oraclelinux:9-slim");
        assertThat(dockerfile).doesNotContain("FROM container-registry.oracle.com/java/jdk-no-fee-term:25 AS builder");
    }
}
