FROM kalilinux/kali-rolling:latest

### Set Environment
ENV DEBIAN_FRONTEND=noninteractive
ENV APT_LISTCHANGES_FRONTEND=none

### Workdir
RUN mkdir /caa /tools
WORKDIR /caa

COPY install-deps.sh /caa/install-deps.sh
COPY install-caa.sh /caa/install-caa.sh
RUN chmod +x /caa/install-deps.sh && /caa/install-deps.sh
RUN chmod +x /caa/install-caa.sh && /caa/install-caa.sh


CMD ["/bin/bash"]