apt-get install libpcre3 libpcre3-dev libssl-dev libxml2-dev libxslt-dev libgeoip-dev

addgroup --system nginx
adduser --system --home /var/run/nginx --no-create-home --disabled-password --disabled-login --ingroup nginx nginx

export TMP_DIR=$(mktemp -d)

cd $TMP_DIR

wget http://nginx.org/download/nginx-1.5.10.tar.gz
wget http://luajit.org/download/LuaJIT-2.0.2.tar.gz

tar -zxf LuaJIT-2.0.2.tar.gz

cd LuaJIT-2.0.2 && make && make install && cd ..

git clone https://github.com/agentzh/lua-resty-redis

cd lua-resty-redis && LUA_VERSION=5.1 make install && cd ..

git clone https://github.com/chaoslawful/lua-nginx-module
git clone https://github.com/simpl/ngx_devel_kit

tar -zxf nginx-1.5.10.tar.gz

cd nginx-1.5.10

export CFLAGS="-O3 -pipe"
export LUAJIT_LIB=/usr/local/lib/lib
export LUAJIT_INC=/usr/local/include/luajit-2.0

./configure   \
--user=nginx \
--group=nginx \
--prefix=/etc/nginx \
--sbin-path=/usr/sbin/nginx \
--conf-path=/etc/nginx/nginx.conf \
--error-log-path=/var/log/nginx/error.main.log \
--http-log-path=/var/log/nginx/access.main.log \
--pid-path=/var/run/nginx/nginx.pid \
--lock-path=/var/lock \
--http-client-body-temp-path=/var/cache/nginx/client \
--http-proxy-temp-path=/var/cache/nginx/proxy \
--http-fastcgi-temp-path=/var/cache/nginx/fastcgi \
--http-uwsgi-temp-path=/var/cache/nginx/uwcgi \
--http-scgi-temp-path=/var/cache/nginx/scgi \
--with-http_addition_module \
--with-http_geoip_module \
--with-http_gzip_static_module \
--with-http_realip_module \
--with-http_stub_status_module \
--with-http_ssl_module \
--with-http_sub_module \
--with-http_xslt_module \
--with-http_spdy_module \
--add-module=../ngx_devel_kit \
--add-module=../lua-nginx-module && make

mkdir -p /var/{run/nginx,log/nginx,cache/nginx/client,cache/nginx/proxy,cache/nginx/fastcgi,cache/nginx/uwcgi,cache/nginx/scgi}
chown nginx:nginx /var/{run/nginx,log/nginx,cache/nginx/client,cache/nginx/proxy,cache/nginx/fastcgi,cache/nginx/uwcgi,cache/nginx/scgi}
mkdir -p /etc/nginx/{conf.d,vhost.d,html}

make install
