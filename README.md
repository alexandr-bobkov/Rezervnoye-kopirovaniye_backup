
# Домашнее задание к занятию 3 «Резервное копирование» - Бобков Александр
<details>
<summary><b>Задание 1</b></summary>

- Составьте команду rsync, которая позволяет создавать зеркальную копию домашней директории пользователя в директорию `/tmp/backup`
- Необходимо исключить из синхронизации все директории, начинающиеся с точки (скрытые)
- Необходимо сделать так, чтобы rsync подсчитывал хэш-суммы для всех файлов, даже если их время модификации и размер идентичны в источнике и приемнике.
- На проверку направить скриншот с командой и результатом ее выполнения.

### ОТВЕТ:
# Резервное копирование домашней директории

Для создания зеркальной копии домашней директории в `/tmp/backup` с проверкой по хеш-суммам и исключением скрытых папок используется следующая команда:

```bash
rsync -av --delete --checksum --exclude='.*/' ~/ /tmp/backup/
```
Разбор параметров:

    -a (archive) — рекурсивное копирование с сохранением прав и метаданных.
    -v (verbose) — подробный вывод процесса работы.
    --delete — удаление файлов в приемнике, если они исчезли в источнике (зеркалирование).
    --checksum — принудительная проверка целостности файлов по хеш-суммам вместо сравнения по дате/размеру.
    --exclude='.*/' — игнорирование всех скрытых директорий.

<summary>Результат проверки команды на скриншоте</summary>
<img src="img/1.jpg" width = 100%>

* Добавим файл `test.txt`  и повторим создание backup

<summary>Результат проверки добавления нового созданного файла в backup</summary>
<img src="img/2.jpg" width = 100%>

</details>

------
------


<details>
<summary><b>Задание 2</b></summary>

- Написать скрипт и настроить задачу на регулярное резервное копирование домашней директории пользователя с помощью rsync и cron.
- Резервная копия должна быть полностью зеркальной
- Резервная копия должна создаваться раз в день, в системном логе должна появляться запись об успешном или неуспешном выполнении операции
- Резервная копия размещается локально, в директории `/tmp/backup`
- На проверку направить файл crontab и скриншот с результатом работы утилиты.
------

### ОТВЕТ:
### 1. Создание «умного» скрипта резервного копирования
Скрипт поддерживает два режима: интерактивный (запрашивает пути у пользователя) и автоматический (использует значения по умолчанию для cron).

```bash
#!/bin/bash

# Настройки по умолчанию (для работы через cron)
DEFAULT_SOURCE="$HOME/"
DEFAULT_TARGET="/tmp/backup"

# Проверяем, запущен ли скрипт в интерактивном режиме (есть ли терминал)
if [ -t 0 ]; then
    # Режим ручного запуска: спрашиваем пользователя
    echo "--- Интерактивный режим резервного копирования ---"
    
    read -p "Источник [$DEFAULT_SOURCE]: " SOURCE_DIR
    SOURCE_DIR=${SOURCE_DIR:-$DEFAULT_SOURCE} # Если нажать Enter, возьмет значение по умолчанию
    
    read -p "Назначение [$DEFAULT_TARGET]: " TARGET_DIR
    TARGET_DIR=${TARGET_DIR:-$DEFAULT_TARGET}
else
    # Режим cron: используем настройки по умолчанию без вопросов
    SOURCE_DIR=$DEFAULT_SOURCE
    TARGET_DIR=$DEFAULT_TARGET
fi

# Проверка источника
if [ ! -d "$SOURCE_DIR" ]; then
    logger "Backup error: Directory $SOURCE_DIR not found"
    exit 1
fi

# Создание папки назначения
mkdir -p "$TARGET_DIR"

# Запуск зеркалирования
if rsync -av --delete --checksum --exclude='.*/' "$SOURCE_DIR" "$TARGET_DIR"; then
    logger "Backup successful: $SOURCE_DIR to $TARGET_DIR"
else
    logger "Backup failed: $SOURCE_DIR to $TARGET_DIR"
fi
```
### 2. Настройка прав и планировщика cron
Чтобы скрипт запускался ежедневно в 03:00, необходимо выполнить следующее:

    chmod +x backup.sh (сделать исполняемым).
    crontab -e и добавьте строку:
```config
0 3 * * * /bin/bash /home/$(whoami)/backup.sh
```

### 3. Проверка работоспособности

- Для проверки поставил в cron выполнение каждую минуту
<summary>Настройка cron</summary>
<img src="img/3.jpg" width = 100%>

- Для просмотра лога журналов через journalctl в консоли:

```config
journalctl | grep "Backup" | tail -n 5
```
<summary>Просмотр логов через journalctl</summary>
<img src="img/4.jpg" width = 100%>










</details>

-------
-------

<details>
<summary><c>Задание 3*</c></summary>

- Настройте связку HAProxy + Nginx как было показано на лекции.
- Настройте Nginx так, чтобы файлы .jpg выдавались самим Nginx (предварительно разместите несколько тестовых картинок в директории /var/www/), а остальные запросы переадресовывались на HAProxy, который в свою очередь переадресовывал их на два Simple Python server.
- На проверку направьте конфигурационные файлы nginx, HAProxy, скриншоты с запросами jpg картинок и других файлов на Simple Python Server, демонстрирующие корректную настройку.

-------

### ОТВЕТ:


## 1. Запуск Python-серверов
- Для имитации трех бэкенд-серверов были созданы директории с уникальными файлами `index.html`. Серверы запущены на портах 8006


**Команды запуска:**
```bash
# Подготовка файлов на сервере s1 (192.168.32.129) и s2 (192.168.32.130)

#### На сервере s1
mkdir -p /home/user/s1
#### На сервере s2
mkdir -p /home/user/s2
#### На сервере s1
echo "<h1>SERVER 1</h1>" > /home/user/s1/index.html
#### На сервере s2
echo "<h1>SERVER 2</h1>" > /home/user/s2/index.html
# Запуск серверов в фоновом режиме
#### На сервере s1
cd /home/user/s1 && python3 -m http.server 8002 --bind 0.0.0.0 &
#### На сервере s2
cd /home/user/s2 && python3 -m http.server 8002 --bind 0.0.0.0 &
```
## 2. Устанавливаем NGINX на хосте 192.168.32.130, HAPRoxy остается на 192.168.32.129
```bash
sudo apt install nginx
```
- **Создаем каталог по пути /var/www/images и кладем туда картинку с расширением .jpg**

### 3. Вносим изменения в конфигурационный файл NGINX (на 192.168.32.130) ```(/etc/nginx/sites-available/default)```

```conf
server {
    # Слушать 80-й порт (стандартный для интернета)
    listen 80;

    # Имя нашего сайта. Если в браузере введут другое — Nginx может не ответить
    server_name example.local;

    # --- КАРТИНКИ (.jpg или .jpeg) ---
    # ~* означает "искать совпадение в тексте ссылки, не обращая внимания на большие/маленькие буквы"
    # \.(jpg|jpeg)$ — если ссылка заканчивается на .jpg или .jpeg
    location ~* \.(jpg|jpeg)$ {
        # Где лежат картинки на жестком диске этого сервера
        root /var/www/images;

        # Попробовать отдать файл ($uri). Если его нет — выдать ошибку 404
        try_files $uri =404;
    }

    # --- ВСЁ ОСТАЛЬНОЕ (кроме картинок) ---
    # Слэш "/" означает любой другой запрос (текст, главная страница и т.д.)
    location / {
        # Переслать запрос на другой сервер, где живет наш HAProxy
        # IP моего
        proxy_pass http://192.168.32.129:8888;

        # Передать оригинальное имя сайта (чтобы HAProxy не запутался)
        proxy_set_header Host $host;

        # Передать реальный IP-адрес пользователя (чтобы сервер видел, кто зашел)
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```
 
## 4. Вносим изменения в конфигурационный файл HAPRoxy (на 192.168.32.129) ```(/etc/haproxy/haproxy.cfg)```

```conf
# Секция FRONTEND — как мы принимаем запросы от Nginx
frontend main_frontend
    # Слушать порт 8888 на всех сетевых интерфейсах (*) этой машины
    bind *:8888
    # Работать в режиме HTTP (чтобы понимать команды браузера)
    mode http
    # Отправлять всех пришедших в "группу серверов" под названием python_servers
    default_backend python_servers

# Секция BACKEND — куда мы отправляем запросы дальше
backend python_servers
    # Режим тоже HTTP
    mode http
    # Алгоритм "по очереди" (одному, второму, одному, второму...)
    balance roundrobin
    # Первый наш Python-сервер (он тут же, на этой же машине, порт 8001)
    # check — проверять, не "упал" ли сервер
    server s1 192.168.32.129:8002 check
    # Второй наш Python-сервер (порт 8002)
    server s2 192.168.32.130:8002 check
```

## 5. Перезапускаем службы NGINX и HAPRoxy на соответсвующих серверах:
```bash
sudo systemctl restart haproxy.service
sudo systemctl restart nginx
```

## 6. Проверяем работоспособность:

<summary>Результат проверки на скриншоте</summary>
<img src="img/9.jpg" width = 100%>

<details>
<summary>Расшифровка результата на скриншоте</summary>

    Первый запрос (/3.jpg):
        HTTP/1.1 200 OK и Server: nginx.
        Вывод: Nginx сам нашел картинку в /var/www/images/ и отдал её. HAProxy в этом не участвовал. Цель достигнута.
    Второй запрос (/):
        HTTP/1.1 200 OK и Server: nginx.
        Вывод: Nginx принял запрос, понял, что это не картинка, и пробросил его на HAProxy (proxy_pass). HAProxy в свою очередь забрал ответ у Python-сервера и вернул его вам через Nginx.
        Content-Length: 29 — это как раз размер  строки в ранее созданном файле index.hrml (<h1>SERVER X</h1>).

</details>

</details>

------
------


<details>
<summary><c>Задание 4*</c></summary>

- Запустите 4 simple python сервера на разных портах.
- Первые два сервера будут выдавать страницу index.html вашего сайта example1.local (в файле index.html напишите example1.local)
- Вторые два сервера будут выдавать страницу index.html вашего сайта example2.local (в файле index.html напишите example2.local)
- Настройте два бэкенда HAProxy
- Настройте фронтенд HAProxy так, чтобы в зависимости от запрашиваемого сайта example1.local или example2.local запросы перенаправлялись на разные бэкенды HAProxy
- На проверку направьте конфигурационный файл HAProxy, скриншоты, демонстрирующие запросы к разным фронтендам и ответам от разных бэкендов.


------
### ОТВЕТ:

## 1.  Подготовка 4 серверов

- Создаю 4 папки и запускаю серверы. Использую порты 8001-8004. Порты 8001 и 8002 буду использовать на сервере с HAPRoxy чтобы не разворачивать 4 виртуальную машину


##### На сервере s1 на котором HAPRoxy (192.168.32.129) создаю 2 каталога и внутри файлы index.html с содержимым:
```bash
mkdir -p ~/site1_1 ~/site1_2
echo "<h1>Welcome to example1.local (Server 1)</h1>" > ~/site1_s1/index.html
echo "<h1>Welcome to example1.local (Server 2)</h1>" > ~/site1_s2/index.html
111
```

##### На сервере s1 запускаю python сервер на портах 8001 и 8002
```bash
cd ~/site1_s1 && python3 -m http.server 8001 --bind 0.0.0.0 &
cd ~/site1_s2 && python3 -m http.server 8002 --bind 0.0.0.0 &
```

##### На сервере s2 (192.168.32.130) создаю 1 каталог и внутри файлы index.html с содержимым:
```bash
mkdir -p ~/site2_s3
echo "<h1>Welcome to example2.local (Server 3)</h1>" > ~/site2_s3/index.html
```
##### На сервере s2 запускаю python сервер на порту 8003
```bash
cd ~/site2_s3 && python3 -m http.server 8003 --bind 0.0.0.0 &
```
##### На сервере s3 (192.168.32.128) создаю 1 каталог и внутри файлы index.html с содержимым:
```bash
mkdir -p ~/site2_s4
echo "<h1>Welcome to example2.local (Server 4)</h1>" > ~/site2_s4/index.html
```

##### На сервере s3 запускаю python сервер на порту 8004
```bash
cd ~/site2_s4 && python3 -m http.server 8004 --bind 0.0.0.0 &
```

## 2. Конфигурация HAProxy (на  S1)(192.168.32.129)
```conf
frontend main_frontend
    bind *:8888
    mode http

    # Настраиваем ACL для разделения по доменам
    acl is_site1 base_dom example1.local
    acl is_site2 base_dom example2.local
    # Перенаправляем на нужные бэкенды
    use_backend backend_site1 if is_site1
    use_backend backend_site2 if is_site2

# Бэкенд для example1.local (оба сервера на этой же машине)
backend backend_site1
    mode http
    balance roundrobin
    server s1 192.168.32.129:8001 check
    server s2 192.168.32.129:8002 check

# Бэкенд для example2.local (серверы на удаленных машинах)
backend backend_site2
    mode http
    balance roundrobin
    server s3 192.168.32.130:8003 check
    server s4 192.168.32.128:8004 check
```

## 3. Результат проверки
<summary>Результат проверки  на скриншоте</summary>
<img src="img/10.jpg" width = 100%>




</details>

