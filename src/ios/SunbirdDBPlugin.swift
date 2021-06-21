import Foundation
import SQLite3

@objc(SunbirdDBPlugin) class SunbirdDBPlugin : CDVPlugin {

    private var name: String? = nil
    private var version: Int? = nil
    private var db: OpaquePointer? = nil
    private var externalDB: OpaquePointer? = nil

    @objc(init:)
    func `init`(_ command: CDVInvokedUrlCommand) {
        name = command.arguments[0] as? String ?? ""
        version = command.arguments[1] as? Int ?? 3
        let pluginResult:CDVPluginResult = CDVPluginResult.init(status: CDVCommandStatus_OK, messageAs: ["method": "onCreate"])
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
        // Migration list is not stored
    }

    @objc(open:)
    func open(_ command: CDVInvokedUrlCommand) {
        var pluginResult: CDVPluginResult = CDVPluginResult.init(status: CDVCommandStatus_ERROR)
        let dbPath = command.arguments[0] as! String
        let fileURL = try! FileManager.default.url(for: .applicationDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent(dbPath)
        if createDatabaseFile(dbPath) != true {
            print("error creating database file at path \(dbPath)")
        }
        guard sqlite3_open_v2(dbPath, &externalDB, SQLITE_OPEN_READWRITE, nil) != SQLITE_OK else {
            print("error opening database at path \(dbPath)")
            print("Error message: \(String(cString: sqlite3_errmsg(db)!)) Code:  \(sqlite3_errcode(db)) Method: Open")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        print("Successfully opened connection to database at path \(fileURL.path)")
        pluginResult = CDVPluginResult.init(status: CDVCommandStatus_OK)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    @objc(close:)
    func close(_ command: CDVInvokedUrlCommand) {
        var pluginResult: CDVPluginResult = CDVPluginResult.init(status: CDVCommandStatus_ERROR)
        guard sqlite3_close(externalDB) == SQLITE_OK else {
            print("Error message: \(String(cString: sqlite3_errmsg(db)!)) Code:  \(sqlite3_errcode(db)) Method: Close")
             self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
             return
        }
        print("Successfully closed connection to database")
        pluginResult = CDVPluginResult.init(status: CDVCommandStatus_OK, messageAs: "Successfully closed connection to database")
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    @objc(copyDatabase:)
    func copyDatabase(_ command: CDVInvokedUrlCommand) {
        //TODO: will implement after undstanding it
        let pluginResult:CDVPluginResult = CDVPluginResult.init(status: CDVCommandStatus_OK, messageAs: "Skipping copy of the data base")
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    @objc(read:)
    func read(_ command: CDVInvokedUrlCommand) {
        var pluginResult:CDVPluginResult = CDVPluginResult.init(status: CDVCommandStatus_ERROR)
        let operatorFlag = command.arguments[9] as? Bool ?? false
        let distinct = command.arguments[0] as? Bool ?? false
        let table = command.arguments[1] as? String ?? ""
        let columns = command.arguments[2] as? [String] ?? []
        let selection = command.arguments[3] as? String ?? ""
        let selectionArgs = command.arguments[4] as? [String] ?? []
        let groupBy = command.arguments[5] as? String ?? ""
        let having = command.arguments[6] as? String ?? ""
        let orderBy = command.arguments[7] as? String ?? ""
        let limit = command.arguments[8] as? String ?? ""
        let db = self.getOperator(operatorFlag)
        if db == nil {
            print("DB object null from getOperator")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        var queryString = "SELECT";
        if distinct == true {
            queryString += "DISTINCT "
        } else if(columns.count > 0) {
            queryString += columns.joined(separator: ", ")
        } else {
            queryString += " * "
        }
        queryString += " FROM \(table) "
        if selection != "" {
            queryString += " WHERE " + selection
        }
        if groupBy != "" {
            queryString += " GROUP BY " + groupBy
        }
        if having != "" {
            queryString += " HAVING " + having
        }
        if orderBy != "" {
            queryString += " ORDER BY " + orderBy
        }
        if limit != "" {
            queryString += " LIMIT " + limit
        }

        var statement: OpaquePointer? = nil
        guard sqlite3_prepare_v2(db, queryString, -1, &statement, nil) == SQLITE_OK else {
            print("Error message: \(String(cString: sqlite3_errmsg(db)!)) Code:  \(sqlite3_errcode(db)) Method: Read")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        let SQLITE_TRANSIENT = unsafeBitCast(OpaquePointer(bitPattern: -1), to: sqlite3_destructor_type.self)
        var valueIndex: Int32 = 1
        for (_, value) in selectionArgs.enumerated() {
            print("Data: \(valueIndex)")
           guard sqlite3_bind_text(statement, valueIndex, value, -1, SQLITE_TRANSIENT) == SQLITE_OK else {
               print("Unable to bind the data \(value)")
               print("Error message: \(String(cString: sqlite3_errmsg(db)!)) Code:  \(sqlite3_errcode(db)) Method: Read")
               self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
               return
           }
            valueIndex += 1
        }
        var result:Array<Dictionary<String,Any>>=[]
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let columnsCount:Int32 = sqlite3_column_count(statement)
            var columnIndex: Int32 = 0
            var eachRow:[String: Any] = [:]
            while columnIndex < columnsCount {
                let columnName = String(cString: sqlite3_column_name(statement, columnIndex))
                let columnType = sqlite3_column_type(statement, columnIndex)
                if(columnType  == SQLITE_FLOAT){
                    eachRow[columnName] = Double(sqlite3_column_double(statement, columnIndex))
                } else if(columnType  == SQLITE_INTEGER){
                    eachRow[columnName] = Int64(sqlite3_column_int64(statement, columnIndex))
                } else if(columnType  == SQLITE_TEXT){
                    eachRow[columnName] = String(cString:sqlite3_column_text(statement, columnIndex) )
                } else if(columnType  == SQLITE_NULL){
                    eachRow[columnName] = nil
                } else if(columnType == SQLITE_BLOB) {
                    //TODO
                    // eachRow[columnName] = String(cString:sqlite3_column_blob(statement, columnIndex) )
                    let blob = sqlite3_column_blob(statement, columnIndex);
                    if blob != nil {
                        let size = sqlite3_column_bytes(statement, columnIndex)
                        eachRow[columnName] = NSData(bytes: blob, length: Int(size))
                    }else{
                        eachRow[columnName] = nil;
                    }
                }
                columnIndex += 1
            }
            result.append(eachRow)
        }
        
        defer {
            sqlite3_finalize(statement)
        }
         pluginResult = CDVPluginResult.init(status: CDVCommandStatus_OK, messageAs: result)
         self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
     
    @objc(insert:)
    func insert(_ command: CDVInvokedUrlCommand) {

        var pluginResult = CDVPluginResult.init(status: CDVCommandStatus_ERROR)
            let operatorFlag = command.arguments[2] as? Bool ?? false
            let db = self.getOperator(operatorFlag)
            if db == nil {
                print("DB object null from getOperator")
                self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
                return
            }
            let table = command.arguments[0] as! String
            let data = command.arguments[1] as? [String: Any]
            var queryStringQuestionString = ""
            for _ in 1..<data!.keys.count {
                queryStringQuestionString += "?,"
            }
            queryStringQuestionString += "?"
            var statement: OpaquePointer?
            let queryString = "INSERT INTO \(table) (\(data!.keys.joined(separator: ","))) VALUES (\(queryStringQuestionString))"
            guard sqlite3_prepare_v2(db, queryString, -1, &statement, nil) == SQLITE_OK else {
                print("Error message: \(String(cString: sqlite3_errmsg(db)!)) Code:  \(sqlite3_errcode(db)) Method: Insert")
                self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
                return
            }
            var valueIndex: Int32 = 1
            let SQLITE_TRANSIENT = unsafeBitCast(OpaquePointer(bitPattern: -1), to: sqlite3_destructor_type.self)
            if let data = data {
                for (_, value) in data {
                    if let value = value as? String {
                        guard sqlite3_bind_text(statement, valueIndex, value as String, -1, SQLITE_TRANSIENT) == SQLITE_OK else {
                            print("sqlite3_bind_text failed with \(value) at index \(valueIndex)")
                            print("Error message: \(String(cString: sqlite3_errmsg(db)!)) Code:  \(sqlite3_errcode(db)) Method: Insert")
                            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
                            return
                        }
                    } else if let value = value as? Int {
                        guard sqlite3_bind_int64(statement, valueIndex, Int64(value)) == SQLITE_OK  else {
                            print("sqlite3_bind_int failed with \(value) at index \(valueIndex)")
                            print("Error message: \(String(cString: sqlite3_errmsg(db)!)) Code:  \(sqlite3_errcode(db)) Method: Insert")
                            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
                            return
                        }
                    }  else if let value = value as? Int32 {
                        guard sqlite3_bind_int(statement, valueIndex, value as Int32) == SQLITE_OK else {
                            print("sqlite3_bind_int failed with \(value) at index \(valueIndex)")
                            print("Error message: \(String(cString: sqlite3_errmsg(db)!)) Code:  \(sqlite3_errcode(db)) Method: Insert")
                            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
                            return
                        }
                    } else if let value = value as? Double {
                        guard sqlite3_bind_double(statement, valueIndex, value as Double) == SQLITE_OK else {
                            print("sqlite3_bind_double failed with \(value) at index \(valueIndex)")
                            print("Error message: \(String(cString: sqlite3_errmsg(db)!)) Code:  \(sqlite3_errcode(db)) Method: Insert")
                            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
                            return
                        }
                    }
                    valueIndex += 1
                }
            }

            guard sqlite3_step(statement) == SQLITE_DONE else {
                print("Error message: \(String(cString: sqlite3_errmsg(db)!)) Code:  \(sqlite3_errcode(db)) Method: Insert")
                self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
                return
            }
            let rowId = sqlite3_last_insert_rowid(db)
            defer {
                sqlite3_finalize(statement)
            }

            //TODO
            print(rowId)
        pluginResult = CDVPluginResult.init(status: CDVCommandStatus_OK, messageAs: rowId.hashValue)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc(delete:)
    func delete(_ command: CDVInvokedUrlCommand) {

        var pluginResult = CDVPluginResult.init(status: CDVCommandStatus_ERROR)
        let table = command.arguments[0] as? String
        let operatorFlag = command.arguments[3] as? Bool ?? false
        let db = self.getOperator(operatorFlag)
        if db == nil {
            print("DB object null from getOperator")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        let whereClause = command.arguments[1] as? String ?? ""
        let whereArgs = command.arguments[2] as? [String] ?? [String]()
        let statementString = "DELETE FROM \(table) WHERE \(whereClause);"
        var statement: OpaquePointer? = nil

        guard sqlite3_prepare_v2(db, statementString, -1, &statement, nil) == SQLITE_OK else {
            print("Error message: \(String(cString: sqlite3_errmsg(db)!)) Code:  \(sqlite3_errcode(db)) Method: Delete")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        let SQLITE_TRANSIENT = unsafeBitCast(OpaquePointer(bitPattern: -1), to: sqlite3_destructor_type.self)
        for (index, value) in whereArgs.enumerated() {
           guard sqlite3_bind_text(statement, Int32((index + 1)), value, -1, SQLITE_TRANSIENT) == SQLITE_OK else {
                print("Unable to bind the data \(value) while running delete call")
                print("Error message: \(String(cString: sqlite3_errmsg(db)!)) Code:  \(sqlite3_errcode(db)) Method: Delete")
                self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
                return
           }
        }
        guard sqlite3_step(statement) == SQLITE_DONE  else {
                print("Error message: \(String(cString: sqlite3_errmsg(db)!)) Code:  \(sqlite3_errcode(db)) Method: Delete")
                self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
                return
        }
        let deletedCount  = sqlite3_changes(db)
        sqlite3_finalize(statement)
        print("Deleted count: ", deletedCount)
        pluginResult = CDVPluginResult.init(status: CDVCommandStatus_OK, messageAs: deletedCount)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    @objc(update:)
    func update(_ command: CDVInvokedUrlCommand) {
        var pluginResult = CDVPluginResult.init(status: CDVCommandStatus_ERROR)
        let table = command.arguments[0] as! String
        let operatorFlag = command.arguments[4] as? Bool ?? false
        let db = self.getOperator(operatorFlag)
        if db == nil {
            print("DB object null from getOperator")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        let whereClause = command.arguments[1] as? String ?? ""
        let updateValues: [String: Any] = command.arguments[3] as? [String: Any] ?? [:]
        let whereArgs =  command.arguments[2] as? [String] ?? [String]()
        let statementString = "UPDATE \(table) SET " + updateValues.keys.joined(separator: " = ?, ") + " = ? WHERE \(whereClause)"
        var statement: OpaquePointer? = nil
        guard sqlite3_prepare_v2(db, statementString, -1, &statement, nil) == SQLITE_OK else {
            print("Error message: \(String(cString: sqlite3_errmsg(db)!)) Code:  \(sqlite3_errcode(db)) Method: Update")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        var valueIndex: Int32 = 1
        let SQLITE_TRANSIENT = unsafeBitCast(OpaquePointer(bitPattern: -1), to: sqlite3_destructor_type.self)
        for (_, value) in updateValues {
            if let value = value as? String {
                guard sqlite3_bind_text(statement, valueIndex, value as! String, -1, SQLITE_TRANSIENT) == SQLITE_OK else {
                    print("sqlite3_bind_text failed with \(value) at index \(valueIndex)")
                    print("Error message: \(String(cString: sqlite3_errmsg(db)!)) Code:  \(sqlite3_errcode(db)) Method: Update")
                    self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
                    return
                }
            } else if let value = value as? Int {
                guard sqlite3_bind_int64(statement, valueIndex, Int64(value)) == SQLITE_OK  else {
                    print("sqlite3_bind_int failed with \(value) at index \(valueIndex)")
                    print("Error message: \(String(cString: sqlite3_errmsg(db)!)) Code:  \(sqlite3_errcode(db)) Method: Update")
                    self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
                    return
                }
            }  else if(value is Int32) {
                guard sqlite3_bind_int(statement, valueIndex, value as! Int32) == SQLITE_OK else {
                    print("sqlite3_bind_int failed with \(value) at index \(valueIndex)")
                    print("Error message: \(String(cString: sqlite3_errmsg(db)!)) Code:  \(sqlite3_errcode(db)) Method: Update")
                    self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
                    return
                }
            } else if(value is Double) {
                guard sqlite3_bind_double(statement, valueIndex, value as! Double) == SQLITE_OK else {
                    print("sqlite3_bind_double failed with \(value) at index \(valueIndex)")
                    print("Error message: \(String(cString: sqlite3_errmsg(db)!)) Code:  \(sqlite3_errcode(db)) Method: Update")
                    self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
                    return
                }
            }
            valueIndex += 1
        }
        for (_, value) in whereArgs.enumerated() {
           guard sqlite3_bind_text(statement, valueIndex, value, -1, SQLITE_TRANSIENT) == SQLITE_OK else {
               print("Unable to bind the data \(value)")
            print("Error message: \(String(cString: sqlite3_errmsg(db)!)) Code:  \(sqlite3_errcode(db)) Method: Update")
               self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
               return
           }
           valueIndex += 1
        }
        guard sqlite3_step(statement) == SQLITE_DONE  else {
            print("Error message: \(String(cString: sqlite3_errmsg(db)!)) Code:  \(sqlite3_errcode(db)) Method: Update")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        let updatedCount  = sqlite3_changes(db)
        print("Updated count: ", updatedCount)
        sqlite3_finalize(statement)
        pluginResult = CDVPluginResult.init(status: CDVCommandStatus_OK, messageAs: updatedCount)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    @objc(execute:)
    func execute(_ command: CDVInvokedUrlCommand) {
        var pluginResult:CDVPluginResult = CDVPluginResult.init(status: CDVCommandStatus_ERROR)
        let operatorFlag = command.arguments[1] as? Bool ?? false
        let statementString = command.arguments[0] as? String
        let db = self.getOperator(operatorFlag)
        if db == nil {
            print("DB object null from getOperator")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        var statement: OpaquePointer? = nil
        var result:Array<Dictionary<String,Any>>=[]
        guard sqlite3_prepare_v2(db, statementString, -1, &statement, nil) == SQLITE_OK else {
            print("Error message: \(String(cString: sqlite3_errmsg(db)!)) Code:  \(sqlite3_errcode(db)) Method: execute")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let columnsCount:Int32 = sqlite3_column_count(statement)
            var columnIndex: Int32 = 0
            var eachRow:[String: Any] = [:]
            while columnIndex < columnsCount {
                let columnName = String(cString: sqlite3_column_name(statement, columnIndex))
                let columnType = sqlite3_column_type(statement, columnIndex)
                if(columnType  == SQLITE_FLOAT){
                    eachRow[columnName] = Double(sqlite3_column_double(statement, columnIndex))
                } else if(columnType  == SQLITE_INTEGER){
                    eachRow[columnName] = Int64(sqlite3_column_int64(statement, columnIndex))
                } else if(columnType  == SQLITE_TEXT){
                    eachRow[columnName] = String(cString:sqlite3_column_text(statement, columnIndex) )
                } else if(columnType  == SQLITE_NULL){
                    eachRow[columnName] = nil
                }
                columnIndex += 1
            }
            result.append(eachRow)
        }
        
        defer {
            sqlite3_finalize(statement)
        }
         pluginResult = CDVPluginResult.init(status: CDVCommandStatus_OK, messageAs: result)
         self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    @objc(beginTransaction:)
    func beginTransaction(_ command: CDVInvokedUrlCommand) {
         //TODO: will implement after undstanding it
        let pluginResult:CDVPluginResult = CDVPluginResult.init(status: CDVCommandStatus_OK, messageAs: "Skipping beginTransaction")
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    @objc(endTransaction:)
    func endTransaction(_ command: CDVInvokedUrlCommand) {
         //TODO: will implement after undstanding it
        let pluginResult:CDVPluginResult = CDVPluginResult.init(status: CDVCommandStatus_OK, messageAs: "Skipping endTransaction")
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
     
    private func getOperator(_ useexternalDbOperator: Bool) -> OpaquePointer?{
        if useexternalDbOperator == true {
            return externalDB
        } else {
            let databaseFilePath = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/\(self.name!)"
            if createDatabaseFile(databaseFilePath) != true {
                return nil
            }
            if sqlite3_open_v2(databaseFilePath, &db, SQLITE_OPEN_READWRITE, nil) != SQLITE_OK
            {
                print("Error message: \(String(cString: sqlite3_errmsg(db)!)) Code:  \(sqlite3_errcode(db)) Method: getOperator")
                return nil
            }
            else
            {
                return db
            }
        }
    }

    private func createDatabaseFile(_ filePath: String) -> Bool {
        let fileMang = FileManager.default
        if fileMang.fileExists(atPath: filePath) {
          return true
        }
        return fileMang.createFile(atPath: filePath, contents: nil, attributes: nil)
    }
}


