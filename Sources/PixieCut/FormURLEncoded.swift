import Foundation



// MARK: - INIT
public struct FormURLEncoded {
  public let encoded: String
  
  
  public init(encodedString: String) throws {
    // It’s important that we ensure the validity of `encoded` because giving invalid encodings to `URLComponent`’s `percentEncodedQuery` segfaults.
    guard Helper.isValidPercentEncoding(encodedString) else {
      throw Error.invalidPercentEncoding
    }
    encoded = encodedString
  }
  
  
  public init(encodedData: Data) throws {
    guard let utf8 = String(data: encodedData, encoding: .utf8) else {
      throw Error.invalidUTF8Encoding
    }
    try self.init(encodedString: utf8)
  }
  
  
  public init(items: [URLQueryItem]) {
    do {
      try self.init(encodedString: Helper.encode(items: items))
    } catch {
      preconditionFailure("We generated an invalid encoding!")
    }
  }
}



// MARK: - PUBLIC
public extension FormURLEncoded {
  func decodeString() -> String {
    guard let decoded = encoded
            .replacingOccurrences(of: "+", with: " ")
            .removingPercentEncoding else {
      preconditionFailure("Decoding of validated encoding somehow failed.")
    }
    return decoded
  }
  
  
  func decodeItems() -> [URLQueryItem] {
    var comps = URLComponents()
    comps.percentEncodedQuery = encoded.replacingOccurrences(of: "+", with: "%20")
    guard let items = comps.queryItems else {
      preconditionFailure("URLComponents with known `query` did not yield `queryItems`.")
    }
    return items
  }
}



// MARK: - ERRORS
public extension FormURLEncoded {
  enum Error: LocalizedError {
    case invalidPercentEncoding, invalidUTF8Encoding
    
    
    public var errorDescription: String? {
      switch self {
      case .invalidPercentEncoding:
        return "The content is not in x-www-form-urlencoded format."
      case .invalidUTF8Encoding:
        return "The content is not UTF-8."
      }
    }
    
    public var failureReason: String? {
      return "Encoding Error"
    }
  }
}



// MARK: - HELPER
private enum Helper {
  // Because this will be used to encode the keys and values of a query, we take the set of characters allowed in a query, generally, then remove the delimeters `=` and `&` so that they are encoded as well. We additionally remove `+` from the list of allowed characters becasue, while classically permitted in queries, must be encoded in form-urlencoded content so as not to be confused with an encoded “space” character (` ` maps to `+` in form-urlencoded content).
  // Finally, we add “space” (` `) to the permitted character list so that we can manually replace occurences of it with `+` later in the process.
  private static var formURLEncodingKeyAndValueCharacters: CharacterSet = {
    CharacterSet
      .urlQueryAllowed
      .subtracting(CharacterSet(charactersIn: "+=&"))
      .union(CharacterSet(charactersIn: " "))
  }()


  /*
   Encoding is not guaranteed as unparsable UTF-8 strings are possible (for example, one that encodes a UTF-16 [leading surrogate](https://en.wikipedia.org/wiki/UTF-16#Code_points_from_U.2B010000_to_U.2B10FFFF) but not a trailing one:
   ```
   String(bytes: [0xD8, 0x00], encoding: .utf16)?
     .addingPercentEncoding(withAllowedCharacters: .alphanumerics)
   ```
   results in `nil`.
   */
  private static func encode(_ unencoded: String) -> String? {
    return unencoded
      .addingPercentEncoding(withAllowedCharacters: formURLEncodingKeyAndValueCharacters)?
      .replacingOccurrences(of: " ", with: "+")
  }
  
  
  static func isValidPercentEncoding(_ encodedString: String) -> Bool {
    return encodedString.removingPercentEncoding != nil
  }
  
  
  static func encode(items: [URLQueryItem]) -> String {
    items
      .compactMap { item -> URLQueryItem? in
        guard let encodedName = Helper.encode(item.name) else {
          // It’s possible for encoding to fail (see `Helper.encode`, but exceptionally rare in normal usage. So we just drop it rather than `throw`ing an error.
          return nil
        }
        return URLQueryItem(name: encodedName, value: item.value.flatMap(Helper.encode))
      }
      .map {
        [$0.name, $0.value]
          .compactMap({ id in id })
          .joined(separator: "=")
      }
      .joined(separator: "&")
  }
}

