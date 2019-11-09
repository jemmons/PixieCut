import Foundation
import PixieCut


let globalOAuthCount = 2000
let globalOAuths: [OAuthRequests] = {
  (0..<globalOAuthCount).map { _ in
    OAuthRequests(
      clientID: "foo",
      authURL: URL.example,
      tokenURL: URL.example,
      redirectURL: URL.example,
      scope: "bar")
  }
}()

extension URL {
  static let example: URL = URL(string: "https://example.com")!
}
