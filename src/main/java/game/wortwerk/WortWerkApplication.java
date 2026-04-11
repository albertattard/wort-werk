package game.wortwerk;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class WortWerkApplication {

    public static void main(String[] args) {
        DatabaseRuntimeBootstrap.apply();
        SpringApplication.run(WortWerkApplication.class, args);
    }
}
