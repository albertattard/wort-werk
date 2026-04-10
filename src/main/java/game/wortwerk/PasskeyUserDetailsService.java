package game.wortwerk;

import org.springframework.security.core.authority.AuthorityUtils;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.web.webauthn.management.PublicKeyCredentialUserEntityRepository;

import java.util.List;

public class PasskeyUserDetailsService implements UserDetailsService {

    static final List<GrantedAuthority> PRE_REGISTRATION_AUTHORITIES = AuthorityUtils.createAuthorityList("ROLE_PASSKEY_REGISTRATION");

    private final PublicKeyCredentialUserEntityRepository userEntityRepository;

    public PasskeyUserDetailsService(PublicKeyCredentialUserEntityRepository userEntityRepository) {
        this.userEntityRepository = userEntityRepository;
    }

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        var userEntity = userEntityRepository.findByUsername(username);
        if (userEntity == null) {
            throw new UsernameNotFoundException("User not found: " + username);
        }
        return User.withUsername(userEntity.getName())
                .password("{noop}unused")
                .roles("USER")
                .build();
    }
}
