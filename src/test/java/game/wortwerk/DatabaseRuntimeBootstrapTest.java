package game.wortwerk;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Base64;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;

import static org.assertj.core.api.Assertions.assertThat;

class DatabaseRuntimeBootstrapTest {

    @TempDir
    Path tempDir;

    @AfterEach
    void clearSystemProperties() {
        System.clearProperty(DatabaseRuntimeBootstrap.DB_URL);
        System.clearProperty(DatabaseRuntimeBootstrap.DB_PASSWORD);
        System.clearProperty(DatabaseRuntimeBootstrap.DB_PASSWORD_SECRET_OCID);
        System.clearProperty(DatabaseRuntimeBootstrap.DB_SSL_ROOT_CERT_BASE64);
    }

    @Test
    void shouldLoadDbPasswordFromVaultWhenExplicitPasswordMissing() {
        DatabaseRuntimeBootstrap.apply(
                Map.of(DatabaseRuntimeBootstrap.DB_PASSWORD_SECRET_OCID, "ocid1.vaultsecret.oc1..example"),
                secretOcid -> "super-secret",
                tempDir);

        assertThat(System.getProperty(DatabaseRuntimeBootstrap.DB_PASSWORD)).isEqualTo("super-secret");
    }

    @Test
    void shouldPreferExplicitPasswordOverVaultSecretLookup() {
        AtomicBoolean invoked = new AtomicBoolean(false);

        DatabaseRuntimeBootstrap.apply(
                Map.of(
                        DatabaseRuntimeBootstrap.DB_PASSWORD, "already-present",
                        DatabaseRuntimeBootstrap.DB_PASSWORD_SECRET_OCID, "ocid1.vaultsecret.oc1..example"),
                secretOcid -> {
                    invoked.set(true);
                    return "unused";
                },
                tempDir);

        assertThat(invoked).isFalse();
        assertThat(System.getProperty(DatabaseRuntimeBootstrap.DB_PASSWORD)).isNull();
    }

    @Test
    void shouldAppendTlsParametersAndMaterializeRootCertificate() throws IOException {
        String certificatePem = """
                -----BEGIN CERTIFICATE-----
                TESTCERT
                -----END CERTIFICATE-----
                """;
        String encodedCertificate = Base64.getEncoder().encodeToString(certificatePem.getBytes(StandardCharsets.UTF_8));

        DatabaseRuntimeBootstrap.apply(
                Map.of(
                        DatabaseRuntimeBootstrap.DB_URL, "jdbc:postgresql://db.example:5432/wortwerk",
                        DatabaseRuntimeBootstrap.DB_SSL_ROOT_CERT_BASE64, encodedCertificate),
                secretOcid -> {
                    throw new AssertionError("secret fetch not expected");
                },
                tempDir);

        String effectiveUrl = System.getProperty(DatabaseRuntimeBootstrap.DB_URL);

        assertThat(effectiveUrl).contains("sslmode=verify-full");
        assertThat(effectiveUrl).contains("sslrootcert=");

        String certificatePath = effectiveUrl.substring(effectiveUrl.indexOf("sslrootcert=") + "sslrootcert=".length());
        if (certificatePath.contains("&")) {
            certificatePath = certificatePath.substring(0, certificatePath.indexOf('&'));
        }

        assertThat(Files.readString(Path.of(certificatePath), StandardCharsets.UTF_8)).isEqualTo(certificatePem);
    }
}
