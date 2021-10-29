//
//  DbHelper.swift
//
//  Created by Rudy on 2021-10-26.
//

import Foundation
import SQLite3

enum SQLiteError: Error {
  case OpenDatabase(message: String)
  case Prepare(message: String)
  case Step(message: String)
  case Bind(message: String)
}

class SQLiteDatabase {
  private let dbPointer: OpaquePointer?
  private init(dbPointer: OpaquePointer?) {
    self.dbPointer = dbPointer
  }
  deinit {
    sqlite3_close(dbPointer)
  }
  
  static func open(path: String) throws -> SQLiteDatabase {
    var db: OpaquePointer?
    // 1
    if sqlite3_open(path, &db) == SQLITE_OK {
      // 2
      return SQLiteDatabase(dbPointer: db)
    } else {
      // 3
      defer {
        if db != nil {
          sqlite3_close(db)
        }
      }
      if let errorPointer = sqlite3_errmsg(db) {
        let message = String(cString: errorPointer)
        throw SQLiteError.OpenDatabase(message: message)
      } else {
        throw SQLiteError
          .OpenDatabase(message: "No error message provided from sqlite.")
      }
    }
  }

  func prepareStatement(sql: String) throws -> OpaquePointer? {
   var statement: OpaquePointer?
   guard sqlite3_prepare_v2(dbPointer, sql, -1, &statement, nil)
       == SQLITE_OK else {
     throw SQLiteError.Prepare(message: "Failed to prepare")
   }
   return statement
  }
  
  func getQuote() -> String {
    let querySql = "select quote from expresso order by random() limit 1;"
    guard let queryStatement = try? prepareStatement(sql: querySql) else {
      return "Prepare failed"
    }
    defer {
      sqlite3_finalize(queryStatement)
    }
    guard sqlite3_step(queryStatement) == SQLITE_ROW else {
      return "Failed execute of statement"
    }
    guard let queryResultCol = sqlite3_column_text(queryStatement, 0) else {
      return "Query returned zero rows"
    }
    let myQuote = String(cString: queryResultCol)
    return myQuote
  }
}

//extension SQLiteDatabase {
// func prepareStatement(sql: String) throws -> OpaquePointer? {
//  var statement: OpaquePointer?
//  guard sqlite3_prepare_v2(dbPointer, sql, -1, &statement, nil)
//      == SQLITE_OK else {
//    throw SQLiteError.Prepare(message: "Failed to prepare")
//  }
//  return statement
// }
//}

//extension SQLiteDatabase {
//  func getQuote() -> String {
//    let querySql = "select quote from expresso order by random() limit 1;"
//    guard let queryStatement = try? prepareStatement(sql: querySql) else {
//      return "Prepare failed"
//    }
//    defer {
//      sqlite3_finalize(queryStatement)
//    }
//    guard sqlite3_step(queryStatement) == SQLITE_ROW else {
//      return "Failed execute of statement"
//    }
//    guard let queryResultCol1 = sqlite3_column_text(queryStatement, 1) else {
//      return "Query returned zero rows"
//    }
//    let myQuote = String(cString: queryResultCol1)
//    return myQuote
//  }
//}
