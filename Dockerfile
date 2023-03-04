FROM centos-xfce4-xrdp:latest
LABEL Name=rivendell Version=0.0.1
ENV container docker
ENV REPO_HOSTNAME="download.paravelsystems.com" \
    RD_HOME=/opt/rivendell \
    RD_USER=rd \
    RD_PASS=letmein \
    RD_GROUP=rivendell \
    RD_TIMEZONE=UTC \
    RD_FQDN=rivendell.example.com \
    RDADMIN_USER=rdadmin \
    RDADMIN_PASS=rdadmin

ENV GOSU_VERSION=1.11
RUN gpg --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64" \
    && curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64.asc" \
    && gpg --verify /usr/local/bin/gosu.asc \
    && rm /usr/local/bin/gosu.asc \
    && rm -r /root/.gnupg/ \
    && chmod +x /usr/local/bin/gosu \
    # Verify that the binary works
    && gosu nobody true

#
# Add RD_USER
#
RUN adduser -c Rivendell\ Audio --groups audio,wheel ${RD_USER} && \
    echo ${RD_USER}:${RD_PASS} | chpasswd

RUN mkdir -p /home/${RD_USER}/rd_xfer && \
    mkdir -p /home/${RD_USER}/music_export && \
    mkdir -p /home/${RD_USER}/music_import && \
    mkdir -p /home/${RD_USER}/traffic_export && \
    mkdir -p /home/${RD_USER}/traffic_import && \
    chown -R ${RD_USER}:${RD_USER} /home/${RD_USER}&& \
    chmod 0755 /home/${RD_USER}

#
# Configure Repos
#
RUN yum -y install wget epel-release && \
wget http://${REPO_HOSTNAME}/CentOS/7rd3/Paravel-Rivendell3.repo -P /etc/yum.repos.d/ && \
wget http://${REPO_HOSTNAME}/CentOS/7rd3/RPM-GPG-KEY-Paravel-Broadcast -P /etc/pki/rpm-gpg

ADD etc /etc
ADD usr/local/bin/start_jack /usr/local/bin/start_jack
ADD usr/share/pixmaps /usr/share/pixmaps
#
# Install Rivendell
#

#RUN  echo "HOSTNAME=\"$(hostname -f)\"" > /etc/sysconfig/network

#RUN yum -y install less patch lame
#RUN yum -y install patch evince lwmon nc  ntp  twolame libmad  xfce4-screenshooter net-tools
RUN yum -y install less lame ntp  twolame libmad
#RUN yum -y groupinstall "X window system"

#RUN systemctl set-default graphical.target

#RUN systemctl disable firewalld
RUN yum -y remove chrony openbox
RUN yum -y remove alsa-firmware alsa-firmware-tools

RUN yum -y --setopt=tsflags="" install rivendell

RUN rdgen -t 10 -l 16 /var/snd/999999_001.wav

#RUN rm /home/rd/.Xclients

CMD ["/usr/sbin/init"]
