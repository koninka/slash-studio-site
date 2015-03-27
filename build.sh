#!/bin/bash

set_permissions() {
   sudo chmod -R ug+rw .
   if egrep -i "^www-data" /etc/group > /dev/null; then
      sudo chown -R $USER:www-data .
   fi
   sudo chmod -R a+rw app/cache app/logs
}

echo -n "Would you like to istall dependencies from composer.json (\"y\" or \"n\", default: \"n\"): "
read answer
if [ "$answer" = "y" ]; then
   composer install
fi

set_permissions

if [[ ! -z "$SLASH_PROD" && $SLASH_PROD -eq 1 ]]; then
   php app/console cache:clear --env=prod --no-debug
   os=$(uname)
   if [ "$os" = "Linux" ]; then
      sed -i 's/app_dev/app/g' web/.htaccess
   elif [ "$os" = "Darwin" ]; then
      sed -i '' 's/app_dev/app/g' web/.htaccess
   fi
   php app/console doctrine:schema:update --force
   composer dump-autoload --optimize
   php app/console assetic:dump --env=prod --no-debug
else
   php app/console cache:clear --env=dev
   php app/console doctrine:database:drop --force
   php app/console doctrine:database:create
   php app/console doctrine:schema:create
   # php app/console doctrine:fixtures:load
fi

php app/console assets:install web --symlink
php app/console mopa:bootstrap:symlink:less
php app/console mopa:bootstrap:install:font

set_permissions

echo "Done!"
