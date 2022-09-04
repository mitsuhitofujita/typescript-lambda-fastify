FROM hashicorp/terraform:1.2.7

RUN apk update && \
    apk add --no-cache \
        curl \
        docker-cli \
        docker-compose

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf aws awscliv2.zip

ARG TERRAFORM_UID=1000
ARG TERRAFORM_USER=terraform
ARG TERRAFORM_HOME=/home/terraform
ARG TERRAFORM_DELGROUP=ping
ARG DOCKER_GID=999
ARG DOCKER_GROUP=docker
RUN delgroup ${TERRAFORM_DELGROUP}; exit 0
RUN addgroup -g ${DOCKER_GID} ${DOCKER_GROUP} && \
    adduser -D -u ${TERRAFORM_UID} -G ${DOCKER_GROUP} -h ${TERRAFORM_HOME} ${TERRAFORM_USER} 
