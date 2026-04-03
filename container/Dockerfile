FROM container-registry.oracle.com/java/jdk:25.0.2 AS builder

# Build a minimized runtime JRE.
WORKDIR /opt
RUN jlink \
      --output './jre' \
      --no-header-files \
      --no-man-pages \
      --add-modules java.base,java.desktop,java.instrument,java.management,java.naming,java.sql,java.security.jgss,jdk.unsupported,jdk.crypto.ec,java.logging,jdk.charsets \
      --compress=zip-9

# Build the application jar.
WORKDIR /opt/app
COPY .mvn .mvn/
COPY src src/
COPY mvnw pom.xml ./
RUN chmod +x mvnw
RUN ./mvnw --quiet -DskipTests clean package

# Extract layered Spring Boot jar.
WORKDIR /opt
RUN cp /opt/app/target/*.jar app.jar \
 && java -Djarmode=tools -jar app.jar extract --layers --destination extracted

FROM container-registry.oracle.com/os/oraclelinux:9-slim
WORKDIR /opt/app

COPY --from=builder /opt/jre /opt/jre
COPY --from=builder /opt/extracted/dependencies/ ./
COPY --from=builder /opt/extracted/spring-boot-loader/ ./
COPY --from=builder /opt/extracted/snapshot-dependencies/ ./
COPY --from=builder /opt/extracted/application/ ./
COPY assets/ ./assets/

EXPOSE 8080

ENTRYPOINT ["/opt/jre/bin/java", "-XX:MaxRAMPercentage=75", "-XX:MinRAMPercentage=75", "-jar", "app.jar"]
