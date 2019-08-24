FROM centos:7
RUN yum install -y epel-release python-setuptools
RUN easy_install supervisor \
&& easy_install supervisor-stdout

RUN yum install -y inotify-tools-3.14-8.el7 \
openssh-clients-7.4p1-16.el7 openssh-server-7.4p1-16.el7 \
openssl-1.0.2k-16.el7 python-setuptools-0.9.8-7.el7 

RUN yum install -y httpd httpd-tools;

RUN mkdir -p /var/log/supervisor \
&& echo "NETWORKING=yes" echo "NETWORKING=yes" > /etc/sysconfig/network;
RUN sed -i -e 's~^PasswordAuthentication yes~PasswordAuthentication no~g' \
-e 's~^#PermitRootLogin yes~PermitRootLogin no~g' -e \
's~^#UseDNS yes~UseDNS no~g' \
-e 's~^\(.*\)/usr/libexec/openssh/sftp-server$~\1internal-sftp~g' /etc/ssh/sshd_config

COPY supervisord.conf /etc/supervisord.conf

RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N '' \
&& ssh-keygen -t dsa  -f /etc/ssh/ssh_host_dsa_key -N '' \
&& ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N '' \
&& chmod 600 /etc/ssh/*

EXPOSE 80 22
CMD ["/usr/bin/supervisord", "--configuration=/etc/supervisord.conf"] \
