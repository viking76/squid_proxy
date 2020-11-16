#!/bin/bash

sed -i 's/"squid-langpack/en"/'"squid-langpack/"${LANG}'/g' /apps/squid.conf.intercept
sed -i 's/3128/'${PORT}'/g' /apps/squid.conf.intercept

#if [[ "${USE_SSL:-0}" == "1" ]] ; then
#    sed -i 's/ssl: false/ssl: true/g' /usr/src/app/web/vue/dist/UIconfig.js
#fi

exec /apps/squid/sbin/squid -N -f /apps/squid.conf.intercept -z
