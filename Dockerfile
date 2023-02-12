
FROM centos:7 as builder
LABEL Name=rivendell Version=0.0.1
RUN yum -y --setopt=tsflags="" groupinstall "Development Tools" \
&& yum -y --setopt=tsflags="" install rpmdevtools yum-utils \
&& rpmdev-setuptree

RUN yum -y install --setopt=tsflags="" pulseaudio pulseaudio-libs pulseaudio-libs-devel \
&& yum-builddep -y pulseaudio

RUN yumdownloader --source pulseaudio \
&& rpm --install pulseaudio*.src.rpm

RUN rpmbuild -bb --noclean ~/rpmbuild/SPECS/pulseaudio.spec

RUN git clone https://github.com/neutrinolabs/pulseaudio-module-xrdp.git \
&& cd pulseaudio-module-xrdp \
&& ./bootstrap && ./configure PULSE_DIR=/root/rpmbuild/BUILD/pulseaudio-10.0 \
&& make && make install

FROM centos:7
LABEL Name=rivendell Version=0.0.1
ENV container docker
ENV REPO_HOSTNAME="download.paravelsystems.com" \
    RD_HOME=/opt/rivendell \
    RD_USER=rduser \
    RD_PASS=rduser \
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
# Configure systemd
#
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
    systemd-tmpfiles-setup.service ] || rm -f $i; done); \
    rm -f /lib/systemd/system/multi-user.target.wants/*;\
    rm -f /etc/systemd/system/*.wants/*;\
    rm -f /lib/systemd/system/local-fs.target.wants/*; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -f /lib/systemd/system/basic.target.wants/*;\
    rm -f /lib/systemd/system/anaconda.target.wants/*;
VOLUME [ "/sys/fs/cgroup" ]

#
# Add RD_USER
#
RUN adduser -c Rivendell\ Audio --groups audio,wheel ${RD_USER} && \
    mkdir -p /home/${RD_USER}/rd_xfer && \
    mkdir -p /home/${RD_USER}/music_export && \
    mkdir -p /home/${RD_USER}/music_import && \
    mkdir -p /home/${RD_USER}/traffic_export && \
    mkdir -p /home/${RD_USER}/traffic_import && \
    chown -R ${RD_USER}:${RD_USER} /home/${RD_USER}&& \
    chmod 0755 /home/${RD_USER} && \
    echo ${RD_USER}:${RD_PASS} | chpasswd

#
# Configure Repos
#
RUN yum -y install wget epel-release && \
wget http://${REPO_HOSTNAME}/CentOS/7rd3/Paravel-Rivendell3.repo -P /etc/yum.repos.d/ && \
wget http://${REPO_HOSTNAME}/CentOS/7rd3/RPM-GPG-KEY-Paravel-Broadcast -P /etc/pki/rpm-gpg
#
# Install XFCE4
#
RUN yum -y --setopt=tsflags="" groupinstall "X window system" \
&& yum -y --setopt=tsflags="" groupinstall xfce
#
# Install Rivendell
#
COPY  ./rivendell-install/rd.conf /etc/rd.conf
RUN yum -y --setopt=tsflags="" install rivendell

# Make sure login works
RUN yum -y install --setopt=tsflags="" pulseaudio pulseaudio-libs xrdp xorgxrdp supervisor

COPY --from=builder /usr/lib64/pulse-10.0/modules /usr/lib64/pulse-10.0/modules

#COPY ./rivendell-install/supervisord.conf /etc/

RUN mkdir -p /var/log/supervisor

ADD etc /etc
ADD bin /bin

EXPOSE 3389
#EXPOSE 8080
#RUN  mysql --password=example -u root -h db -e "SET GLOBAL sql_mode='ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION';" && \

#COPY  ./rivendell-install/start /start
RUN chmod +x /start
# prepare xrdp key
RUN xrdp-keygen xrdp auto

RUN yum -y install firefox mozilla-ublock-origin

RUN yum -y install alsa-plugins-pulseaudio

ENTRYPOINT ["/bin/docker-entrypoint.sh"]
#CMD ["/usr/bin/supervisord","-c","/etc/supervisor/supervisord.conf"]
CMD ["/usr/sbin/init"]
