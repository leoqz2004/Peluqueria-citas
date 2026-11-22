# Imagen de Bella Estilo (Semana 16: despliegue). Construccion en dos etapas: Maven compila, el JRE ejecuta.
# Si la etiqueta de la imagen con Java 24 ya no existe en Docker Hub, usar la LTS disponible
# y ajustar <java.version> en pom.xml.
FROM maven:3.9-eclipse-temurin-24 AS build
WORKDIR /src
COPY pom.xml .
RUN mvn -q -B dependency:go-offline
COPY src ./src
RUN mvn -q -B -DskipTests package

FROM eclipse-temurin:24-jre
RUN useradd --system --uid 1001 --no-create-home bella \
 && mkdir -p /app/logs && chown bella /app/logs
WORKDIR /app
COPY --from=build /src/target/*.jar app.jar
USER bella
EXPOSE 8080
ENV JAVA_OPTS="-XX:MaxRAMPercentage=75" LOG_DIR=/app/logs
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD curl -fsS http://localhost:8080/actuator/health | grep -q '"status":"UP"' || exit 1
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]
