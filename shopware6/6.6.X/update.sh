#!/bin/bash

# Setze den Pfad zur Composer-Datei
COMPOSER_FILE="composer.json"
BACKUP_COMPOSER_FILE="composer_backup.json"

# Sicherung der aktuellen composer.json Datei
cp "$COMPOSER_FILE" "$BACKUP_COMPOSER_FILE"

# Pakete, die mit "store.shopware.com" anfangen, automatisch auslesen 
packages_to_remove=($(jq -r '.require | to_entries[] | select(.key | startswith("store.shopware.com")) | .key' "$COMPOSER_FILE"))

# Temporär entfernen der Pakete
for package in "${packages_to_remove[@]}"; do
    /usr/bin/php8.3 /usr/bin/composer remove --no-update "$package"
done

curl -o ./bin/console https://raw.githubusercontent.com/shopware/shopware/v6.6.0.0/bin/shopware
curl -o ./public/index.php https://raw.githubusercontent.com/shopware/shopware/v6.6.0.0/public/index.php

# Update der gewünschten Shopware-Pakete durchführen
/usr/bin/php8.3 /usr/bin/composer require -W \
    shopware/core:6.6.0.0 \
    shopware/administration:6.6.0.0 \
    shopware/elasticsearch:6.6.0.0 \
    shopware/storefront:6.6.0.0

# Entfernte Pakete wieder hinzufügen
for package in "${packages_to_remove[@]}"; do
    echo "$package"
done

# Entfernte Pakete wieder hinzufügen
for package in "${packages_to_remove[@]}"; do
    /usr/bin/php8.3 /usr/bin/composer require "$package" -W
done


# Nach dem Hinzufügen der Pakete erneut aktualisieren
/usr/bin/php8.3 /usr/bin/composer update --ignore-platform-reqs 

echo "Update abgeschlossen. composer.json wurde wiederhergestellt."

php bin/console system:update:finish -vvvv

php bin/console plugin:update:all
