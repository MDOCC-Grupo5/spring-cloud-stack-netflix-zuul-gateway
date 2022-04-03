FROM maven:3.8.4-openjdk-11-slim as builder

WORKDIR /build

COPY src/ src/
COPY pom.xml .

RUN mvn clean package -DskipTests

FROM adoptopenjdk:11.0.11_9-jre-hotspot-focal

ENV SPRING_APP_PROFILE=prod

ARG uid=1001
ARG gid=51

WORKDIR /app

RUN addgroup --gid $gid app \
    && adduser --disabled-password --gecos "" --no-create-home --uid $uid --gid $gid app

COPY --from=builder --chown=app:app /build/target/*.jar app.jar

USER app

ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom", "-Dspring.profiles.active=${SPRING_APP_PROFILE}", "-jar", "app.jar"]