# ---------- Build Stage ----------
FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /app

COPY . .

RUN chmod +x gradlew

RUN ./gradlew clean bootJar --no-daemon

# ---------- Runtime Stage ----------
FROM eclipse-temurin:21-jre-alpine

RUN addgroup -S spring && adduser -S spring -G spring

WORKDIR /app

COPY --from=builder /app/build/libs/test-backend.jar app.jar

USER spring

EXPOSE 4000

ENTRYPOINT ["java","-jar","app.jar"]