# Свадебная фотогалерея

Статический сайт с тремя разделами: «Венчание», «Роспись» и «Гуляния». Внутри каждого раздела избранные кадры показываются крупной журнальной подборкой, а остальные — компактной сеткой ниже.

## Куда положить фотографии

Создайте внутри проекта папку `incoming` и разложите исходники так:

```text
incoming/
  venchanie/
    best/           лучшие фотографии венчания
    rest/           остальные фотографии венчания
  rospis/
    best/           лучшие фотографии с росписи
    rest/           остальные фотографии с росписи
  gulyania/
    best/           лучшие фотографии с прогулки, театра и ресторана
    rest/           остальные фотографии этого раздела
  heroes/
    rospis.jpg      заглавное фото раздела «Роспись»
    gulyania.jpg    заглавное фото раздела «Гуляния»
```

Оптимально положить в `best` примерно 6–12 кадров на раздел. Порядок задаётся именами файлов, поэтому любимые фотографии удобно назвать так:

```text
01-first-look.jpg
02-portrait.jpg
03-family.jpg
```

Если фотографии пока лежат прямо в `venchanie`, `rospis` или `gulyania`, скрипт не потеряет их и автоматически отнесёт к `rest`. Но для понятного порядка лучше разложить всё по двум подпапкам.

Для заглавных фотографий подходят JPG, JPEG, PNG, WebP и TIFF. Готовить WebP вручную не нужно: скрипт создаст его сам и положит в `src/images/heroes/`. Чтобы заменить обложку венчания, добавьте `incoming/heroes/venchanie.jpg`.

Папка `incoming` не попадёт в Git — тяжёлые исходники останутся только на ноутбуке.

## Запуск на Windows

Откройте PowerShell в папке `wedding-gallery-site` и выполните:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-photos.ps1
```

Если три папки находятся в другом месте, укажите их общую родительскую папку:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-photos.ps1 -SourceRoot "D:\Фото\Свадьба"
```

В `D:\Фото\Свадьба` в этом примере должны лежать `venchanie`, `rospis`, `gulyania` и при необходимости `heroes`.

Скрипту нужен ImageMagick. Установить его достаточно один раз:

```powershell
winget install ImageMagick.ImageMagick
```

## Что создаёт скрипт

```text
public/photos/
  venchanie/
    best/
      thumbs/        WebP до 1600 px для крупной подборки
      full/          WebP до 2800 px для полноэкранного просмотра
      originals/     исходники без уменьшения
    rest/
      thumbs/
      full/
      originals/
  rospis/             такая же структура
  gulyania/           такая же структура
  downloads/
    venchanie.zip     best + rest раздела
    rospis.zip        best + rest раздела
    gulyania.zip      best + rest раздела
    all-photos.zip    все три раздела
```

Также скрипт полностью обновляет `src/photos.js`. Список фотографий вручную редактировать не требуется. Каждый повторный запуск пересобирает результат с нуля, но не меняет исходники в `incoming`.

После подготовки новых заглавных фотографий Docker-образ нужно пересобрать: файлы из `src/images` копируются внутрь образа во время `docker build`. Простой перезапуск старого контейнера новые обложки не подхватит.

## GitHub и Ubuntu

Код сайта загружайте в GitHub как обычно. Папка `public/photos` игнорируется Git, чтобы репозиторий не разрастался. После `git clone` или `git pull` скопируйте подготовленные фотографии с ноутбука на сервер:

```powershell
scp -r .\public\photos user@server:/srv/wedding-gallery/public/
```

Замените `user@server` и `/srv/wedding-gallery` на свои имя пользователя, адрес сервера и путь к репозиторию. Для последующих обновлений удобнее использовать `rsync` из WSL:

```bash
rsync -av --delete ./public/photos/ user@server:/srv/wedding-gallery/public/photos/
```

Важно: `src/photos.js` и подготовленные заглавные WebP нужно добавить в Git. Сами фотографии из `public/photos` передаются отдельно.

## Запуск через Docker

Сначала скопируйте `public/photos` на сервер, затем собирайте контейнер:

```bash
docker build -t wedding-gallery .
docker run -d --name wedding-gallery -p 80:80 wedding-gallery
```

Чтобы обновлять фотографии без пересборки контейнера, подключите серверную папку как том:

```bash
docker run -d --name wedding-gallery -p 80:80 \
  -v /srv/wedding-gallery/public/photos:/usr/share/nginx/html/public/photos:ro \
  wedding-gallery
```
