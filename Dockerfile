FROM darrick1/rockylinux-xfce4-xrdp:8
LABEL Name=rivendell Version=4.1.3
ENV container docker

#
# Configure Repos
#
RUN dnf -y install wget; \
    wget https://software.paravelsystems.com/rhel/8rd4/RPM-GPG-KEY-Paravel-Broadcast -P /etc/pki/rpm-gpg/; \
    wget https://software.paravelsystems.com/rhel/8rd4/Paravel-Rivendell4.repo -P /etc/yum.repos.d/; \
    dnf -y clean expire-cache; \
    dnf -y --setopt=tsflags="" install rhel-rivendell-installer; \
    dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm; \
    /usr/bin/crb enable; \
    wget https://software.paravelsystems.com/rhel/8com/Paravel-Commercial.repo -P /etc/yum.repos.d/;

# Install Deps
RUN dnf -y install patch nc chrony libmad lame-libs twolame-libs jack-audio-connection-kit jack-audio-connection-kit-example-clients nfs-utils autofs; \
    rpm -i /root/pulseaudio-module-jack-14*.rpm;

#
# Install Rivendell
#
RUN patch -p0 /etc/rsyslog.conf /usr/share/rhel-rivendell-installer/rsyslog.conf.patch; \
    mv /etc/selinux/config /etc/selinux/config-original; \
    cp -f /usr/share/rhel-rivendell-installer/selinux.config /etc/selinux/config; \
    cp /usr/share/rhel-rivendell-installer/Reyware.repo /etc/yum.repos.d/; \
    cp /usr/share/rhel-rivendell-installer/RPM-GPG-KEY-Reyware /etc/pki/rpm-gpg/; \
    mkdir -p /usr/share/pixmaps/rivendell; \
    cp /usr/share/rhel-rivendell-installer/no_screen_blank.conf /etc/X11/xorg.conf.d/; \
    mkdir -p /etc/skel/Desktop; \
    cp /usr/share/rhel-rivendell-installer/skel/paravel_support.pdf /etc/skel/Desktop/First\ Steps.pdf; \
    tar -C /etc/skel -zxf /usr/share/rhel-rivendell-installer/xfce-config.tgz; \
    rm -rf /etc/skel/.config/Thunar; \
    rm -rf /etc/skel/.config/dconf;

RUN dnf -y --setopt=tsflags="" install rivendell

#Configure XRDP-PULSEAUDIO
COPY ./usr/libexec/pulseaudio-module-xrdp/load_pa_modules.sh /usr/libexec/pulseaudio-module-xrdp/

#Add Environment=JACK_PROMISCUOUS_SERVER=audio
COPY ./etc/skel/.config/systemd/user/pulseaudio.service /etc/skel/.config/systemd/user/pulseaudio.service

#RUN echo "load-module module-jack-source connect=0" >> /etc/xrdp/pulse/default.pa; \
#    echo "load-module module-loopback source=jack_in sink=xrdp-sink" >> /etc/xrdp/pulse/default.pa; \
#    echo "/usr/bin/jack_connect rivendell_0:playout_0L \"PulseAudio JACK Source:front-left\"" >> /usr/bin/start-pulseaudio-x11; \
#    echo "/usr/bin/jack_connect rivendell_0:playout_0R \"PulseAudio JACK Source:front-right\"" >> /usr/bin/start-pulseaudio-x11;

COPY docker-entrypoint.sh /usr/local/bin/
COPY installer_install_rivendell.sh /usr/local/bin/

ENTRYPOINT [ "/usr/sbin/init" ]
CMD ["docker-entrypoint.sh"]
