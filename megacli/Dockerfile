FROM centos:7

ENV PATH "/opt/MegaRAID/MegaCli:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

COPY MegaCli-8.07.14-1.noarch.rpm /tmp/
RUN yum -y install \
        bash-completion \
        nano \
        less \
        dmidecode \
    && yum clean all \
    && mkdir -p /megacli \
    && rpm -ivh /tmp/MegaCli*.rpm \
    && rm /tmp/MegaCli*.rpm \
    && cd /megacli \
    && ln -s $(command -v MegaCli64) /usr/local/sbin/megacli \
    && ln -s $(command -v MegaCli64) /usr/local/sbin/megacli64 \
    && ln -s $(command -v MegaCli64) /usr/local/sbin/Megacli \
    && ln -s $(command -v MegaCli64) /usr/local/sbin/Megacli64 \
    && ln -s $(command -v MegaCli64) /usr/local/sbin/MegaCLI \
    && ln -s $(command -v MegaCli64) /usr/local/sbin/MegaCLI64 \
    && ln -s $(command -v MegaCli64) /usr/local/sbin/MegaCli \
    && echo 'megacli -v | grep "^.*Tool"' >> ~/.bashrc

COPY resources/megacli_profile.sh /etc/profile.d/
COPY resources/scripts /megacli

WORKDIR "/megacli"

CMD ["bash", "-l"]
