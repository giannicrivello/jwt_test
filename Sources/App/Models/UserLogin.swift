//
//  File.swift
//  
//
//  Created by Gianni Crivello on 4/15/22.
//

import Vapor
import Fluent

final class UserLogin: Content {
    var userName: String
    var password: String
}
