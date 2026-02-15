FROM gradle:8.10-jdk17 AS builder
WORKDIR /app
COPY . .
RUN chmod +x gradlew
RUN ./gradlew clean build -x test

FROM eclipse-temurin:17-jdk-jammy
WORKDIR /app

COPY --from=builder /app/build/libs/*.jar app.jar

EXPOSE 8080

RUN mkdir -p /app/uploads
VOLUME ["/app/uploads"]

ENTRYPOINT ["java", "-jar", "app.jar"]
