import XCTest
import PixieCut



class StateTests: XCTestCase {
  func testValidity() {
    var comps = URLComponents()
    
    let states: [String] = globalOAuths.map { oauthRequest in
      comps.query = oauthRequest.authRequest.url?.query
      
      return (comps.queryItems?.first { $0.name == "state" }?.value)!
    }
    
    let invalidCharacters = CharacterSet(charactersIn: "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ").inverted
    
    let looped = expectation(description: "Waiting for all the loops.")
    looped.expectedFulfillmentCount = globalOAuthCount

    states.forEach { state in
      XCTAssertNil(state.rangeOfCharacter(from: invalidCharacters))
      XCTAssertEqual(state.count, 42)
      looped.fulfill()
    }
    
    wait(for: [looped], timeout: 0)
  }
  
  
  func testUnique() {
    var comps = URLComponents()
    
    let states: [String] = globalOAuths.map { oauthRequest in
      comps.query = oauthRequest.authRequest.url?.query
      return (comps.queryItems?.first { $0.name == "state" }?.value)!
    }
    
    let stateSet = Set(states)
    XCTAssertEqual(stateSet.count, globalOAuthCount)
  }
  
  
  func testPersistence() {
    let looped = expectation(description: "Waiting for all the loops.")
    looped.expectedFulfillmentCount = globalOAuthCount

    var comps = URLComponents()
    globalOAuths.forEach { oauthRequest in
      comps.query = oauthRequest.authRequest.url?.query
      let state = (comps.queryItems?.first { $0.name == "state" }?.value)!
      _ = try! oauthRequest.makeTokenRequest(callback: URL(string: "https://example.com?code=123&state=\(state)")!)
      looped.fulfill()
    }
    
    wait(for: [looped], timeout: 0)
  }
}
