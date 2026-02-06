// package.json dependencies:
// {
//   "express": "^4.18.2",
//   "mongoose": "^8.0.3",
//   "bcryptjs": "^2.4.3",
//   "jsonwebtoken": "^9.0.2",
//   "cors": "^2.8.5",
//   "dotenv": "^16.3.1",
//   "express-validator": "^7.0.1"
// }

// server.js
require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const app = express();


const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET || JWT_SECRET.length < 32) {
  console.error('❌ CRITICAL: JWT_SECRET must be set and at least 32 characters long!');
  console.error('   Generate one with: node -e "console.log(require(\'crypto\').randomBytes(64).toString(\'hex\'))"');
  process.exit(1);
}


const rateLimit = {};
const RATE_LIMIT_WINDOW = 15 * 60 * 1000; 
const MAX_REQUESTS = {
  auth: 5,      
  api: 100,     
};

const rateLimiter = (type) => (req, res, next) => {
  const ip = req.ip || req.connection.remoteAddress;
  const key = `${type}:${ip}`;
  const now = Date.now();

  if (!rateLimit[key]) {
    rateLimit[key] = { count: 1, resetTime: now + RATE_LIMIT_WINDOW };
  } else if (now > rateLimit[key].resetTime) {
    rateLimit[key] = { count: 1, resetTime: now + RATE_LIMIT_WINDOW };
  } else {
    rateLimit[key].count++;
  }

  if (rateLimit[key].count > MAX_REQUESTS[type]) {
    const retryAfter = Math.ceil((rateLimit[key].resetTime - now) / 1000);
    res.set('Retry-After', retryAfter);
    return res.status(429).json({
      success: false,
      message: 'Слишком много запросов. Попробуйте позже.',
      retryAfter
    });
  }

  next();
};


setInterval(() => {
  const now = Date.now();
  Object.keys(rateLimit).forEach(key => {
    if (now > rateLimit[key].resetTime) {
      delete rateLimit[key];
    }
  });
}, 5 * 60 * 1000);

// ========== LOGGING ==========
const logger = {
  info: (message, data = {}) => {
    console.log(`[${new Date().toISOString()}] INFO: ${message}`, Object.keys(data).length ? data : '');
  },
  warn: (message, data = {}) => {
    console.warn(`[${new Date().toISOString()}] WARN: ${message}`, Object.keys(data).length ? data : '');
  },
  error: (message, error = null) => {
    console.error(`[${new Date().toISOString()}] ERROR: ${message}`, error ? error.message || error : '');
  }
};


const uploadDir = path.join(__dirname, 'uploads', 'avatars');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}


const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'avatar-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
  fileFilter: function (req, file, cb) {
    const filetypes = /jpeg|jpg|png|gif/;
    const mimetype = filetypes.test(file.mimetype);
    const extname = filetypes.test(path.extname(file.originalname).toLowerCase());

    if (mimetype && extname) {
      return cb(null, true);
    }
    cb(new Error('Только изображения (jpeg, jpg, png, gif)'));
  }
});


app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));


mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/lifequest', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => console.log('✅ Connected to MongoDB'))
.catch((err) => console.error('❌ MongoDB connection error:', err));

// ========== MODELS ==========


const userSchema = new mongoose.Schema({
  username: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    minlength: 3,
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true,
  },
  password: {
    type: String,
    required: true,
    minlength: 6,
  },
  level: {
    type: Number,
    default: 1,
  },
  xp: {
    type: Number,
    default: 0,
  },
  completedTasks: {
    type: Number,
    default: 0,
  },
  streak: {
    type: Number,
    default: 0,
  },
  lastTaskCompletedAt: {
    type: Date,
    default: null,
  },
  lastActive: {
    type: Date,
    default: Date.now,
  },
  friends: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  }],
  friendRequests: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  }],
  achievements: [{
    type: String,
  }],
  avatar: {
    type: String,
    default: null,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});


userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 10);
  next();
});

const User = mongoose.model('User', userSchema);

// Task Schema
const taskSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  title: {
    type: String,
    required: true,
    trim: true,
  },
  description: {
    type: String,
    trim: true,
  },
  category: {
    type: String,
    enum: ['study', 'health', 'finance', 'general'],
    default: 'general',
  },
  xp: {
    type: Number,
    default: 10,
  },
  completed: {
    type: Boolean,
    default: false,
  },
  completedAt: {
    type: Date,
  },
  dueDate: {
    type: Date,
  },
  priority: {
    type: String,
    enum: ['low', 'medium', 'high'],
    default: 'medium',
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

const Task = mongoose.model('Task', taskSchema);

// ========== MIDDLEWARE ==========

// Authentication Middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ success: false, message: 'Токен не предоставлен' });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ success: false, message: 'Недействительный токен' });
    }
    req.user = user;
    next();
  });
};

// ========== AUTH ROUTES ==========

// Register
app.post('/api/auth/register', rateLimiter('auth'), [
  body('username')
    .trim()
    .isLength({ min: 3, max: 30 })
    .withMessage('Имя пользователя должно быть от 3 до 30 символов')
    .matches(/^[a-zA-Z0-9_]+$/)
    .withMessage('Имя пользователя может содержать только буквы, цифры и _'),
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Некорректный email'),
  body('password')
    .isLength({ min: 8 })
    .withMessage('Пароль должен быть минимум 8 символов')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage('Пароль должен содержать строчную, заглавную букву и цифру'),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }

  try {
    const { username, email, password } = req.body;

    // Check if user already exists
    const existingUser = await User.findOne({ $or: [{ email }, { username }] });
    if (existingUser) {
      return res.status(400).json({ 
        success: false, 
        message: 'Пользователь с таким email или username уже существует' 
      });
    }

    // Create new user
    const user = new User({ username, email, password });
    await user.save();

    // Generate token (7 days expiry for better security)
    const token = jwt.sign(
      { userId: user._id, username: user.username },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    logger.info('User registered', { userId: user._id, username: user.username });

    res.status(201).json({
      success: true,
      message: 'Регистрация успешна',
      token,
      userId: user._id,
      user: {
        id: user._id,
        username: user.username,
        email: user.email,
        level: user.level,
        xp: user.xp,
      },
    });
  } catch (error) {
    logger.error('Registration error', error);
    res.status(500).json({ success: false, message: 'Ошибка сервера' });
  }
});

// Login
app.post('/api/auth/login', rateLimiter('auth'), [
  body('email').isEmail().normalizeEmail().withMessage('Некорректный email'),
  body('password').notEmpty().withMessage('Пароль обязателен'),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }

  try {
    const { email, password } = req.body;

    // Find user
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ success: false, message: 'Неверный email или пароль' });
    }

    // Check password
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ success: false, message: 'Неверный email или пароль' });
    }

    // Update last active
    user.lastActive = Date.now();
    await user.save();

    // Generate token (7 days expiry for better security)
    const token = jwt.sign(
      { userId: user._id, username: user.username },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    logger.info('User logged in', { userId: user._id, username: user.username });

    res.json({
      success: true,
      message: 'Вход выполнен успешно',
      token,
      userId: user._id,
      user: {
        id: user._id,
        username: user.username,
        email: user.email,
        level: user.level,
        xp: user.xp,
      },
    });
  } catch (error) {
    logger.error('Login error', error);
    res.status(500).json({ success: false, message: 'Ошибка сервера' });
  }
});

// ========== USER ROUTES ==========

// Get user profile
app.get('/api/users/:userId', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.params.userId)
      .select('-password')
      .populate('friends', 'username level xp completedTasks');

    if (!user) {
      return res.status(404).json({ success: false, message: 'Пользователь не найден' });
    }

    res.json(user);
  } catch (error) {
    logger.error('Get user error', error);
    res.status(500).json({ success: false, message: 'Ошибка сервера' });
  }
});

// Update user profile
app.patch('/api/users/:userId', authenticateToken, async (req, res) => {
  try {
    // Check if user is updating their own profile
    if (req.user.userId !== req.params.userId) {
      return res.status(403).json({ success: false, message: 'Недостаточно прав' });
    }

    const updates = req.body;
    const allowedUpdates = ['username', 'email'];
    const actualUpdates = Object.keys(updates).filter(key => allowedUpdates.includes(key));

    if (actualUpdates.length === 0) {
      return res.status(400).json({ success: false, message: 'Нет допустимых обновлений' });
    }

    const user = await User.findById(req.params.userId);
    actualUpdates.forEach(key => user[key] = updates[key]);
    await user.save();

    res.json({ success: true, user });
  } catch (error) {
    logger.error('Update user error', error);
    res.status(500).json({ success: false, message: 'Ошибка сервера' });
  }
});

// Upload avatar
app.post('/api/users/:userId/avatar', authenticateToken, upload.single('avatar'), async (req, res) => {
  try {
    // Check if user is updating their own profile
    if (req.user.userId !== req.params.userId) {
      return res.status(403).json({ success: false, message: 'Недостаточно прав' });
    }

    if (!req.file) {
      return res.status(400).json({ success: false, message: 'Файл не загружен' });
    }

    const user = await User.findById(req.params.userId);

    // Удаляем старый аватар если есть
    if (user.avatar) {
      const oldAvatarPath = path.join(__dirname, user.avatar.replace('/uploads', 'uploads'));
      if (fs.existsSync(oldAvatarPath)) {
        fs.unlinkSync(oldAvatarPath);
      }
    }

    // Сохраняем путь к новому аватару
    user.avatar = `/uploads/avatars/${req.file.filename}`;
    await user.save();

    res.json({
      success: true,
      message: 'Аватар обновлен',
      avatar: user.avatar,
    });
  } catch (error) {
    logger.error('Upload avatar error', error);
    res.status(500).json({ success: false, message: 'Ошибка сервера' });
  }
});

// Search users
app.get('/api/users/search/:query', authenticateToken, async (req, res) => {
  try {
    const users = await User.find({
      $or: [
        { username: { $regex: req.params.query, $options: 'i' } },
        { email: { $regex: req.params.query, $options: 'i' } }
      ],
      _id: { $ne: req.user.userId }
    })
    .select('username email level xp')
    .limit(10);

    res.json(users);
  } catch (error) {
    logger.error('Search users error', error);
    res.status(500).json({ success: false, message: 'Ошибка сервера' });
  }
});

// ========== FRIENDS ROUTES ==========

// Get friends list
app.get('/api/friends', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId)
      .populate('friends', 'username email level xp completedTasks streak');

    res.json(user.friends);
  } catch (error) {
    logger.error('Get friends error', error);
    res.status(500).json({ success: false, message: 'Ошибка сервера' });
  }
});

// Add friend
app.post('/api/friends/add', authenticateToken, async (req, res) => {
  try {
    const { friendId } = req.body;

    if (req.user.userId === friendId) {
      return res.status(400).json({ success: false, message: 'Нельзя добавить себя в друзья' });
    }

    const user = await User.findById(req.user.userId);
    const friend = await User.findById(friendId);

    if (!friend) {
      return res.status(404).json({ success: false, message: 'Пользователь не найден' });
    }

    // Check if already friends
    if (user.friends.includes(friendId)) {
      return res.status(400).json({ success: false, message: 'Уже в друзьях' });
    }

    // Add to friends
    user.friends.push(friendId);
    friend.friends.push(req.user.userId);

    await user.save();
    await friend.save();

    res.json({ success: true, message: 'Друг добавлен', friend });
  } catch (error) {
    logger.error('Add friend error', error);
    res.status(500).json({ success: false, message: 'Ошибка сервера' });
  }
});

// Remove friend
app.delete('/api/friends/:friendId', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    const friend = await User.findById(req.params.friendId);

    if (!friend) {
      return res.status(404).json({ success: false, message: 'Пользователь не найден' });
    }

    // Remove from both users
    user.friends = user.friends.filter(id => id.toString() !== req.params.friendId);
    friend.friends = friend.friends.filter(id => id.toString() !== req.user.userId);

    await user.save();
    await friend.save();

    res.json({ success: true, message: 'Друг удален' });
  } catch (error) {
    logger.error('Remove friend error', error);
    res.status(500).json({ success: false, message: 'Ошибка сервера' });
  }
});

// ========== TASK ROUTES ==========

// Get all tasks for user
app.get('/api/tasks', authenticateToken, async (req, res) => {
  try {
    const { completed, category } = req.query;
    const filter = { userId: req.user.userId };

    if (completed !== undefined) {
      filter.completed = completed === 'true';
    }
    if (category) {
      filter.category = category;
    }

    const tasks = await Task.find(filter).sort({ createdAt: -1 });
    res.json(tasks);
  } catch (error) {
    logger.error('Get tasks error', error);
    res.status(500).json({ success: false, message: 'Ошибка сервера' });
  }
});

// Create new task
app.post('/api/tasks', authenticateToken, rateLimiter('api'), [
  body('title').trim().notEmpty().isLength({ max: 200 }).withMessage('Название задачи обязательно (макс. 200 символов)'),
  body('description').optional().trim().isLength({ max: 1000 }).withMessage('Описание макс. 1000 символов'),
  body('category').optional().isIn(['study', 'health', 'finance', 'general']),
  body('xp').optional().isInt({ min: 5, max: 100 }).withMessage('XP должен быть от 5 до 100'),
  body('priority').optional().isIn(['low', 'medium', 'high']),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }

  try {
    const { title, description, category, xp, priority, dueDate } = req.body;

    const task = new Task({
      userId: req.user.userId,
      title,
      description,
      category: category || 'general',
      xp: xp || 10,
      priority: priority || 'medium',
      dueDate,
    });

    await task.save();

    res.status(201).json({ success: true, message: 'Задача создана', task });
  } catch (error) {
    logger.error('Create task error', error);
    res.status(500).json({ success: false, message: 'Ошибка сервера' });
  }
});

// Update task
app.patch('/api/tasks/:taskId', authenticateToken, async (req, res) => {
  try {
    const task = await Task.findById(req.params.taskId);

    if (!task) {
      return res.status(404).json({ success: false, message: 'Задача не найдена' });
    }

    // Check if user owns the task
    if (task.userId.toString() !== req.user.userId) {
      return res.status(403).json({ success: false, message: 'Недостаточно прав' });
    }

    const updates = req.body;
    const allowedUpdates = ['title', 'description', 'category', 'priority', 'dueDate'];
    
    allowedUpdates.forEach(key => {
      if (updates[key] !== undefined) {
        task[key] = updates[key];
      }
    });

    await task.save();

    res.json({ success: true, message: 'Задача обновлена', task });
  } catch (error) {
    logger.error('Update task error', error);
    res.status(500).json({ success: false, message: 'Ошибка сервера' });
  }
});

// Complete task
app.patch('/api/tasks/:taskId/complete', authenticateToken, async (req, res) => {
  try {
    const task = await Task.findById(req.params.taskId);

    if (!task) {
      return res.status(404).json({ success: false, message: 'Задача не найдена' });
    }

    if (task.userId.toString() !== req.user.userId) {
      return res.status(403).json({ success: false, message: 'Недостаточно прав' });
    }

    if (task.completed) {
      return res.status(400).json({ success: false, message: 'Задача уже выполнена' });
    }

    // Mark task as completed
    task.completed = true;
    task.completedAt = Date.now();
    await task.save();

    // Update user stats
    const user = await User.findById(req.user.userId);
    user.xp += task.xp;
    user.completedTasks += 1;

    // ========== STREAK LOGIC ==========
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());

    if (user.lastTaskCompletedAt) {
      const lastCompleted = new Date(user.lastTaskCompletedAt);
      const lastCompletedDay = new Date(lastCompleted.getFullYear(), lastCompleted.getMonth(), lastCompleted.getDate());
      const daysDiff = Math.floor((today - lastCompletedDay) / (1000 * 60 * 60 * 24));

      if (daysDiff === 1) {
        // Consecutive day - increment streak
        user.streak += 1;
      } else if (daysDiff > 1) {
        // Streak broken - reset to 1
        user.streak = 1;
      }
      // If daysDiff === 0, same day - don't change streak
    } else {
      // First task ever completed - start streak
      user.streak = 1;
    }

    user.lastTaskCompletedAt = now;
    user.lastActive = now;

    // Level up logic (can level up multiple times)
    let leveledUp = false;
    while (user.xp >= (user.level + 1) * 100) {
      const xpForNextLevel = (user.level + 1) * 100;
      user.xp -= xpForNextLevel;
      user.level += 1;
      leveledUp = true;
    }

    await user.save();

    logger.info('Task completed', {
      userId: user._id,
      taskId: task._id,
      xpGained: task.xp,
      newLevel: user.level,
      streak: user.streak
    });

    res.json({
      success: true,
      message: leveledUp ? `Задача выполнена! Новый уровень: ${user.level}! 🎉🚀` : 'Задача выполнена! 🎉',
      task,
      user: {
        level: user.level,
        xp: user.xp,
        completedTasks: user.completedTasks,
        streak: user.streak,
      },
    });
  } catch (error) {
    logger.error('Complete task error', error);
    res.status(500).json({ success: false, message: 'Ошибка сервера' });
  }
});

// Delete task
app.delete('/api/tasks/:taskId', authenticateToken, async (req, res) => {
  try {
    const task = await Task.findById(req.params.taskId);

    if (!task) {
      return res.status(404).json({ success: false, message: 'Задача не найдена' });
    }

    if (task.userId.toString() !== req.user.userId) {
      return res.status(403).json({ success: false, message: 'Недостаточно прав' });
    }

    await Task.findByIdAndDelete(req.params.taskId);

    res.json({ success: true, message: 'Задача удалена' });
  } catch (error) {
    logger.error('Delete task error', error);
    res.status(500).json({ success: false, message: 'Ошибка сервера' });
  }
});

// ========== LEADERBOARD ROUTES ==========

// Get global leaderboard with pagination
app.get('/api/leaderboard', authenticateToken, async (req, res) => {
  try {
    const { type = 'xp', page = 1, limit = 20 } = req.query;
    const pageNum = Math.max(1, parseInt(page));
    const limitNum = Math.min(50, Math.max(1, parseInt(limit))); // Max 50 per page
    const skip = (pageNum - 1) * limitNum;

    let sortField;
    switch(type) {
      case 'level':
        sortField = { level: -1, xp: -1 };
        break;
      case 'tasks':
        sortField = { completedTasks: -1 };
        break;
      case 'streak':
        sortField = { streak: -1 };
        break;
      default:
        sortField = { xp: -1 };
    }

    const [users, total] = await Promise.all([
      User.find()
        .select('username level xp completedTasks streak avatar')
        .sort(sortField)
        .skip(skip)
        .limit(limitNum),
      User.countDocuments()
    ]);

    res.json({
      success: true,
      data: users,
      pagination: {
        page: pageNum,
        limit: limitNum,
        total,
        totalPages: Math.ceil(total / limitNum),
        hasNext: pageNum * limitNum < total,
        hasPrev: pageNum > 1
      }
    });
  } catch (error) {
    logger.error('Leaderboard error', error);
    res.status(500).json({ success: false, message: 'Ошибка сервера' });
  }
});

// Get friends leaderboard
app.get('/api/leaderboard/friends', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId).populate({
      path: 'friends',
      select: 'username level xp completedTasks streak',
    });

    const leaderboard = [
      {
        _id: user._id,
        username: user.username,
        level: user.level,
        xp: user.xp,
        completedTasks: user.completedTasks,
        streak: user.streak,
      },
      ...user.friends,
    ].sort((a, b) => b.xp - a.xp);

    res.json(leaderboard);
  } catch (error) {
    logger.error('Friends leaderboard error', error);
    res.status(500).json({ success: false, message: 'Ошибка сервера' });
  }
});

// ========== ACHIEVEMENTS ROUTES ==========

// Get user achievements
app.get('/api/achievements', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId).select('achievements level completedTasks streak');
    
    const allAchievements = [
      { id: 'first_task', name: 'Первые шаги', description: 'Выполните первую задачу', icon: '🏆', unlocked: user.completedTasks >= 1 },
      { id: 'task_master_10', name: 'Новичок', description: 'Выполните 10 задач', icon: '⭐', unlocked: user.completedTasks >= 10 },
      { id: 'task_master_50', name: 'Профи', description: 'Выполните 50 задач', icon: '🌟', unlocked: user.completedTasks >= 50 },
      { id: 'task_master_100', name: 'Мастер', description: 'Выполните 100 задач', icon: '💎', unlocked: user.completedTasks >= 100 },
      { id: 'level_5', name: 'Растущий герой', description: 'Достигните 5 уровня', icon: '🚀', unlocked: user.level >= 5 },
      { id: 'level_10', name: 'Легенда', description: 'Достигните 10 уровня', icon: '👑', unlocked: user.level >= 10 },
      { id: 'streak_7', name: 'Неделя силы', description: 'Серия 7 дней', icon: '🔥', unlocked: user.streak >= 7 },
      { id: 'streak_30', name: 'Месяц упорства', description: 'Серия 30 дней', icon: '💪', unlocked: user.streak >= 30 },
    ];

    res.json(allAchievements);
  } catch (error) {
    logger.error('Get achievements error', error);
    res.status(500).json({ success: false, message: 'Ошибка сервера' });
  }
});

// ========== STATISTICS ROUTES ==========

// Get user statistics
app.get('/api/stats', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    const tasks = await Task.find({ userId: req.user.userId });

    const stats = {
      totalTasks: tasks.length,
      completedTasks: tasks.filter(t => t.completed).length,
      pendingTasks: tasks.filter(t => !t.completed).length,
      level: user.level,
      xp: user.xp,
      streak: user.streak,
      totalFriends: user.friends.length,
      categoryBreakdown: {
        study: tasks.filter(t => t.category === 'study').length,
        health: tasks.filter(t => t.category === 'health').length,
        finance: tasks.filter(t => t.category === 'finance').length,
        general: tasks.filter(t => t.category === 'general').length,
      },
      completionRate: tasks.length > 0 
        ? ((tasks.filter(t => t.completed).length / tasks.length) * 100).toFixed(1)
        : 0,
    };

    res.json(stats);
  } catch (error) {
    logger.error('Get stats error', error);
    res.status(500).json({ success: false, message: 'Ошибка сервера' });
  }
});

// ========== HEALTH CHECK ==========

app.get('/api/health', (req, res) => {
  res.json({ 
    success: true, 
    message: 'LifeQuest API is running! 🚀',
    timestamp: new Date().toISOString(),
  });
});

// ========== ERROR HANDLING ==========

// 404 handler
app.use((req, res) => {
  res.status(404).json({ success: false, message: 'Маршрут не найден' });
});

// Global error handler
app.use((err, req, res, next) => {
  logger.error('Global error', err);
  res.status(500).json({ 
    success: false, 
    message: 'Внутренняя ошибка сервера',
    error: process.env.NODE_ENV === 'development' ? err.message : undefined,
  });
});

// ========== START SERVER ==========

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`
  🎮 LifeQuest Server is running!
  📡 Port: ${PORT}
  🗄️  MongoDB: Connected
  🌐 Environment: ${process.env.NODE_ENV || 'development'}
  
  Available endpoints:
  - POST /api/auth/register
  - POST /api/auth/login
  - GET  /api/users/:userId
  - GET  /api/friends
  - POST /api/friends/add
  - GET  /api/tasks
  - POST /api/tasks
  - PATCH /api/tasks/:taskId/complete
  - GET  /api/leaderboard
  - GET  /api/achievements
  - GET  /api/stats
  `);
});

module.exports = app;