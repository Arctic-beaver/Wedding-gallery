# Wedding Gallery Site

Статический свадебный сайт-галерея.

## Структура фото

```text
public/photos/
  thumbs/       маленькие превью .webp
  full/         большие версии для просмотра .webp
  downloads/
    jpg/        файлы для скачивания по одной .jpg
    wedding-all.zip
```

## Как добавить фото

1. Скопируйте превью в `public/photos/thumbs/`.
2. Скопируйте большие web-версии в `public/photos/full/`.
3. Скопируйте версии для скачивания в `public/photos/downloads/jpg/`.
4. Создайте архив `wedding-all.zip` и положите его в `public/photos/downloads/`.
5. Обновите список файлов в `src/photos.js`.

## Запуск через Docker

```bash
docker build -t wedding-gallery .
docker run -d --name wedding-gallery -p 80:80 wedding-gallery
```
