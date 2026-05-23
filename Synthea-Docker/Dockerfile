FROM amazoncorretto:17-alpine3.22-jdk
#FROM openjdk:17-jdk-alpine3.14

RUN mkdir /synthea

WORKDIR  /synthea

COPY ./synthea-with-dependencies.jar ./

COPY ./synthea.properties ./

ENTRYPOINT  [ "java", "-jar" , "./synthea-with-dependencies.jar", "-c", "./synthea.properties" , "-m", "metabolic*" ] 

CMD ["-p" , "25"]
