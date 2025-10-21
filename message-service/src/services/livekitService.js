// services/livekitService.js
// LiveKit 音视频服务

const { AccessToken } = require('livekit-server-sdk');
const config = require('../config');

/**
 * 生成 LiveKit 访问令牌
 * @param {string} room - 房间名
 * @param {string} identity - 用户标识
 * @param {string} metadata - 元数据（可选）
 * @returns {Promise<{livekitUrl, token}>}
 */
async function generateAccessToken(room, identity, metadata) {
  if (!config.LIVEKIT.API_KEY || !config.LIVEKIT.API_SECRET) {
    throw new Error('LiveKit not configured');
  }
  
  const at = new AccessToken(
    config.LIVEKIT.API_KEY,
    config.LIVEKIT.API_SECRET,
    {
      identity: String(identity),
      ttl: 3600,  // 1 小时
      metadata: metadata ? String(metadata) : undefined,
    }
  );
  
  // 添加房间权限
  at.addGrant({
    roomJoin: true,
    room: String(room),
    canPublish: true,
    canSubscribe: true,
    canPublishData: true,
  });
  
  const token = await at.toJwt();
  
  return {
    livekitUrl: config.LIVEKIT.WS_URL,
    token,
  };
}

module.exports = {
  generateAccessToken,
};

