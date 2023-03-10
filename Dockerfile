FROM rocky-xfce4-xrdp:latest
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

RUN dnf -y remove pipewire-jack-audio-connection-kit pipewire;
#
# Configure Repos
#
RUN dnf -y install wget; \
    wget https://software.paravelsystems.com/rhel/9rd4/RPM-GPG-KEY-Paravel-Broadcast -P /etc/pki/rpm-gpg/; \
    wget https://software.paravelsystems.com/rhel/9rd4/Paravel-Rivendell4.repo -P /etc/yum.repos.d/; \
    dnf -y --setopt=tsflags="" install rhel-rivendell-installer; \
    dnf -y install procps-ng patch lame chrony twolame libmad rsyslog lame-libs jack-audio-connection-kit jack-audio-connection-kit-example-clients; \
    wget http://mirror.ppa.trinitydesktop.org/trinity/rpm/el9/trinity-r14/RPMS/noarch/trinity-repo-14.0.13-1.el9.noarch.rpm; \
    rpm -Uvh trinity-repo*rpm;

#
# Install Rivendell
#
RUN systemctl enable rsyslog; \
    patch -p0 /etc/rsyslog.conf /usr/share/rhel-rivendell-installer/rsyslog.conf.patch; \
    mv /etc/selinux/config /etc/selinux/config-original; \
    cp -f /usr/share/rhel-rivendell-installer/selinux.config /etc/selinux/config; \
    cp /usr/share/rhel-rivendell-installer/Reyware.repo /etc/yum.repos.d/; \
    cp /usr/share/rhel-rivendell-installer/RPM-GPG-KEY-Reyware /etc/pki/rpm-gpg/; \
    mkdir -p /usr/share/pixmaps/rivendell; \
    cp /usr/share/rhel-rivendell-installer/no_screen_blank.conf /etc/X11/xorg.conf.d/; \
    mkdir -p /etc/skel/Desktop; \
    cp /usr/share/rhel-rivendell-installer/skel/paravel_support.pdf /etc/skel/Desktop/First\ Steps.pdf; \
    ln -s /usr/share/rivendell/opsguide.pdf /etc/skel/Desktop/Operations\ Guide.pdf;

ADD etc/rd.conf /etc/rd.conf

RUN echo "load-module /usr/lib64/pulse-15.0/modules/module-jack-source.so connect=0" >> /etc/xrdp/pulse/default.pa; \
    echo "load-module /usr/lib64/pulse-15.0/modules/module-loopback.so source=jack_in sink=xrdp-sink" >> /etc/xrdp/pulse/default.pa;

RUN dnf -y --setopt=tsflags="" install rivendell

RUN rdgen -t 10 -l 16 /var/snd/999999_001.wav

ADD usr/bin/start-pulseaudio-x11 /usr/bin/start-pulseaudio-x11
RUN dnf -y install nmap-ncat
#RUN rm /home/rd/.Xclients
COPY docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]
CMD [ "/usr/sbin/init" ]
