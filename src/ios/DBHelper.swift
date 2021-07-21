import Foundation
import SQLite3


class DBHelper {

    func createDatabaseFile(_ filePath: String) -> Bool {
        let fileMang = FileManager.default
        if fileMang.fileExists(atPath: filePath) {
          return true
        }
        return fileMang.createFile(atPath: filePath, contents: nil, attributes: nil)
    }
}