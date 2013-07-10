# IBOX модуль для NoDeny 49/50

Модуль для биллинговой системы NoDeny реализует протокол взаимодействия с [платежной системой IBOX](http://www.ibox.com.ua).

## Установка

- Скопировать скрипт ibox.pl в директорию /usr/local/www/apache22/cgi-bin/ibox
- При необходимости указать нужную платежную категорию в ibox.pl (category)
- Создать файл /usr/local/nodeny/module/ibox.log и установить права записи для веб-сервера
- Обеспечить доступность payu.pl через web только с адресов 213.160.149.229 и 213.160.149.230 (apache, nginx)

В качестве платежного кода используется код, который выводится у каждого абонента в его статистике внизу ("Ваш персональный платежный код: …")

## Maintainers and Authors

Yuriy Kolodovskyy (https://github.com/kolodovskyy)

## License

MIT License. Copyright 2013 [Yuriy Kolodovskyy](http://twitter.com/kolodovskyy)
