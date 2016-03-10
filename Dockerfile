FROM java:8

# File Maintainer
MAINTAINER Patrick Double (http://github.com/double16)

RUN adduser --disabled-password --gecos '' r  && adduser r sudo && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN mkdir /cache && chown r /cache
ENV GRADLE_USER_HOME=/cache TERM=dumb

WORKDIR /home/r
COPY . /app
RUN chown -R r /app
WORKDIR /app

USER r
RUN ./gradlew --version

VOLUME /cache
VOLUME /dist
ENTRYPOINT ["./gradlew"]
CMD ["check"]

