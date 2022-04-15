//
//  File.swift
//  
//
//  Created by Gianni Crivello on 4/14/22.
//

import Foundation
import Vapor
import Fluent
import JWT


final class User: Model, Content {
    static let schema = "User"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "UserName")
    var userName: String
    
    @Field(key: "Password")
    var passWord: String
    
    init(){ }
    init(id: UUID? = nil, userName: String){
        self.id = id
        self.userName = userName
    }
}

//Step 1) Verify the user provided password
//JWT EXTENSTION FOR AUTHENTICATION
extension User: ModelAuthenticatable {
    static var usernameKey: KeyPath<User, Field<String>> =
    \User.$userName
    static var passwordHashKey: KeyPath<User, Field<String>> =
    \User.$passWord
    
    //comparing that the password provided is the same as the password
    //inside of the database
    func verify(password: String) throws -> Bool {
        return try Bcrypt.verify(password, created: self.passWord)
    }
}

//Step 2) AUTHORIZATION
struct JWTBearerAuthenticator: JWTAuthenticator {
    typealias Payload = MyJwtPayload
    
    func authenticate(jwt: Payload, for request: Request) -> EventLoopFuture<Void> {
        do {
            try jwt.verify(using:
                            request.application.jwt.signers.get()!)
            return User
                .find(jwt.id, on: request.db)
                .unwrap(or: Abort(.notFound))
                .map { usr in
                    request.auth.login(user)
                }
            
        } catch {
            return request.eventLoop.makeSucceededFuture()
        }
    }
}

//step 3)
extension User {
    func generateToken(_ app: Application) throws -> String {
        var expDate = Date()
        expDate.addTimeInterval(oneDayInSeconds * 7)
        
        let exp = ExpirationClaim(value: expDate)
        
        return try app.jwt.signers.get(kid: .private)!
            .sign(MyJwtPayload(id: self.id, userName: self.userName, exp: exp))
    }
    
}

