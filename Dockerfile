# Set base image
FROM ubuntu:15.04

# File Maintainer
MAINTAINER Patrick Double (http://github.com/double16) (thanks to Michael Joseph Walsh for most of it)

# Update the sources list
RUN apt-get update

# Install cmd-line dev toolchain
RUN apt-get install -y tar git curl nano wget dialog net-tools build-essential software-properties-common

# To install the default OpenJDK environment
RUN add-apt-repository -y ppa:openjdk-r/ppa
RUN apt-get -y update 
RUN apt-get -y install openjdk-8-jdk

RUN adduser --disabled-password --gecos '' r  && adduser r sudo && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

VOLUME /cache
VOLUME /dist
ENV GRADLE_HOME=/cache

WORKDIR /home/r
COPY . pet-store
RUN chown -R r pet-store
RUN su r -c 'cd pet-store && ./gradlew build'

