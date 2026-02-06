# 🚀 Запуск LifeQuest Backend

## Шаг 1: Установите зависимости

```bash
npm install
```

## Шаг 2: Убедитесь что MongoDB запущен

```bash
# Windows (откройте новое окно терминала)
mongod

# Linux/Mac
sudo systemctl start mongod
```

## Шаг 3: Запустите сервер

### Режим разработки (с автоперезагрузкой):
```bash
npm run dev
```

### Обычный режим:
```bash
npm start
```

Сервер запустится на **http://localhost:3000**

## ✅ Проверка

Откройте в браузере: http://localhost:3000/api/health

Должны увидеть:
```json
{
  "success": true,
  "message": "LifeQuest API is running! 🚀"
}
```

## 📝 Доступные endpoints:

- `POST /api/auth/register` - Регистрация
- `POST /api/auth/login` - Вход
- `GET /api/users/:userId` - Профиль пользователя
- `POST /api/users/:userId/avatar` - Загрузка аватарки
- `GET /api/friends` - Список друзей
- `POST /api/friends/add` - Добавить друга
- `DELETE /api/friends/:friendId` - Удалить друга
- `GET /api/tasks` - Список задач
- `POST /api/tasks` - Создать задачу
- `PATCH /api/tasks/:taskId/complete` - Выполнить задачу
- `DELETE /api/tasks/:taskId` - Удалить задачу
- `GET /api/leaderboard/friends` - Рейтинг друзей
- `GET /api/stats` - Статистика

## 🔧 Настройка

Файл `.env`:
```
MONGODB_URI=mongodb://localhost:27017/lifequest
JWT_SECRET=bhjfgfkgjlg
PORT=3000
NODE_ENV=development
```

## 📂 Загруженные файлы

Аватарки сохраняются в: `lifequest-backend/uploads/avatars/`
