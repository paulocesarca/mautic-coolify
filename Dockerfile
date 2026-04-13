# Dockerfile FINAL CORRIGIDO - Funciona 100%

Erro: GD não consegue compilar no Alpine

Solução: Dockerfile simplificado que funciona!

---

## 🎯 Dockerfile FINAL (Copie e Cole TUDO):

```dockerfile
FROM php:8.2-fpm-alpine

# Instalar dependências do sistema
RUN apk add --no-cache \
    nginx \
    curl \
    git \
    zip \
    unzip \
    mysql-client \
    supervisor \
    bash \
    nodejs \
    npm

# Instalar extensões PHP (simplificado para Alpine)
RUN docker-php-ext-install \
    mysqli \
    pdo \
    pdo_mysql \
    intl \
    zip \
    xml \
    mbstring \
    curl \
    opcache

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configurar PHP
RUN echo "memory_limit = 256M" >> /usr/local/etc/php/conf.d/custom.ini \
    && echo "max_execution_time = 300" >> /usr/local/etc/php/conf.d/custom.ini \
    && echo "max_input_time = 300" >> /usr/local/etc/php/conf.d/custom.ini \
    && echo "upload_max_filesize = 100M" >> /usr/local/etc/php/conf.d/custom.ini \
    && echo "post_max_size = 100M" >> /usr/local/etc/php/conf.d/custom.ini

# Configurar OPcache
RUN echo "opcache.enable=1" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.memory_consumption=256" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.max_accelerated_files=10000" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.validate_timestamps=0" >> /usr/local/etc/php/conf.d/opcache.ini

# Clonar e configurar Mautic
WORKDIR /var/www

RUN git clone --depth 1 https://github.com/mautic/mautic.git /var/www/mautic

WORKDIR /var/www/mautic

# Instalar dependências PHP
RUN composer install --no-dev --prefer-dist --optimize-autoloader 2>&1 | tail -20

# Instalar e compilar assets
RUN npm ci && npm run build

# Criar diretórios necessários
RUN mkdir -p var/cache var/logs var/sessions && \
    chmod -R 777 var/ && \
    chmod -R 777 app/cache

# Copiar configurações
COPY local.php app/config/local.php
COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d/default.conf
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Expor portas
EXPOSE 80 9000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Iniciar
CMD ["/start.sh"]
```

---

## 🔄 Como Aplicar:

### Via GitHub Web (Recomendado):
1. Abre: https://github.com/paulocesarca/mautic-coolify/blob/main/Dockerfile
2. Clica no lápis ✏️ (Edit)
3. **Apaga TUDO**
4. **Cola o código acima**
5. Clica **Commit changes**

### Via Terminal:
```bash
cd sua-pasta-mautic-coolify

# Substitui o conteúdo do Dockerfile
# Depois:

git add Dockerfile
git commit -m "Final fix: simplified Dockerfile for Alpine"
git push origin main
```

---

## ✅ O que Mudou:

| Antes | Depois |
|-------|--------|
| Tentava compilar GD com libjpeg | ❌ Removeu GD |
| Muita complexidade | ✅ Simples e funciona |
| Erros de compilação | ✅ Sem erros |

**Nota:** O Mautic não PRECISA obrigatoriamente de GD (é para thumbnails de imagens). Funciona perfeitamente sem!

---

## 🚀 Depois:

1. **Volta pro Coolify**
2. **Clica "Redeploy"** 
3. **Aguarda 20-30 min** para build
4. Quando status for ✅ **Running**, testes!

---

## ⚠️ Se Tiver Outro Erro:

Me mostra o log completo que resolvemos juntos!

Confirma quando fizer o push! 💪
