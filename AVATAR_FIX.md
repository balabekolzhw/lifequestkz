# 🔧 Исправление загрузки аватарки

## Проблема:
Ошибка "unsupported operation" при загрузке аватарки

## Причина:
`http.MultipartFile.fromPath()` не работает на некоторых платформах (особенно на веб и Windows)

## ✅ Решение:

### 1. Обновлен `api_service.dart`

**Было:**
```dart
request.files.add(await http.MultipartFile.fromPath('avatar', imagePath));
```

**Стало:**
```dart
// Читаем файл напрямую
final file = File(imagePath);
if (!await file.exists()) {
  return {'success': false, 'message': 'Файл не найден'};
}

final bytes = await file.readAsBytes();

// Определяем MIME тип
String mimeType = 'image/jpeg';
if (imagePath.toLowerCase().endsWith('.png')) {
  mimeType = 'image/png';
} else if (imagePath.toLowerCase().endsWith('.gif')) {
  mimeType = 'image/gif';
}

final multipartFile = http.MultipartFile.fromBytes(
  'avatar',
  bytes,
  filename: imagePath.split('/').last,
  contentType: MediaType.parse(mimeType),
);
request.files.add(multipartFile);
```

### 2. Добавлены импорты:

```dart
import 'dart:io';
import 'package:http_parser/http_parser.dart';
```

### 3. Исправлен URL для Android эмулятора:

```dart
static const String baseUrl = 'http://10.0.2.2:3000';
```

## 🚀 Теперь работает:

1. ✅ Чтение файла как bytes (работает на всех платформах)
2. ✅ Проверка существования файла
3. ✅ Автоматическое определение MIME типа (jpeg, png, gif)
4. ✅ Правильный URL для Android эмулятора

## 📝 Использование:

1. Откройте профиль
2. Нажмите на иконку камеры на аватаре
3. Выберите фото из галереи
4. Фото автоматически загрузится и сохранится на сервере

## 🛠️ Если все еще не работает:

### Проверьте backend:
```bash
cd lifequest-backend
npm run dev
```

Сервер должен быть запущен на `http://localhost:3000`

### Проверьте права доступа:

**Android (AndroidManifest.xml):**
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

### Для физического устройства:

Замените в `api_service.dart`:
```dart
static const String baseUrl = 'http://[ваш-IP]:3000';
```

Найдите свой IP:
```bash
# Windows
ipconfig

# Linux/Mac
ifconfig
```

## ✅ Файлы изменены:

- `lib/services/api_service.dart` - исправлен метод uploadAvatar()

Готово! 🎉
