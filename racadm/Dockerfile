FROM centos:7

RUN yum install -y \
        dmidecode \
        openssl098e \
        perl \
        wget
RUN wget -q -O /tmp/dell-bootstrap.cgi http://linux.dell.com/repo/hardware/latest/bootstrap.cgi \
    && bash /tmp/dell-bootstrap.cgi \
    && rm /tmp/dell-bootstrap.cgi
RUN yum install -y \
        srvadmin-idrac-ivmcli \
        srvadmin-idrac-vmcli \
        srvadmin-idracadm \
        srvadmin-idracadm7 \
        srvadmin-racadm4 \
        srvadmin-racadm5

ENV PATH $PATH:/opt/dell/srvadmin/bin
