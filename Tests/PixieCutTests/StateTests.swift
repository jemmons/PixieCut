import XCTest
import PixieCut


private var comps = URLComponents()

private let states: [String] = {
  return globalOAuths.map { oauthRequest in
    comps.query = oauthRequest.authRequest.url?.query
    
    return (comps
      .queryItems?
      .first { $0.name == "state" }?
      .value)!
  }
}()



class StateTests: XCTestCase {
  func testValidState() {
    let validCharacters = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    let looped = expectation(description: "Waiting for all the loops.")
    looped.expectedFulfillmentCount = globalOAuthCount

    XCTAssert(states.allSatisfy { state in
      looped.fulfill()
      return state.allSatisfy { validCharacters.contains($0) }
    })
    wait(for: [looped], timeout: 0)
  }
  
  
  func testUniqueState() {
    let looped = expectation(description: "Waiting for all the loops.")
    looped.expectedFulfillmentCount = globalOAuthCount

    states.forEach { state in
      XCTAssertEqual(states.filter { $0 == state}.count, 1)
      looped.fulfill()
    }
    
    wait(for: [looped], timeout: 0)
  }
  
  
  func testStateLength() {
    let looped = expectation(description: "Waiting for all the loops.")
    looped.expectedFulfillmentCount = globalOAuthCount

    states.forEach { state in
      XCTAssertEqual(state.count, 42)
      looped.fulfill()
    }
    
    wait(for: [looped], timeout: 0)
  }
}
