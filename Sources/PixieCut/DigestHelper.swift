import Foundation
import CommonCrypto



public enum DigestHelper {
  private static func urlSafeBase64(from data: Data) -> String {
    return data
      .base64EncodedString()
      .trimmingCharacters(in: CharacterSet(charactersIn: "="))
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
  }
  
  
  private static func sha256(from data: Data) -> Data {
    var sha = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    data.withUnsafeBytes { pointer in
      _ = CC_SHA256(pointer.baseAddress, CC_LONG(data.count), &sha)
    }
    return Data(sha)
  }
  
  
  public static func base64SHA256(from codeVerifier: String) -> String {
    return urlSafeBase64(from:
      sha256(from:
        Data(codeVerifier.utf8)
      )
    )
  }
}
