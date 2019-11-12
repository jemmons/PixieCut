import XCTest
import PixieCut



class CredentialsFormTests: XCTestCase {
  func testFull() {
    let query = Data("access_token=access123&refresh_token=refresh123&token_type=bearer&expires_in=3600&scope=read write".utf8)
    let credentials = try! Credentials(queryData: query)
    XCTAssertEqual(Date().timeIntervalSince1970, credentials.created.timeIntervalSince1970, accuracy: 1.0)
    XCTAssertEqual(credentials.accessToken, "access123")
    XCTAssertEqual(credentials.refreshToken, "refresh123")
    XCTAssertEqual(credentials.tokenType, "bearer")
    XCTAssertEqual(credentials.expiresIn, 3600)
    XCTAssertEqual(credentials.scope, ["read", "write"])
  }
  
  
  func testMinimum() {
    let query = Data("access_token=access123&token_type=bearer".utf8)
    let credentials = try! Credentials(queryData: query)
    XCTAssertEqual(Date().timeIntervalSince1970, credentials.created.timeIntervalSince1970, accuracy: 1.0)
    XCTAssertEqual(credentials.accessToken, "access123")
    XCTAssertEqual(credentials.tokenType, "bearer")
    XCTAssertNil(credentials.refreshToken)
    XCTAssertNil(credentials.expiresIn)
    XCTAssert(credentials.scope.isEmpty)
  }
  
  
  func testMissingRequiredAccessToken() {
    let accessTokenNotFound = expectation(description: "waiting for error")
    
    let query = Data("token_type=bearer".utf8)
    do {
      _ = try Credentials(queryData: query)
    } catch Credentials.Error.missingRequiredQueryParameter("access_token") {
      accessTokenNotFound.fulfill()
    } catch {
      XCTFail()
    }
    
    wait(for: [accessTokenNotFound], timeout: 0)
  }
  
  
  func testMissingRequiredTokenType() {
    let tokenTypeNotFound = expectation(description: "Waiting for error")
    
    let query = Data("access_token=access123".utf8)
    do {
      _ = try Credentials(queryData: query)
    } catch Credentials.Error.missingRequiredQueryParameter("token_type"){
      tokenTypeNotFound.fulfill()
    } catch {
      XCTFail()
    }
    
    wait(for: [tokenTypeNotFound], timeout: 0)
  }
  
  
  func testInvalidData() {
    let errorThrown = expectation(description: "Waiting for error")
    
    let invalidQuery = Data(capacity: 0)
    do {
      _ = try Credentials(queryData: invalidQuery)
    } catch Credentials.Error.missingRequiredQueryParameter {
      errorThrown.fulfill()
    } catch {
      XCTFail()
    }
    
    wait(for: [errorThrown], timeout: 0)
  }

}
