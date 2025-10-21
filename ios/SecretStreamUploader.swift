// ios/SecretStreamUploader.swift
// Swift example: libsodium SecretStream (XChaCha20-Poly1305) chunked encryption + background PUT upload
//
// Requirements:
// - Swift 5.7+
// - Swift Package: https://github.com/jedisct1/swift-sodium (add as dependency)
// - iOS target: 14+ (recommended)
// - Implement AppDelegate's background URLSession handler (see ios/README.md).

import Foundation
import Sodium
import CryptoKit

public struct SecretStreamEncryptionResult {
    /// Base64-encoded libsodium SecretStream header (send to peer + backend metadata)
    public let headerBase64: String
    /// Path/URL of the encrypted output file to upload
    public let encryptedFileURL: URL
    /// Chunk size used during encryption
    public let chunkSize: Int
    /// Total ciphertext bytes (including per-chunk overhead)
    public let totalCipherBytes: Int64
}

public enum SecretStreamUploaderError: Error {
    case keyLengthInvalid
    case fileIOFailed(String)
    case encryptionFailed(String)
    case uploadFailed(String)
}

/// Derive a 32-byte key from a passphrase using PBKDF2-HMAC-SHA256
/// Salt scheme: "hc:" + channelName  (same as text E2EE)
public struct PBKDF2 {
    public static func deriveKey(passphrase: String, channelName: String, iterations: Int = 250_000) -> Data {
        let salt = Data(("hc:" + channelName).utf8)
        return pbkdf2HMACSHA256(password: Data(passphrase.utf8),
                                salt: salt,
                                iterations: iterations,
                                derivedKeyLength: 32)
    }

    // Pure-Swift PBKDF2(HMAC-SHA256) using CryptoKit
    private static func pbkdf2HMACSHA256(password: Data, salt: Data, iterations: Int, derivedKeyLength: Int) -> Data {
        precondition(iterations > 0 && derivedKeyLength > 0)

        func INT(_ i: UInt32) -> Data { withUnsafeBytes(of: i.bigEndian) { Data($0) } }

        func hmac(_ key: Data, _ message: Data) -> Data {
            let sk = SymmetricKey(data: key)
            let mac = HMAC<SHA256>.authenticationCode(for: message, using: sk)
            return Data(mac)
        }

        var derived = Data()
        var blockIndex: UInt32 = 1
        while derived.count < derivedKeyLength {
            let u1 = hmac(password, salt + INT(blockIndex))
            var t = u1
            if iterations > 1 {
                var uPrev = u1
                for _ in 2...iterations {
                    let u = hmac(password, uPrev)
                    // XOR accumulate
                    var x = Data(count: min(t.count, u.count))
                    for i in 0..<x.count { x[i] = t[i] ^ u[i] }
                    t = x
                    uPrev = u
                }
            }
            derived.append(t)
            blockIndex += 1
        }
        return derived.prefix(derivedKeyLength)
    }
}

public final class SecretStreamFileEncryptor {
    private let key: Data
    private let sodium = Sodium()

    /// key must be 32 bytes
    public init(key: Data) throws {
        guard key.count == 32 else { throw SecretStreamUploaderError.keyLengthInvalid }
        self.key = key
    }

    /// Encrypt a file to a new temporary file using SecretStream (XChaCha20-Poly1305).
    public func encryptFile(inputURL: URL, chunkSize: Int = 64 * 1024) throws -> SecretStreamEncryptionResult {
        guard let inHandle = try? FileHandle(forReadingFrom: inputURL) else {
            throw SecretStreamUploaderError.fileIOFailed("cannot open input file")
        }
        defer { try? inHandle.close() }

        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".enc")
        guard FileManager.default.createFile(atPath: tmpURL.path, contents: nil) else {
            throw SecretStreamUploaderError.fileIOFailed("cannot create output file")
        }
        guard let outHandle = try? FileHandle(forWritingTo: tmpURL) else {
            throw SecretStreamUploaderError.fileIOFailed("cannot open output file")
        }
        defer { try? outHandle.close() }

        // Init push stream
        var keyBytes = key.bytes
        guard var stateHeader = sodium.secretStream.xchacha20poly1305.initPush(key: keyBytes) else {
            throw SecretStreamUploaderError.encryptionFailed("initPush failed")
        }
        let header = Data(stateHeader.header)
        var state = stateHeader.state

        let bufSize = max(4096, chunkSize)
        var totalCipher: Int64 = 0

        while true {
            let chunk = (try? inHandle.read(upToCount: bufSize)) ?? Data()
            if chunk.count == 0 {
                // finalize with empty final tag
                guard let sealed = sodium.secretStream.xchacha20poly1305.push(stream: &state,
                                                                              message: Data().bytes,
                                                                              tag: .final) else {
                    throw SecretStreamUploaderError.encryptionFailed("finalize failed")
                }
                try outHandle.write(contentsOf: Data(sealed))
                totalCipher += Int64(sealed.count)
                break
            } else {
                // normal chunk (not necessarily final — loop ends when read returns 0)
                guard let sealed = sodium.secretStream.xchacha20poly1305.push(stream: &state,
                                                                              message: chunk.bytes,
                                                                              tag: .message) else {
                    throw SecretStreamUploaderError.encryptionFailed("push failed")
                }
                try outHandle.write(contentsOf: Data(sealed))
                totalCipher += Int64(sealed.count)
            }
        }

        return SecretStreamEncryptionResult(
            headerBase64: header.base64EncodedString(),
            encryptedFileURL: tmpURL,
            chunkSize: bufSize,
            totalCipherBytes: totalCipher
        )
    }
}

// MARK: - Background PUT upload using presigned URL
public final class PresignedUploader: NSObject, URLSessionTaskDelegate, URLSessionDelegate {
    private var session: URLSession!

    public override init() {
        super.init()
        let cfg = URLSessionConfiguration.background(withIdentifier: "com.yourapp.uploads.\(UUID().uuidString)")
        cfg.isDiscretionary = false
        cfg.sessionSendsLaunchEvents = true
        self.session = URLSession(configuration: cfg, delegate: self, delegateQueue: nil)
    }

    /// Start a background PUT upload to an S3/MinIO presigned URL.
    public func put(encryptedFileURL: URL, presignedPutURL: URL, contentType: String = "application/octet-stream") -> URLSessionUploadTask {
        var req = URLRequest(url: presignedPutURL)
        req.httpMethod = "PUT"
        req.setValue(contentType, forHTTPHeaderField: "Content-Type")
        let task = session.uploadTask(with: req, fromFile: encryptedFileURL)
        task.resume()
        return task
    }

    // Observe progress if needed
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64,
                           totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        // print("progress: \(totalBytesSent)/\(totalBytesExpectedToSend)")
    }
}

// MARK: - Utilities
private extension Data {
    var bytes: [UInt8] { [UInt8](self) }
}
