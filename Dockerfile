ARG MVN_VERSION=3.8.4
ARG JDK_VERSION=11

FROM maven:${MVN_VERSION}-openjdk-${JDK_VERSION}-slim as builder

WORKDIR /build

COPY ./pom.xml .
RUN mvn dependency:go-offline

WORKDIR /tmp

COPY ./pom.xml .
COPY ./src/ src/

RUN mvn clean package -DskipTests

WORKDIR /tmp/target
RUN java -Djarmode=layertools -jar *.jar extract

FROM gcr.io/distroless/java:${JDK_VERSION}-nonroot as runtime

USER nonroot:nonroot

WORKDIR /application

COPY --from=builder --chown=nonroot:nonroot /tmp/target/dependencies/ ./
COPY --from=builder --chown=nonroot:nonroot /tmp/target/snapshot-dependencies/ ./
COPY --from=builder --chown=nonroot:nonroot /tmp/target/spring-boot-loader/ ./
COPY --from=builder --chown=nonroot:nonroot /tmp/target/application/ ./

ENV SPRING_APP_PROFILE=prod
ENV PORT=8080

ENV _JAVA_OPTIONS "-XX:MinRAMPercentage=60.0 -XX:MaxRAMPercentage=90.0 \
-Djava.security.egd=file:/dev/./urandom \
-Djava.awt.headless=true -Dfile.encoding=UTF-8 \
-Dspring.output.ansi.enabled=ALWAYS \
-Dspring.profiles.active=${SPRING_APP_PROFILE}"

EXPOSE ${PORT}

ENTRYPOINT ["java", "org.springframework.boot.loader.JarLauncher"]