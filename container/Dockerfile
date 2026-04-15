FROM container-registry.oracle.com/java/jdk-no-fee-term:25.0.2-oraclelinux9 AS builder

# Build a minimized runtime JRE.
WORKDIR /opt
RUN jlink \
      --output './jre' \
      --no-header-files \
      --no-man-pages \
      --add-modules java.base,java.desktop,java.instrument,java.management,java.naming,java.sql,java.security.jgss,jdk.unsupported,jdk.crypto.ec,java.logging,jdk.charsets,java.compiler \
      --compress=zip-9

# Extract layered Spring Boot jar from the Maven-built artifact.
COPY target/*.jar /opt/app.jar
RUN java -Djarmode=tools -jar /opt/app.jar extract --layers --destination /opt/extracted

FROM oraclelinux:9-slim
WORKDIR /opt/app

COPY --from=builder /opt/jre /opt/jre
COPY --from=builder /opt/extracted/dependencies/ ./
COPY --from=builder /opt/extracted/spring-boot-loader/ ./
COPY --from=builder /opt/extracted/snapshot-dependencies/ ./
COPY --from=builder /opt/extracted/application/ ./
COPY assets/ ./assets/

EXPOSE 8080

ENTRYPOINT ["/opt/jre/bin/java", "-XX:MaxRAMPercentage=75", "-XX:MinRAMPercentage=75", "-jar", "app.jar"]
