package game.wortwerk;

import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.web.webauthn.api.Bytes;
import org.springframework.security.web.webauthn.api.ImmutablePublicKeyCredentialUserEntity;
import org.springframework.security.web.webauthn.management.PublicKeyCredentialUserEntityRepository;

import static org.assertj.core.api.Assertions.assertThat;

@Tag("db")
@SpringBootTest
class AuthPersistenceTest {

    @Autowired
    private PublicKeyCredentialUserEntityRepository userEntityRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void shouldPersistAndLoadUserEntityWithPostgresql() {
        String username = "db-user-" + System.nanoTime();
        var userEntity = ImmutablePublicKeyCredentialUserEntity.builder()
                .id(Bytes.random())
                .name(username)
                .displayName("DB User")
                .build();

        userEntityRepository.save(userEntity);

        var loaded = userEntityRepository.findByUsername(username);
        Integer count = jdbcTemplate.queryForObject(
                "select count(*) from user_entities where name = ?",
                Integer.class,
                username);

        assertThat(loaded).isNotNull();
        assertThat(loaded.getName()).isEqualTo(username);
        assertThat(loaded.getDisplayName()).isEqualTo("DB User");
        assertThat(loaded.getId()).isEqualTo(userEntity.getId());
        assertThat(count).isEqualTo(1);
    }
}
