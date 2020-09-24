import Foundation
import PixieCut


let globalOAuthCount = 2000
let globalOAuths: [OAuthSession] = {
  (0..<globalOAuthCount).map { _ in
    OAuthSession(
      clientID: "foo",
      authURL: .example,
      tokenURL: .example,
      redirectURL: .example,
      scope: ["bar"])
  }
}()


extension URL {
  static let example: URL = URL(string: "https://example.com")!
}
