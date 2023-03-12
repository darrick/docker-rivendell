FROM darrick1/rockylinux-xfce4-xrdp:7
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

#
# Configure Repos
#
RUN yum -y install wget; \
    wget http://download.paravelsystems.com/CentOS/7rd3/RPM-GPG-KEY-Paravel-Broadcast -P /etc/pki/rpm-gpg/; \
    wget http://download.paravelsystems.com/CentOS/7rd3/Paravel-Rivendell3.repo -P /etc/yum.repos.d/; \
    yum -y install procps-ng patch lame chrony twolame libmad rsyslog lame-libs jack;
#
# Install Rivendell
#
RUN yum -y --setopt=tsflags="" install rivendell-install; \
    cp /usr/share/rivendell-install/*.repo /etc/yum.repos.d/; \
    cp /usr/share/rivendell-install/RPM-GPG-KEY* /etc/pki/rpm-gpg/; \
    mkdir -p /usr/share/pixmaps/rivendell; \
    cp /usr/share/rivendell-install/rdairplay_skin.png /usr/share/pixmaps/rivendell/; \
    cp /usr/share/rivendell-install/rdpanel_skin.png /usr/share/pixmaps/rivendell/; \
    cp /usr/share/rivendell-install/no_screen_blank.conf /etc/X11/xorg.conf.d/; \
    mkdir -p /etc/skel/Desktop; \
    ln -s /usr/share/rivendell/opsguide.pdf /etc/skel/Desktop/Operations\ Guide.pdf; \
    cp /usr/share/rivendell-install/skel/paravel_support.pdf /etc/skel/Desktop/First\ Steps.pdf; \
    tar -C /etc/skel -zxf /usr/share/rivendell-install/xfce-config.tgz; \
    cp /usr/share/rivendell-install/qtrc /etc/skel/.qt/; \
    yum -y --setopt=tsflags="" install rivendell;

ADD etc/rd.conf /etc/rd.conf

RUN echo "load-module /usr/lib64/pulse-10.0/modules/module-jack-source.so connect=0" >> /etc/xrdp/pulse/default.pa; \
    echo "load-module /usr/lib64/pulse-10.0/modules/module-loopback.so source=jack_in sink=xrdp-sink" >> /etc/xrdp/pulse/default.pa;

RUN yum -y install nmap-ncat less fuse
RUN pip3 install jack-matchmaker

#RUN rm /home/rd/.Xclients
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY etc /etc
RUN systemctl enable jack-matchmaker

ENTRYPOINT ["docker-entrypoint.sh"]
CMD [ "/usr/sbin/init" ]
