import Foundation
import SQLite3

@objc(SunbirdDBPlugin) class SunbirdDBPlugin : CDVPlugin { 

    var db: OpaquePointer? = nil

    @objc
    func init(_ command: CDVInvokedUrlCommand) {

    }

    @objc
    func open(_ command: CDVInvokedUrlCommand) {

        let dbPath = command.arguments[0] as? String ?? ""
           let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent(dbPath)
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK
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

    @objc
    func close(_ command: CDVInvokedUrlCommand) {
        if(sqlite3_close(db)) != SQLITE_OK
        {
            print("error closing the database")
            pluginResult = CDVPluginResult.init(status: CDVCommandStatus_ERROR)
        }
        else
        {
            print("Successfully closed connection to database at \(dbPath)")
            pluginResult = CDVPluginResult.init(status: CDVCommandStatus_OK, messageAs: "Successfully closed connection to database at \(dbPath)")
        }
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    @objc
    func copyDatabase(_ command: CDVInvokedUrlCommand) {
        
    }

    @objc
    func read(_ command: CDVInvokedUrlCommand) {
        
    }
     
    @objc 
    func insert(_ command: CDVInvokedUrlCommand) {
        
    }
    
    @objc
    func delete(_ command: CDVInvokedUrlCommand) {
        
    }

    @objc
    func update(_ command: CDVInvokedUrlCommand) {
        
    }

    @objc
    func execute(_ command: CDVInvokedUrlCommand) {
        
    }

    @objc
    func beginTransaction(_ command: CDVInvokedUrlCommand) {
        
    }

    @objc
    func endTransaction(_ command: CDVInvokedUrlCommand) {
        
    }
     
}

