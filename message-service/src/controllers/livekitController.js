// controllers/livekitController.js
// LiveKit RTC 控制器

const livekitService = require('../services/livekitService');

/**
 * 生成 LiveKit 令牌（POST /api/rtc/token）
 */
async function generateToken(req, res) {
  try {
    const { room, identity, metadata } = req.body || {};
    
    if (!room || !identity) {
      return res.status(400).json({ error: 'room & identity required' });
    }
    
    const result = await livekitService.generateAccessToken(room, identity, metadata);
    res.json(result);
    
  } catch (e) {
    console.error('rtc token error:', e);
    
    if (e.message === 'LiveKit not configured') {
      return res.status(500).json({ error: 'livekit not configured' });
    }
    
    res.status(500).json({ error: 'token failed' });
  }
}

module.exports = {
  generateToken,
};

