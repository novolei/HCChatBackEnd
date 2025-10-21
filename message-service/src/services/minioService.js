// services/minioService.js
// MinIO 存储服务

const Minio = require('minio');
const { URL } = require('url');
const config = require('../config');

// 初始化 MinIO 客户端
const u = new URL(config.MINIO.ENDPOINT);
const minioClient = new Minio.Client({
  endPoint: u.hostname,
  port: u.port ? Number(u.port) : (u.protocol === 'https:' ? 443 : 80),
  useSSL: u.protocol === 'https:',
  accessKey: config.MINIO.ROOT_USER,
  secretKey: config.MINIO.ROOT_PASSWORD,
});

/**
 * 生成预签名 URL
 * @param {string} objectKey - 对象键
 * @param {string} contentType - 内容类型
 * @returns {Promise<{bucket, objectKey, putUrl, getUrl, expiresSeconds}>}
 */
async function generatePresignedUrls(objectKey, contentType = 'application/octet-stream') {
  const bucket = config.MINIO.DEFAULT_BUCKET;
  
  // 生成上传 URL（有效期 10 分钟）
  const putUrl = await minioClient.presignedPutObject(
    bucket,
    objectKey,
    600,
    { 'Content-Type': contentType }
  );
  
  // 生成下载 URL（有效期 7 天）
  const getUrl = await minioClient.presignedGetObject(
    bucket,
    objectKey,
    7 * 24 * 3600
  );
  
  return {
    bucket,
    objectKey,
    putUrl,
    getUrl,
    expiresSeconds: 600,
  };
}

module.exports = {
  generatePresignedUrls,
};

