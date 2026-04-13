#!/bin/bash
set -e

cd /var/www/mautic

echo "🔧 Aguardando banco de dados..."
until mysqladmin ping -h"${DB_HOST:-mautic-db}" -u"${DB_USER:-mautic}" -p"${DB_PASSWORD:-mautic}" --silent 2>/dev/null; do
  echo 'Aguardando MySQL...'
  sleep 2
done
echo "✅ Banco de dados disponível!"

echo "🚀 Iniciando configuração do Mautic..."

# Limpar cache
php bin/console cache:clear --env=prod --no-warmup || true

# Executar migrations
php bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration || true

# Instalar assets
php bin/console assets:install --env=prod --symlink || true

# Ajustar permissões
chmod -R 775 var/
chmod -R 775 app/cache

echo "✅ Mautic configurado!"

# Criar crontab
cat > /tmp/cron_mautic << 'EOF'
*/5 * * * * cd /var/www/mautic && php bin/console mautic:segments:update --env=prod > /dev/null 2>&1
*/5 * * * * cd /var/www/mautic && php bin/console mautic:email:send --env=prod > /dev/null 2>&1
*/5 * * * * cd /var/www/mautic && php bin/console mautic:campaigns:trigger --env=prod > /dev/null 2>&1
*/5 * * * * cd /var/www/mautic && php bin/console mautic:campaigns:update --env=prod > /dev/null 2>&1
* * * * * cd /var/www/mautic && php bin/console mautic:process --env=prod > /dev/null 2>&1
0 2 * * * cd /var/www/mautic && php bin/console mautic:maintenance:cleanup --env=prod > /dev/null 2>&1
EOF

crontab -u www-data /tmp/cron_mautic 2>/dev/null || true

# Configurar supervisor
cat > /etc/supervisor/conf.d/mautic.conf << 'SUPERVISOR'
[program:php-fpm]
command = php-fpm -F
autorestart = true
redirect_stderr = true
stdout_logfile = /var/log/php-fpm.log

[program:nginx]
command = nginx -g "daemon off;"
autorestart = true
redirect_stderr = true
stdout_logfile = /var/log/nginx.log

[program:cron]
command = /usr/sbin/crond -f -l 2
autorestart = true
redirect_stderr = true
stdout_logfile = /var/log/cron.log
SUPERVISOR

echo "📅 Iniciando serviços..."

/usr/bin/supervisord -c /etc/supervisor/supervisord.conf

echo "🎉 Mautic rodando com sucesso!"
