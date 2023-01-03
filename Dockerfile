    FROM centos:7
    ENV container docker
    ENV RD_HOME=/opt/rivendell \
        RD_USER=rduser \
        RD_PASS=rduser \
        RD_GROUP=rivendell \
        RD_TIMEZONE=UTC \
        RD_FQDN=rivendell.example.com \
        RDADMIN_USER=rdadmin \
        RDADMIN_PASS=rdadmin

    RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
    systemd-tmpfiles-setup.service ] || rm -f $i; done);
    RUN rm -f /lib/systemd/system/multi-user.target.wants/*;\
    rm -f /etc/systemd/system/*.wants/*;\
    rm -f /lib/systemd/system/local-fs.target.wants/*; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -f /lib/systemd/system/basic.target.wants/*;\
    rm -f /lib/systemd/system/anaconda.target.wants/*;
    VOLUME [ “/sys/fs/cgroup” ]
    #CMD [“/usr/sbin/init”]

    # Create rduser (password is rduser)
    RUN adduser --create-home --groups wheel,audio ${RD_USER} ; \
    echo "${RD_USER}:${RD_PASS}" | chpasswd ;\
    mkdir -m 0750 /etc/sudoers.d && \
    echo "${RD_USER} ALL=(root) NOPASSWD:ALL" >/etc/sudoers.d/rduser && \
    chmod 0440 /etc/sudoers.d/${RD_USER}
    # locale-gen en

    # Install EPEL repos
    RUN yum install -y epel-release

    # Get repo GPG keys
    #RUN rpm –import https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL http://download.paravelsystems.com/CentOS/7/RPM-GPG-KEY-Paravel-Broadcast

    RUN yum install -y wget
    # Install rivendell stuffs
    RUN wget http://download.paravelsystems.com/CentOS/7rd3/Paravel-Rivendell3.repo -P /etc/yum.repos.d/; \
    wget http://download.paravelsystems.com/CentOS/7rd3/RPM-GPG-KEY-Paravel-Broadcast -P /etc/pki/rpm-gpg

    #RUN yum-config-manager -add-repo http://download.paravelsystems.com/CentOS/7/Paravel-Broadcast.repo ; \
 #   RUN yum install -y rivendell sudo lame faac libaacplus twolame libmad id3lib icewm jackd x11vnc openssh-server tigervnc-server-minimal tigervnc-server supervisor cronie ghostscript-fonts less; \
 #   /usr/sbin/sshd-keygen

    #COPY rdmysql.conf /etc/mysql/conf.d/rdmysql.cnf
    #COPY rd.icecast.conf /etc/rd.icecast.conf
  #  COPY rd.conf /etc/rd.conf
 #   COPY supervisord.conf /etc/supervisord.d/supervisord.conf

    # copy darkice binary and config
   # RUN yum install -y darkice
    #COPY darkice /usr/local/bin
   # COPY darkice.cfg /etc
   # COPY rlm_icecast2.conf /etc




