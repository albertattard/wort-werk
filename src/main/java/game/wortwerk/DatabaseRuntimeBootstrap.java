package game.wortwerk;

import com.oracle.bmc.auth.ResourcePrincipalAuthenticationDetailsProvider;
import com.oracle.bmc.secrets.SecretsClient;
import com.oracle.bmc.secrets.model.Base64SecretBundleContentDetails;
import com.oracle.bmc.secrets.requests.GetSecretBundleRequest;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Base64;
import java.util.Map;

final class DatabaseRuntimeBootstrap {

    static final String DB_URL = "WORTWERK_DB_URL";
    static final String DB_PASSWORD = "WORTWERK_DB_PASSWORD";
    static final String DB_PASSWORD_SECRET_OCID = "WORTWERK_DB_PASSWORD_SECRET_OCID";
    static final String DB_SSL_ROOT_CERT_BASE64 = "WORTWERK_DB_SSL_ROOT_CERT_BASE64";

    private DatabaseRuntimeBootstrap() {
    }

    static void apply() {
        apply(System.getenv(), new OciVaultSecretValueFetcher(), Path.of(System.getProperty("java.io.tmpdir")));
    }

    static void apply(Map<String, String> environment, SecretValueFetcher secretValueFetcher, Path tempDirectory) {
        String password = firstNonBlank(System.getProperty(DB_PASSWORD), environment.get(DB_PASSWORD));
        String passwordSecretOcid = firstNonBlank(System.getProperty(DB_PASSWORD_SECRET_OCID), environment.get(DB_PASSWORD_SECRET_OCID));

        if (password.isBlank() && !passwordSecretOcid.isBlank()) {
            System.setProperty(DB_PASSWORD, secretValueFetcher.fetch(passwordSecretOcid));
        }

        String certificateBase64 = firstNonBlank(System.getProperty(DB_SSL_ROOT_CERT_BASE64), environment.get(DB_SSL_ROOT_CERT_BASE64));
        String url = firstNonBlank(System.getProperty(DB_URL), environment.get(DB_URL));

        if (!certificateBase64.isBlank() && !url.isBlank()) {
            Path certificatePath = writeCertificateFile(certificateBase64, tempDirectory);
            System.setProperty(DB_URL, appendTlsParameters(url, certificatePath));
        }
    }

    private static Path writeCertificateFile(String certificateBase64, Path tempDirectory) {
        try {
            Files.createDirectories(tempDirectory);
            Path certificatePath = Files.createTempFile(tempDirectory, "wortwerk-db-root-", ".crt");
            byte[] certificate = Base64.getDecoder().decode(certificateBase64);
            Files.writeString(certificatePath, new String(certificate, StandardCharsets.UTF_8), StandardCharsets.UTF_8);
            certificatePath.toFile().deleteOnExit();
            return certificatePath;
        } catch (IOException e) {
            throw new IllegalStateException("Failed to materialize database TLS root certificate", e);
        }
    }

    private static String appendTlsParameters(String url, Path certificatePath) {
        String withSslMode = containsQueryParameter(url, "sslmode=") ? url : appendQueryParameter(url, "sslmode=verify-full");
        return containsQueryParameter(withSslMode, "sslrootcert=")
                ? withSslMode
                : appendQueryParameter(withSslMode, "sslrootcert=" + certificatePath.toAbsolutePath());
    }

    private static boolean containsQueryParameter(String url, String parameterNamePrefix) {
        return url.contains("?" + parameterNamePrefix) || url.contains("&" + parameterNamePrefix);
    }

    private static String appendQueryParameter(String url, String parameter) {
        return url + (url.contains("?") ? "&" : "?") + parameter;
    }

    private static String firstNonBlank(String first, String second) {
        if (first != null && !first.isBlank()) {
            return first;
        }
        return second == null ? "" : second;
    }

    interface SecretValueFetcher {
        String fetch(String secretOcid);
    }

    static final class OciVaultSecretValueFetcher implements SecretValueFetcher {

        @Override
        public String fetch(String secretOcid) {
            try (SecretsClient client = SecretsClient.builder().build(ResourcePrincipalAuthenticationDetailsProvider.builder().build())) {
                var response = client.getSecretBundle(GetSecretBundleRequest.builder()
                        .secretId(secretOcid)
                        .build());
                var content = response.getSecretBundle().getSecretBundleContent();
                if (!(content instanceof Base64SecretBundleContentDetails details)) {
                    throw new IllegalStateException("Unsupported OCI Vault secret bundle content type for secret: " + secretOcid);
                }
                return new String(Base64.getDecoder().decode(details.getContent()), StandardCharsets.UTF_8);
            } catch (Exception e) {
                throw new IllegalStateException("Failed to load database secret from OCI Vault: " + secretOcid, e);
            }
        }
    }
}
