package game.wortwerk;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.core.JdbcOperations;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.LoginUrlAuthenticationEntryPoint;
import org.springframework.security.web.webauthn.management.JdbcPublicKeyCredentialUserEntityRepository;
import org.springframework.security.web.webauthn.management.JdbcUserCredentialRepository;
import org.springframework.security.web.webauthn.management.PublicKeyCredentialUserEntityRepository;
import org.springframework.security.web.webauthn.management.UserCredentialRepository;
import org.springframework.security.web.webauthn.registration.HttpSessionPublicKeyCredentialCreationOptionsRepository;
import org.springframework.security.web.webauthn.registration.PublicKeyCredentialCreationOptionsRepository;

import java.util.Arrays;
import java.util.Set;
import java.util.stream.Collectors;

@Configuration
public class SecurityConfig {

    private final String rpId;
    private final String rpName;
    private final Set<String> allowedOrigins;

    public SecurityConfig(
            @Value("${wortwerk.security.webauthn.rp-id}") String rpId,
            @Value("${wortwerk.security.webauthn.rp-name}") String rpName,
            @Value("${wortwerk.security.webauthn.allowed-origins}") String allowedOrigins) {
        this.rpId = rpId;
        this.rpName = rpName;
        this.allowedOrigins = Arrays.stream(allowedOrigins.split(","))
                .map(String::trim)
                .filter(value -> !value.isBlank())
                .collect(Collectors.toSet());
    }

    @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(
                                "/login",
                                "/register",
                                "/login/webauthn",
                                "/passkey/register/session",
                                "/webauthn/**",
                                "/assets/**",
                                "/error",
                                "/favicon.ico",
                                "/site.webmanifest",
                                "/apple-touch-icon.png",
                                "/android-chrome-192x192.png",
                                "/android-chrome-512x512.png",
                                "/favicon-16x16.png",
                                "/favicon-32x32.png"
                        ).permitAll()
                        .anyRequest().hasAuthority("FACTOR_WEBAUTHN"))
                .webAuthn(webAuthn -> webAuthn
                        .rpId(rpId)
                        .rpName(rpName)
                        .allowedOrigins(allowedOrigins)
                        .disableDefaultRegistrationPage(true))
                .exceptionHandling(ex -> ex
                        .authenticationEntryPoint(new LoginUrlAuthenticationEntryPoint("/login"))
                        .accessDeniedHandler((request, response, accessDeniedException) -> response.sendRedirect("/login")))
                .anonymous(anonymous -> anonymous.disable())
                .logout(logout -> logout
                        .logoutSuccessUrl("/login?logout")
                        .permitAll());

        return http.build();
    }

    @Bean
    PublicKeyCredentialUserEntityRepository publicKeyCredentialUserEntityRepository(JdbcOperations jdbcOperations) {
        return new JdbcPublicKeyCredentialUserEntityRepository(jdbcOperations);
    }

    @Bean
    UserCredentialRepository userCredentialRepository(JdbcOperations jdbcOperations) {
        return new JdbcUserCredentialRepository(jdbcOperations);
    }

    @Bean
    PublicKeyCredentialCreationOptionsRepository publicKeyCredentialCreationOptionsRepository() {
        return new HttpSessionPublicKeyCredentialCreationOptionsRepository();
    }

    @Bean
    UserDetailsService userDetailsService(PublicKeyCredentialUserEntityRepository userEntityRepository) {
        return new PasskeyUserDetailsService(userEntityRepository);
    }
}
