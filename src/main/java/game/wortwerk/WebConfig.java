package game.wortwerk;

import java.nio.file.Path;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    private final String assetsDirectory;

    public WebConfig(@Value("${wortwerk.assets-dir:assets}") String assetsDirectory) {
        this.assetsDirectory = assetsDirectory;
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        Path path = Path.of(assetsDirectory).toAbsolutePath().normalize();
        registry.addResourceHandler("/assets/**")
                .addResourceLocations(path.toUri().toString());
    }
}
