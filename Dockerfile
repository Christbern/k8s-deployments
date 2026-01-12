# Étape 1 : Builder avec Composer (image temporaire)
FROM php:8.1-fpm AS builder

# Installer extensions système nécessaires pour Laravel + Composer
RUN apt-get update && apt-get install -y \
    git unzip zip libzip-dev libpng-dev libjpeg-dev libfreetype6-dev libonig-dev \
    libxml2-dev curl \
 && docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install pdo_mysql mbstring gd xml zip bcmath \
 && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copier tout le code (important pour autoload.files)
COPY . .

# Installer les dépendances PHP
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Étape 2 : Image finale PHP-FPM (pas de Composer)
FROM php:8.1-fpm

# Installer extensions nécessaires pour Laravel
RUN apt-get update && apt-get install -y \
    libzip-dev libpng-dev libjpeg-dev libfreetype6-dev libonig-dev libxml2-dev curl \
 && docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install pdo_mysql mbstring gd xml zip bcmath \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

# Copier tout depuis le builder (code + vendor)
COPY --from=builder /app /var/www/html

# Créer les dossiers storage et bootstrap/cache
RUN mkdir -p storage/framework/{sessions,views,cache} bootstrap/cache \
 && chown -R www-data:www-data storage bootstrap/cache \
 && chmod -R 775 storage bootstrap/cache

EXPOSE 9000

CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
#CMD ["php-fpm"]
