import Foundation
import SQLite3

@objc(SunbirdDBPlugin) class SunbirdDBPlugin : CDVPlugin { 

    private var name: String? = nil
    private var version: Int? = nil
    private var db: OpaquePointer? = nil
    private var externalDB: OpaquePointer? = nil

    @objc(init:)
    func init(_ command: CDVInvokedUrlCommand) {
        name = command.arguments[0] as? String ?? ""
        version = command.arguments[1] as? Int ?? 3
        let pluginResult:CDVPluginResult = CDVPluginResult.init(status: CDVCommandStatus_OK, messageAs: "Successfully initilized with \(name).")
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
        // Migration list is not stored
    }

    @objc(open:)
    func open(_ command: CDVInvokedUrlCommand) {
        var pluginResult:CDVPluginResult
        let dbPath = command.arguments[0] as? String ?? ""
        // TODO: update db path to application path 
           let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent(dbPath)
        if sqlite3_open(fileURL.path, &externalDB) != SQLITE_OK
        {
            print("error opening database")
            pluginResult = CDVPluginResult.init(status: CDVCommandStatus_ERROR)
        }
        else
        {
            print("Successfully opened connection to database at \(dbPath)")
            pluginResult = CDVPluginResult.init(status: CDVCommandStatus_OK, messageAs: "Successfully opened connection to database at \(dbPath)")
        }
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    @objc(close:)
    func close(_ command: CDVInvokedUrlCommand) {
        var pluginResult:CDVPluginResult
        if(sqlite3_close(externalDB)) != SQLITE_OK
        {
            print("error closing the database")
            pluginResult = CDVPluginResult.init(status: CDVCommandStatus_ERROR)
        }
        else
        {
            print("Successfully closed connection to database")
            pluginResult = CDVPluginResult.init(status: CDVCommandStatus_OK, messageAs: "Successfully closed connection to database")
        }
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    @objc(copyDatabase:)
    func copyDatabase(_ command: CDVInvokedUrlCommand) {
        //TODO: will implement after undstanding it
        let pluginResult:CDVPluginResult = CDVPluginResult.init(status: CDVCommandStatus_OK, messageAs: "Skipping copy of the data base")
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    @objc
    func read(_ command: CDVInvokedUrlCommand) {
        let operatorFlag = command.arguments[9] as? Bool ?? false
        let distinct = command.arguments[0] as? Bool ?? false
        let table = command.arguments[1] as? String ?? ""
        let columns = command.arguments[2] as? String[] ?? nil
        let selection = command.arguments[3] as? String ?? ""
        let selectionArgs = command.arguments[2] as? String[] ?? nil
        let groupBy = command.arguments[1] as? String ?? ""
        let having = command.arguments[1] as? String ?? ""
        let orderBy = command.arguments[1] as? String ?? ""
        let limit = command.arguments[1] as? String ?? ""
        let db = self.getOperator(operatorFlag)

    }
     
    @objc 
    func insert(_ command: CDVInvokedUrlCommand) {
            pluginResult = CDVPluginResult.init(status: CDVCommandStatus_ERROR)    
            let operatorFlag = command.arguments[2] as? Bool ?? false
            let db = self.getOperator(operatorFlag)
            let table = command.arguments[0] as? String
            let data = command.arguments[1] as? [String: Any]
            var queryStringQuestionString = ""
            for _ in 1..<data.keys.count {
                queryStringQuestionString += "?,"
            }
            queryStringQuestionString += "?"
            var statement: OpaquePointer?
            let queryString = "INSERT INTO \(table) (\(data.keys.joined(separator: ","))) VALUES (\(queryStringQuestionString))"
            guard sqlite3_prepare_v2(db, queryString, -1, &statement, nil) == SQLITE_OK else {
                let errmsg = String(cString: sqlite3_errmsg(externalDB)!)
                print("error preparing insert: \(errmsg)")
                self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
                return
            }
            var valueIndex: Int32 = 1
            let SQLITE_TRANSIENT = unsafeBitCast(OpaquePointer(bitPattern: -1), to: sqlite3_destructor_type.self)
            for (key, value) in data {
                if let value = value as? String {
                    guard sqlite3_bind_text(statement, valueIndex, value as! String, -1, SQLITE_TRANSIENT) == SQLITE_OK else {
                        let errmsg = String(cString: sqlite3_errmsg(externalDB)!)
                        print("sqlite3_bind_text failed with \(value) at index \(valueIndex)")
                        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
                        return
                    }
                } else if let value = value as? Int {
                    guard sqlite3_bind_int64(statement, valueIndex, Int64(value)) == SQLITE_OK  else {
                        print("sqlite3_bind_int failed with \(value) at index \(valueIndex)")
                        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
                        return
                    }
                }  else if let value = value as? Int32 {{
                    guard sqlite3_bind_int(statement, valueIndex, value as! Int32) == SQLITE_OK else {
                        print("sqlite3_bind_int failed with \(value) at index \(valueIndex)")
                        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
                        return
                    }
                } else if let value = value as? Double {{
                     guard sqlite3_bind_double(statement, valueIndex, value as! Double) == SQLITE_OK else {
                        print("sqlite3_bind_double failed with \(value) at index \(valueIndex)")
                        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
                        return
                    }
                }
                valueIndex += 1
            }

            guard sqlite3_step(statement) == SQLITE_DONE else {
                print("Error while inserting row")
                self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
                return
            } 
            let rowId = sqlite3_last_insert_rowid(db)
            defer {
                sqlite3_finalize(statement)
            }
        pluginResult = CDVPluginResult.init(status: CDVCommandStatus_OK, messageAs: rowId)    
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc
    func delete(_ command: CDVInvokedUrlCommand) {
        
    }

    @objc
    func update(_ command: CDVInvokedUrlCommand) {
        
    }

    @objc(execute:)
    func execute(_ command: CDVInvokedUrlCommand) {
        var pluginResult:CDVPluginResult
        let operatorFlag = command.arguments[1] as? Bool ?? false
        let db = self.getOperator(operatorFlag)
        var statement: OpaquePointer? = nil
        var result:Array<Dictionary<String,Any>>=[]
        guard sqlite3_prepare_v2(db, createTableString, -1, &statement, nil) == SQLITE_OK else {
            pluginResult = CDVPluginResult.init(status: CDVCommandStatus_ERROR)
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        while sqlite3_step(createTableStatement) == SQLITE_ROW {
            let columnsCount:Int32 = sqlite3_column_count(createTableStatement)
            var columnIndex: Int32 = 0;
            var eachRow:[String: Any] = [:]
            while column < columnsCount {
                let columnName = String(cString: sqlite3_column_name(createTableStatement, columnIndex))
                let columnType = sqlite3_column_type(createTableStatement, columnIndex);
                if(columnType  == SQLITE_FLOAT){
                    eachRow[columnName] = Double(sqlite3_column_double(createTableStatement, columnIndex))
                } else if(columnType  == SQLITE_INTEGER){ 
                    eachRow[columnName] = Int64(sqlite3_column_int64(createTableStatement, columnIndex))
                } else if(columnType  == SQLITE_TEXT){     
                    eachRow[columnName] = String(cString:sqlite3_column_text(createTableStatement, columnIndex) )
                } else if(columnType  == SQLITE_NULL){     
                    eachRow[columnName] = nil
                }
                columnIndex += 1
            }
            result.append(eachRow)
        }
        
        defer {
            sqlite3_finalize(createTableStatement)
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
     
    private getOperator(useexternalDbOperator: Bool) -> OpaquePointer{
        if useexternalDbOperator === true {
            return externalDB
        } else {
            let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent(self.name)
            if sqlite3_open(fileURL.path, &db) != SQLITE_OK
            {
                return nil;
            }
            else
            {
                return db
            }
        }
    } 
}

