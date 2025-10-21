# iOS SecretStream 分块加密上传（Swift 示例）

## 依赖
- **Swift-Sodium**（libsodium Swift 封装）：Xcode → Package Dependencies 添加：
  `https://github.com/jedisct1/swift-sodium.git`
- iOS 14+（建议）
- AppDelegate 里实现背景上传回调。

## 用法示例
```swift
// 1) 从群口令派生 32 字节密钥（与文本 E2EE 一致的盐规则）
let key = PBKDF2.deriveKey(passphrase: "你的群口令", channelName: "ios-dev")

// 2) 加密本地文件（图片/视频/任意大文件）
let encryptor = try SecretStreamFileEncryptor(key: key)
let result = try encryptor.encryptFile(inputURL: sourceURL, chunkSize: 64*1024)

// 3) 请求后端预签名 PUT
// POST https://hc.go-lv.com/api/attachments/presign
// body: { "objectKey": "rooms/ios-dev/2025/10/xx/uuid.bin", "contentType": "application/octet-stream" }
// 返回: { putUrl, getUrl, ... }

// 4) 背景上传密文文件
let uploader = PresignedUploader()
let task = uploader.put(encryptedFileURL: result.encryptedFileURL, presignedPutURL: URL(string: putUrl)!)

// 5) 通过 WS 广播元数据给对端：headerB64 / chunkSize / bytes / objectKey（或 getUrl）
