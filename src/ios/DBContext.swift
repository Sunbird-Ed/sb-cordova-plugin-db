import Foundation
import SQLite3

class DBContext {
    static var name = ""
    static var version = 3
    private static var db: OpaquePointer? = nil
    private static var dbHelper = DBHelper()

    static func getOperator() -> OpaquePointer? {
        let databaseFilePath = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/\(DBContext.name)"
            if dbHelper.createDatabaseFile(databaseFilePath) != true {
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
