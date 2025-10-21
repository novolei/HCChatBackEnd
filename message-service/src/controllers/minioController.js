// controllers/minioController.js
// MinIO 附件控制器

const minioService = require('../services/minioService');

/**
 * 生成预签名 URL（POST /api/attachments/presign）
 */
async function presignAttachment(req, res) {
  try {
    const { objectKey, contentType } = req.body || {};
    
    if (!objectKey) {
      return res.status(400).json({ error: 'objectKey required' });
    }
    
    const result = await minioService.generatePresignedUrls(objectKey, contentType);
    res.json(result);
    
  } catch (e) {
    console.error('presign error:', e);
    res.status(500).json({ error: 'presign failed' });
  }
}

module.exports = {
  presignAttachment,
};

