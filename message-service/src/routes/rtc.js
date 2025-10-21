// routes/rtc.js
// RTC (Real-Time Communication) 路由

const express = require('express');
const router = express.Router();
const livekitController = require('../controllers/livekitController');

// POST /api/rtc/token - 生成 LiveKit 访问令牌
router.post('/token', livekitController.generateToken);

module.exports = router;

