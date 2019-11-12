import XCTest
import PixieCut



class CodeTests: XCTestCase {
  func testCodeChallenges() {
    var comps = URLComponents()
    
    let codeVerifiers: [String] = globalOAuths.map { oauthRequest in
      comps.query = oauthRequest.authRequest.url?.query
      return (comps.queryItems?.first { $0.name == "code_challenge" }?.value)!
    }
    
    let invalidCharaters = CharacterSet(charactersIn: "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-_").inverted
    
    let looped = expectation(description: "Waiting for all the loops.")
    looped.expectedFulfillmentCount = globalOAuthCount

    codeVerifiers.forEach { codeVerifier in
      XCTAssertNil(codeVerifier.rangeOfCharacter(from: invalidCharaters))
      XCTAssertEqual(codeVerifier.count, 43)
      looped.fulfill()
    }

    wait(for: [looped], timeout: 0)
  }
  
  
  func testVerifierMatchesChallenge() {
    var comps = URLComponents()
    globalOAuths.forEach { oauth in
      comps.query = oauth.authRequest.url?.query
      let challenge = (comps.queryItems?.first { $0.name == "code_challenge" }?.value)!
      let state = (comps.queryItems?.first { $0.name == "state" }?.value)!
      
      let tokenReq = try! oauth.makeTokenRequest(callback: URL(string: "https://example.com?code=123&state=" + state)!)
      comps.query = String(data: tokenReq.httpBody!, encoding: .utf8)
      let verifier = (comps.queryItems?.first {$0.name == "code_verifier"}?.value)!
      XCTAssertEqual(challenge, DigestHelper.base64SHA256(from: verifier))
    }
  }

}
