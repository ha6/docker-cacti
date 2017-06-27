FROM centos

MAINTAINER Fenei <babyfenei@qq.com>

ENV DB_USER=root \
    DB_PASS=xpwl@qwer@123! \
    DB_ADDRESS=172.17.0.1 \
    TIMEZONE=Asia/Shanghai
### 安装httpd
RUN \
	mkdir -p /data/logs/ && \
	curl -o /etc/yum.repos.d/CentOS-Base.repo -O http://mirrors.163.com/.help/CentOS7-Base-163.repo && \
	yum install -y epel-release && \
	yum install -y automake mariadb-devel mariadb gcc-core gzip help2man libtool make net-snmp-devel  \
	m4  openssl-devel dos2unix php php-opcache php-devel php-gd php-ldap php-mbstring php-mcrypt  \
	dejavu-fonts-common dejavu-lgc-sans-mono-fonts dejavu-sans-mono-fonts  fontpackages-filesystemfontconfig \
	php-mysqlnd php-phpunit-PHPUnit php-pecl-xdebug php-pecl-xhprof php-snmp  \
	net-snmp net-snmp-utils mariadb-devel gcc pango-devel libxml2-devel net-snmp-devel cronie \
	sendmail supervisor httpd && \
	yum clean all && \
    	rpm --rebuilddb && yum clean all

COPY container-files / 

### 安装cacti
RUN \
### 安装rrdtool
    mkdir -p /rrdtool/ && \
    #curl -o /tmp/rrdtool/rrdtool.tar.gz -O http://oss.oetiker.ch/rrdtool/pub/rrdtool-1.7.0.tar.gz && \
    tar zxvf /tmp/rrdtool/rrdtool*.tar.gz -C /rrdtool --strip-components=1 && \
    cd /rrdtool/ && ./configure --prefix=/usr/local/rrdtool && make && make install && \
    ln -s /usr/local/rrdtool/bin/rrdtool /bin/rrdtool && \
    rm -rf /tmp/rrdtool/rrdtool*.tar.gz && rm -rf /rrdtool && \
### 安装cacti
    #curl -o /tmp/cacti/cacti.tar.gz -O http://www.cacti.net/downloads/cacti-latest.tar.gz && \
    mkdir -p /cacti/log && \
    tar zxvf /tmp/cacti/cacti*.tar.gz -C /cacti --strip-components=1 && \
    touch /cacti/log/cacti.log && \
    rm -rf /tmp/cacti/cacti*.tar.gz && \
### 安装spine
    #curl -o /tmp/spine/cacti-spine.tar.gz -O http://www.cacti.net/downloads/spine/cacti-spine-latest.tar.gz && \
    mkdir -p /spine && \
    tar zxvf /tmp/spine/cacti-spine*.tar.gz -C /spine --strip-components=1 && \
    rm -f /tmp/spine/cacti-spine*.tar.gz && \
    cd /spine/ && ./configure && make && make install && \
    rm -rf /spine && \
    yum remove -y gcc mariadb-devel net-snmp-devel && \
    yum clean all

EXPOSE 80 9111
CMD ["/config/start.sh"]
