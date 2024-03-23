FROM rockylinux:8

LABEL Name=rivendell Version=4.1.3
ENV container docker

RUN dnf -y install epel-release;

# Install XFCE4
RUN dnf -y install \
        Thunar \
        fuse \
        openssh-askpass \
        thunar-archive-plugin \
        thunar-volman \
        tumbler \
        xfce-polkit \
        xfce4-appfinder \
        xfce4-panel \
        xfce4-pulseaudio-plugin \
        xfce4-session \
        xfce4-settings \
        xfce4-terminal \
        xfconf \
        xfdesktop \
        xfwm4;

# Install XRDP
RUN dnf -y install xrdp xorgxrdp;
ADD etc/sysconfig /etc/sysconfig
ADD etc/xrdp /etc/xrdp

# Install PulseAudio
RUN dnf -y install \
        pulseaudio \
        pulseaudio-libs \
        alsa-plugins-pulseaudio \
        pulseaudio-module-x11;
COPY ./usr/lib64/pulse-14.0/modules /usr/lib64/pulse-14.0/modules
COPY ./pulseaudio-module-jack-14*.rpm /root
COPY ./usr/libexec/pulseaudio-module-xrdp/load_pa_modules.sh /usr/libexec/pulseaudio-module-xrdp/load_pa_modules.sh
COPY ./etc/xdg/autostart/pulseaudio-xrdp.desktop /etc/xdg/autostart/pulseaudio-xrdp.desktop
ADD etc/pulse /etc/pulse

#
# Configure systemd
#
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
    systemd-tmpfiles-setup.service ] || rm -f $i; done); \
    rm -f /etc/systemd/system/*.wants/*;\
    rm -f /lib/systemd/system/local-fs.target.wants/*; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -f /lib/systemd/system/basic.target.wants/*;\
    rm -f /usr/lib/systemd/system/multi-user.target.wants/systemd-update-utmp-runlevel.service; \
    rm -f /lib/systemd/system/anaconda.target.wants/*;
#VOLUME [ "/sys/fs/cgroup" ]

RUN systemctl set-default multi-user.target; \
    systemctl enable xrdp; \
    systemctl enable xrdp-sesman; \
    systemctl unmask systemd-logind.service;

# Setup LANG
RUN dnf -y install glibc-langpack-en; \
    sed -i -e 's/C.UTF-8/en_US.utf8/' /etc/locale.conf;

RUN dnf -y remove policycoreutils; \
    dnf -y autoremove; \
    dnf -y clean all;

# Add a user
#RUN adduser -c Rivendell\ Audio --groups audio,wheel rd && echo rd:letmein | chpasswd
ADD 999999_001.wav /tone.wav

EXPOSE 3389

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

#ENTRYPOINT [ "docker-entrypoint.sh" ]
CMD ["/usr/sbin/init"]
