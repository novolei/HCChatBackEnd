// middleware/errorHandler.js
// 统一错误处理中间件

function errorHandler(err, _req, res, _next) {
  console.error('unhandled error:', err);
  res.status(500).json({ error: 'internal' });
}

module.exports = errorHandler;

