package game.wortwerk;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Controller;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.web.context.HttpSessionSecurityContextRepository;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.security.web.webauthn.management.PublicKeyCredentialUserEntityRepository;

import java.util.Map;

@Controller
public class AuthController {

    private final PublicKeyCredentialUserEntityRepository userEntityRepository;
    private final HttpSessionSecurityContextRepository securityContextRepository = new HttpSessionSecurityContextRepository();

    public AuthController(PublicKeyCredentialUserEntityRepository userEntityRepository) {
        this.userEntityRepository = userEntityRepository;
    }

    @GetMapping("/login")
    public String loginPage() {
        return "login";
    }

    @GetMapping("/register")
    public String registerPage() {
        return "register";
    }

    @PostMapping("/passkey/register/session")
    @ResponseBody
    public ResponseEntity<Map<String, String>> startPasskeyRegistrationSession(
            @RequestBody Map<String, String> payload,
            HttpServletRequest request,
            HttpServletResponse response) {
        String username = normalize(payload.get("username"));
        if (username.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Benutzername fehlt."));
        }

        try {
            if (userEntityRepository.findByUsername(username) != null) {
                return ResponseEntity.status(409).body(Map.of("error", "Benutzername bereits belegt."));
            }
        } catch (UsernameNotFoundException ignored) {
            // Expected for new users.
        }

        SecurityContext context = SecurityContextHolder.createEmptyContext();
        context.setAuthentication(UsernamePasswordAuthenticationToken.authenticated(username, "N/A", PasskeyUserDetailsService.PRE_REGISTRATION_AUTHORITIES));
        securityContextRepository.saveContext(context, request, response);
        SecurityContextHolder.setContext(context);

        return ResponseEntity.ok(Map.of("status", "ok"));
    }

    private String normalize(String username) {
        return username == null ? "" : username.trim();
    }
}
