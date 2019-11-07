//
//  JSONType.swift
//  
//
//  Created by Yannick Heinrich on 04.11.19.
//

import Foundation

indirect enum JSONType {
    case bool(Bool)
    case integer(Int)
    case float(Double)
    case string(String)
    case null
    case date(Date)
    case data(Data)
    case array([JSONType])
    case object([String: JSONType])
}


