FROM debian:buster-slim AS build
#add package

RUN apt-get -y update
RUN apt-get install -y supervisor openssl build-essential libssl-dev wget nano iputils-ping
RUN mkdir -p /var/log/supervisor

RUN export PS1="squid-server $PS1"
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

WORKDIR /apps/
RUN wget -O - http://www.squid-cache.org/Versions/v4/squid-4.13.tar.gz | tar zxfv - \
    && CPU=$(( `nproc --all`-1 )) \
    && cd /apps/squid-4.13/ \
    && ./configure --prefix=/apps/squid --disable-arch-native -enable-icap-client --enable-ssl \
	--enable-delay-pools \
	--with-openssl --enable-ssl-crtd --enable-follow-x-forwarded-for \
        --enable-auth-basic="DB,fake,getpwnam,NCSA,NIS" \
        --enable-auth-digest="file"  \
    && make -j$CPU \
    && make install \
    && cd /apps \
    && rm -rf /apps/squid-4.13
ADD . /apps/


# ** Add user
RUN chown -R nobody:nogroup /apps/
RUN useradd -m squid
RUN usermod -G squid squid
RUN mkdir -p  /apps/squid/var/lib/
RUN chown -R squid:squid /apps/squid/libexec/security_file_certgen
RUN chmod -R 750 /apps/squid/libexec/security_file_certgen
RUN chgrp -R 0 /apps && chmod -R g=u /apps

# ** Remove inusable packages
RUN apt-get remove -y --force-yes --auto-remove build-essential gcc g++
RUN apt-get purge --auto-remove build-essential

# ** Clean
RUN apt-get clean && \
    apt-get autoclean
RUN rm -rf /var/lib/apt/lists/*

# ** LANGUAGES
RUN mkdir -p /usr/share/squid-langpack
WORKDIR /usr/share/squid-langpack/
	RUN wget -O - http://www.squid-cache.org/Versions/langpack/squid-langpack-20201029.tar.gz | tar zxfv -

WORKDIR /apps/
# ** gencert test
RUN /apps/squid/libexec/security_file_certgen -c -s /apps/squid/var/lib/ssl_db -M 4MB
RUN /apps/squid/sbin/squid -N -f /apps/squid.conf.intercept -z
#RUN killall security_file_certgen
#RUN killall squid

EXPOSE 3128
#CMD ["/usr/bin/supervisord"]
RUN chmod +x /apps/docker-entrypoint.sh
ENTRYPOINT ["/apps/docker-entrypoint.sh"]
