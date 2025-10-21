// routes/attachments.js
// 附件路由

const express = require('express');
const router = express.Router();
const minioController = require('../controllers/minioController');

// POST /api/attachments/presign - 生成预签名 URL
router.post('/presign', minioController.presignAttachment);

module.exports = router;

