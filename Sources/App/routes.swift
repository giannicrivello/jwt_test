import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        return "It works!"
    }

    app.get("hello") { req -> String in
        return "Hello, world!"
    }
    
    //how user gets token
    app.post("login") { req -> EventLoopFuture<String> in
        let userToLogin = try req.content.decode(UserLogin.self)
        
        return User.query(on: req.db)
            .filter(\.$userName == userToLogin.userName)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMapThrowing { addUser in
                let verified = try addUser.verify(password:
                                                    addUser.passWord)
                if verified == false {
                    throw Abort(.unauthorized)
                }
                
                req.auth.login(addUser)
                let user = try req.auth.require(User.self)
                return try user.generateToken(req.application)
            }
    }
    
    app.post(JWTBearerAuthenticator(), ":me") { req -> EventLoopFuture<Me> in
        
        let user = try req.auth.require(User.self)
        let userName = user.userName

        return User.query(on: req.db)
            .filter(\.$userName == userName)
            .first()
            .unwrap(or: Abort(.notFound))
            .map { usr in
                return Me(id: UUID(), userName: user.userName)
            }
        
    }

    try app.register(collection: TodoController())
}
