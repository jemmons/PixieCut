import XCTest
import PixieCut



class StateTests: XCTestCase {
  func testRandmoStateProperties() {
    var comps = URLComponents()
    
    let states: [String] = globalOAuths.map { oauthRequest in
      comps.query = oauthRequest.authRequest.url?.query
      
      return (comps.queryItems?.first { $0.name == "state" }?.value)!
    }

    let invalidCharacters = CharacterSet(charactersIn: "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ").inverted
    
    let looped = expectation(description: "Waiting for all the loops.")
    looped.expectedFulfillmentCount = globalOAuthCount

    states.forEach { state in
      XCTAssertNil(state.rangeOfCharacter(from: invalidCharacters), "valid characters")
      XCTAssertEqual(state.count, 42, "proper length")
      XCTAssertEqual(states.filter { $0 == state}.count, 1, "unique")

      looped.fulfill()
    }
    
    wait(for: [looped], timeout: 0)
  }
}
