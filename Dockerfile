FROM amd64/ubuntu:20.04


ENV DEBIAN_FRONTEND="noninteractive"
ENV CRITICAL_DAYS=7
ENV WARNING_DAYS=30


RUN apt-get update && apt-get install -y \
	vim \
	net-tools --fix-missing \
	wget \
	curl \
	sudo \
	build-essential \
	git \
    mailutils

# install bosh cli
RUN  wget https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-6.4.1-linux-amd64
RUN mv bosh-cli-6.4.1-linux-amd64 bosh
RUN chmod +x bosh
RUN sudo mv bosh /usr/local/bin
RUN bosh --version

# install credhub cli
RUN wget https://github.com/cloudfoundry-incubator/credhub-cli/releases/download/2.9.0/credhub-linux-2.9.0.tgz
RUN tar -xzvf credhub-linux-2.9.0.tgz
RUN chmod +x credhub
RUN sudo mv credhub /usr/local/bin
RUN credhub --version


WORKDIR /app/
COPY . /app

ENTRYPOINT ["/bin/bash", "/app/run.sh"]