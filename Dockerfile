ARG BASE_IMAGE="azul/zulu-openjdk:21"

FROM $BASE_IMAGE AS overlay

ARG EXT_BUILD_COMMANDS=""
ARG EXT_BUILD_OPTIONS=""

RUN mkdir -p cas-overlay \
    && mkdir cas-overlay/build
COPY ./src cas-overlay/src/
COPY ./gradle/ cas-overlay/gradle/
COPY ./gradlew ./settings.gradle ./build.gradle ./gradle.properties ./lombok.config /cas-overlay/

RUN mkdir -p ~/.gradle \
    && echo "org.gradle.daemon=false" >> ~/.gradle/gradle.properties \
    && echo "org.gradle.configureondemand=true" >> ~/.gradle/gradle.properties \
    && cd cas-overlay \
    && chmod 750 ./gradlew \
    && ./gradlew --version;

RUN cd cas-overlay \
    && ./gradlew clean build $EXT_BUILD_COMMANDS --parallel --no-daemon $EXT_BUILD_OPTIONS;

FROM $BASE_IMAGE AS cas

LABEL "Organization"="Apereo"
LABEL "Description"="Apereo CAS"

RUN cd / \
    && mkdir -p /etc/cas/config \
    && mkdir -p cas-overlay \
    && mkdir -p /cas-overlay/build \
    && chmod -R 775 /cas-overlay/build;



COPY --from=overlay cas-overlay/build/ cas-overlay/build/
COPY /etc/cas/ /etc/cas/
COPY /etc/cas/config/ /etc/cas/config/

EXPOSE 8080 8443

ENV PATH $PATH:$JAVA_HOME/bin:.

WORKDIR cas-overlay/
ENTRYPOINT ["java", "-server", "-noverify", "-Xmx2048M", "-jar", "build/libs/cas.war"]
