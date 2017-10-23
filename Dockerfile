FROM idocking/ubuntu-sshd:16.04


ENV CODENAME           xenial
ENV NGINX_MAIN_VERSION 1.12.2
ENV NGINX_SUB_VERSION  1
ENV NJS_VERSION        1.12.2.0.1.14-1~xenial

## For chinese user
RUN sed -i "s/http:\/\/archive\.ubuntu\.com/http:\/\/mirrors\.aliyun\.com/g" /etc/apt/sources.list

COPY nginx/rules /tmp/rules
COPY entrypoint /

RUN set -x \
	&& echo "deb http://nginx.org/packages/ubuntu/ ${CODENAME} nginx" >> /etc/apt/sources.list \
	&& echo "deb-src http://nginx.org/packages/ubuntu/ ${CODENAME} nginx" >> /etc/apt/sources.list \
	&& mkdir -p /tmp/nginx \
	&& wget -q https://nginx.org/keys/nginx_signing.key -O /tmp/nginx/nginx_signing.key \
	&& apt-key add /tmp/nginx/nginx_signing.key \
	&& mkdir -p /tmp/nginx/modules \
	&& git -C /tmp/nginx/modules clone https://github.com/kvspb/nginx-auth-ldap.git \
	&& nginxPackages=" \
		nginx=${NGINX_MAIN_VERSION}-${NGINX_SUB_VERSION} \
		nginx-module-xslt=${NGINX_MAIN_VERSION}-${NGINX_SUB_VERSION} \
		nginx-module-geoip=${NGINX_MAIN_VERSION}-${NGINX_SUB_VERSION} \
		nginx-module-image-filter=${NGINX_MAIN_VERSION}-${NGINX_SUB_VERSION} \
		nginx-module-njs=${NJS_VERSION} \
	" \
	&& savedAptMark="$(apt-mark showmanual)" \
	&& apt-get update \
	&& apt-get install -y libldap-dev dh-systemd \
	&& apt-get build-dep -y $nginxPackages \
    && mkdir -p /tmp/nginx/source \
	&& chmod 777 /tmp/nginx/source \
	&& cd /tmp/nginx/source \
	&& apt-get source nginx \
	&& tar -zxvf nginx_${NGINX_MAIN_VERSION}.orig.tar.gz \
	&& mv /tmp/rules /tmp/nginx/source/nginx-${NGINX_MAIN_VERSION}/debian/rules \
	&& cd nginx-${NGINX_MAIN_VERSION} \
	&& dpkg-buildpackage -uc -b \
	&& apt-mark showmanual | xargs apt-mark auto > /dev/null \
	&& { [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; } \
	&& apt-get purge -y --auto-remove \
	&& apt-get clean \
	&& dpkg -i ../nginx_${NGINX_MAIN_VERSION}-${NGINX_SUB_VERSION}~${CODENAME}_amd64.deb \
	&& nginx -V \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && chmod +x /entrypoint

EXPOSE 80

ENTRYPOINT ["/entrypoint"]

CMD ["/usr/sbin/sshd", "-D"]