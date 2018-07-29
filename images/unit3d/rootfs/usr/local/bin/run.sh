#!/bin/bash

set -e

export PHP_GID
export PHP_UID
export APP_DIR
export APP_ENV

DB_HOST=${DB_HOST:-mariadb}
REDIS_HOST=${REDIS_HOST:-redis}
PHP_GID=${PHP_GID:-991}
PHP_UID=${PHP_UID:-991}
APP_DIR=${APP_DIR:-/usr/src/app}
UNIT3D_GIT=${UNIT3D_GIT:-https://github.com/HDInnovations/UNIT3D.git}
APP_ENV=${APP_ENV:-prod}

logger -s -p local0.info "[UNIT3D] Starting UNIT3D"

# Setup UNIT3D
# ---------------------------------------------------------------------------------------------
if [ ! -f "${APP_DIR}/artisan" ] ; then
  logger -s -p local0.info "[UNIT3D] Starting setup"
  git clone ${UNIT3D_GIT} ${APP_DIR}
  cd ${APP_DIR}
  chown -R ${PHP_UID}: storage bootstrap public config && find . -type d -exec chmod 0755 '{}' + -or -type f -exec chmod 0644 '{}' +
fi

cd ${APP_DIR}

if [ ! -f laravel-echo-server.json ] ; then
  logger -s -p local0.info "[UNIT3D] Setting up laravel-echo-server"
  npm install -g laravel-echo-server
  # Create echo-config
  cat <<EOT >> laravel-echo-server.json 
{
  "authHost": "http://unit3d:8888",
  "authEndpoint": "/broadcasting/auth",
  "clients": [
  ],    
  "database": "redis",
  "databaseConfig": {
    "redis": {  
      "host": "${REDIS_HOST}"
    },
    "sqlite": { 
      "databasePath": "/database/laravel-echo-server.sqlite"
    }           
  },    
  "devMode": false,
  "host": null, 
  "port": "6001",
  "protocol": "http",
  "socketio": {},
  "sslCertPath": "",
  "sslKeyPath": "",
  "sslCertChainPath": "",
  "sslPassphrase": "",
  "apiOriginAllow": {
    "allowCors": false,
    "allowOrigin": "",
    "allowMethods": "",
    "allowHeaders": ""
  }     
}
EOT

  # Create App ID
  laravel-echo-server client:add
fi

if [ ! -f .env ] ; then
  logger -s -p local0.info "[UNIT3D] Generating .env"
  # Create .env
  cp .env.example .env
fi

# Environment
# ---------------------------------------------------------------------------------------------
logger -s -p local0.info "[UNIT3D] Fixing .env"
APP_ID=$(jq -r '.clients[].appId' laravel-echo-server.json)
APP_KEY=$(jq -r '.clients[].key' laravel-echo-server.json)

sed -i -e "s/^DB_HOST=.*\$/DB_HOST=${DB_HOST}/" \
       -e "s/^DB_PASSWORD=.*\$/DB_PASSWORD=${MYSQL_PASSWORD}/" \
       -e "s/^DB_USERNAME=.*\$/DB_USERNAME=${MYSQL_USER}/" \
       -e "s/^DB_DATABASE=.*\$/DB_DATABASE=${MYSQL_DATABASE}/" \
       -e "s/^REDIS_HOST=.*\$/REDIS_HOST=${REDIS_HOST}/" \
       -e "s/^PUSHER_APP_KEY=.*\$/PUSHER_APP_KEY=${APP_KEY}/" \
       -e "s/^PUSHER_APP_ID=.*\$/PUSHER_APP_ID=${APP_ID}/" \
    .env

# Hack
sed -i -e 's/":6001"/""/' public/js/app.js

# Composer and Nodejs
# ---------------------------------------------------------------------------------------------
if [ ! -d node_modules ] ; then
  logger -s -p local0.info "[UNIT3D] composer install and npm install"
  composer install
  composer require predis/predis
  npm install
  npm install --save-dev socket.io-client
  npm run prod
fi

# Artisan
# ---------------------------------------------------------------------------------------------
if [ ! -f .key_generated ] ; then
  logger -s -p local0.info "[UNIT3D] Generating key and seeding database"
  php artisan key:generate
  php artisan migrate --seed
  touch .key_generated
fi

# Permissions
# ---------------------------------------------------------------------------------------------
logger -s -p local0.info "[UNIT3D] Fixing permissions"
chown -R ${PHP_UID}: storage bootstrap public config

# S6 WATCHDOG
# ---------------------------------------------------------------------------------------------

mkdir -p /tmp/counters

for service in _parent cron php rsyslogd; do

# Init process counters
echo 0 > /tmp/counters/$service

# Create a finish script for all services
cat > /services/$service/finish <<EOF
#!/bin/bash
# $1 = exit code from the run script
if [ "\$1" -eq 0 ]; then
  # Send a SIGTERM and do not restart the service
  logger -p local0.info "s6-supervise : stopping ${service} process"
  s6-svc -d /services/${service}
else
  COUNTER=\$((\$(cat /tmp/counters/${service})+1))
  if [ "\$COUNTER" -ge 20 ]; then
    # Permanent failure for the service, s6-supervise does not restart it
    logger -p local0.err "s6-supervise : ${service} has restarted too many times (permanent failure)"
    exit 125
  else
    echo "\$COUNTER" > /tmp/counters/${service}
  fi
fi
exit 0
EOF

done

chmod +x /services/*/finish

# LAUNCH ALL SERVICES
# ---------------------------------------------------------------------------------------------

exec s6-svscan -t0 /services

