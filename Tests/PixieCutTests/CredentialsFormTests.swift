import XCTest
import PixieCut



class CredentialsFormTests: XCTestCase {
  func testFull() {
    let query = OAuthQuery(queryItems: [
      URLQueryItem(name: "access_token", value: "access123"),
      URLQueryItem(name: "refresh_token", value: "refresh123"),
      URLQueryItem(name: "token_type", value: "bearer"),
      URLQueryItem(name: "expires_in", value: "3600"),
      URLQueryItem(name: "scope", value: "read write"),
    ])
    let credentials = try! Credentials(query: query)
    XCTAssertEqual(Date().timeIntervalSince1970, credentials.created.timeIntervalSince1970, accuracy: 1.0)
    XCTAssertEqual(credentials.accessToken, "access123")
    XCTAssertEqual(credentials.refreshToken, "refresh123")
    XCTAssertEqual(credentials.tokenType, "bearer")
    XCTAssertEqual(credentials.expiresIn, 3600)
    XCTAssertEqual(credentials.scope, ["read", "write"])
  }
  
  
  func testMinimum() {
    let query = OAuthQuery(queryItems: [
      URLQueryItem(name: "access_token", value: "access123"),
      URLQueryItem(name: "token_type", value: "bearer"),
    ])
    let credentials = try! Credentials(query: query)
    XCTAssertEqual(Date().timeIntervalSince1970, credentials.created.timeIntervalSince1970, accuracy: 1.0)
    XCTAssertEqual(credentials.accessToken, "access123")
    XCTAssertEqual(credentials.tokenType, "bearer")
    XCTAssertNil(credentials.refreshToken)
    XCTAssertNil(credentials.expiresIn)
    XCTAssert(credentials.scope.isEmpty)
  }
  
  
  func testMissingRequiredAccessToken() {
    let accessTokenNotFound = expectation(description: "waiting for error")
    
    let query = OAuthQuery(queryItems: [
      URLQueryItem(name: "token_type", value: "bearer"),
    ])
    do {
      _ = try Credentials(query: query)
    } catch Credentials.Error.missingRequiredQueryParameter("access_token") {
      accessTokenNotFound.fulfill()
    } catch {
      XCTFail()
    }
    
    wait(for: [accessTokenNotFound], timeout: 0)
  }
  
  
  func testMissingRequiredTokenType() {
    let tokenTypeNotFound = expectation(description: "Waiting for error")

    let query = OAuthQuery(queryItems: [
      URLQueryItem(name: "access_token", value: "access123"),
    ])

    do {
      _ = try Credentials(query: query)
    } catch Credentials.Error.missingRequiredQueryParameter("token_type"){
      tokenTypeNotFound.fulfill()
    } catch {
      XCTFail()
    }
    
    wait(for: [tokenTypeNotFound], timeout: 0)
  }
  
  
  func testInvalidData() {
    let errorThrown = expectation(description: "Waiting for error")
    
    let invalidQuery = OAuthQuery(queryItems: [])
    do {
      _ = try Credentials(query: invalidQuery)
    } catch Credentials.Error.missingRequiredQueryParameter {
      errorThrown.fulfill()
    } catch {
      XCTFail()
    }
    
    wait(for: [errorThrown], timeout: 0)
  }

}
