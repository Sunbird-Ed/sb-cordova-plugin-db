# sb-cordova-plugin-db
A plugin to acsess SQLite database in Sunbird Mobile app - available for the iOS and Android platforms.

## Installation

    cordova plugin add https://github.com/Sunbird-Ed/sb-cordova-plugin-db.git#<branch_name>

To install it locally 

Clone the repo
    
    cordova plugin add <location_of plugin>/sb-cordova-plugin-db

# API Reference


* [db](#module_db)
    * [.init(dbName, dbVersion, migrations,successCallback)](#module_db.init)
    * [.open(filePath, successCallback)](#module_db.open)
    * [.close(isExternalDb, successCallback)](#module_db.close)
    * [.read(distinct,table,columns,selection,selectionArgs,groupBy,having,orderBy,limit, useExternalDb,successCallback, errorCallback)](#module_db.close)
    * [.execute(query,useExternalDb,successCallback, errorCallback)](#module_db.execute)
    * [.insert(table, model,useExternalDb,successCallback, errorCallback)](#module_db.insert)
    * [.update(table, whereClause, whereArgs, model,useExternalDb,successCallback, errorCallback)](#module_db.update)
    * [.delete(table, whereClause, whereArgs, useExternalDb,successCallback, errorCallback)](#module_db.delete)
    * [.beginTransaction()](#module_db.beginTransaction)
    * [.endTransaction(isOperationSuccessful,useExternalDb)](#module_db.endTransaction)
    * [.getDatabaseVersion()](#module_db.getDatabaseVersion)
    * [.bulkInsert(query, dataModels)](#module_db.bulkInsert)


## db
### db.init(dbName, dbVersion, migrations, successCallback)

Initializes the database.

- `dbName` represents dbName.
- `dbVersion` represents dbVersion.
- `migrations` represents list of migrations to be executed.

### db.open(filePath, successCallback)
Opens the database given in the filePath.

- `filePath` represents filePath of the database file.

### db.close(isExternalDb, successCallback)
Closes the database.

- `useExternalDb` represents whether the database is external or not.

### db.read(distinct, table, columns, selection, selectionArgs,groupBy, having, orderBy,limit, useExternalDb, successCallback, errorCallback)

- `distinct` represents  if you want each row to be unique, false otherwise..
- `table` represents The table name to compile the query against.
- `columns` represents a list of which columns to return. Passing null will return all columns, which is discouraged to prevent reading data from storage that isn't going to be used.
- `selection` represents A filter declaring which rows to return, formatted as an SQL WHERE clause (excluding the WHERE itself). Passing null will return all rows for the given table.
- `selectionArgs` You may include ?s in selection, which will be
replaced by the values from selectionArgs, in order that they
appear in the selection. The values will be bound as Strings.
- `groupBy` represents a filter declaring how to group rows, formatted as an SQL GROUP BY clause (excluding the GROUP BY itself). Passing null will cause the rows to not be grouped..
- `having` represents A filter declare which row groups to include in the cursor,if row grouping is being used, formatted as an SQL HAVING clause (excluding the HAVING itself). Passing null will cause all row groups to be included, and is required when row grouping is not being used.
- `orderBy` represents How to order the rows, formatted as an SQL ORDER BY clause (excluding the ORDER BY itself). Passing null will use the default sort order, which may be unordered.
- `limit` Limits the number of rows returned by the query,
formatted as LIMIT clause. Passing null denotes no LIMIT clause.
- `useExternalDb` represents whether the database is external or not.

### db.execute(query,useExternalDb,successCallback, errorCallback)
Stops the scanner

- `query` represents the query to be executed.
- `useExternalDb` represents whether the database is external or not.

### db.insert(table, model,useExternalDb,successCallback, errorCallback)
Stops the scanner

- `table` represents the table to insert into.
- `model` represents model to update in the table.
- `useExternalDb` represents whether the database is external or not.

### db.update(table, whereClause, whereArgs, model,useExternalDb,successCallback, errorCallback)
Stops the scanner

- `table` represents the table to update in.
- `whereClause` represents the optional WHERE clause to apply when deleting. Passing null will delete all rows.
- `whereArgs` represents arguments to be added in the whereClause.
- `model` represents model to update in the table.
- `useExternalDb` represents whether the database is external or not.

### db.delete(table, whereClause, whereArgs, useExternalDb,successCallback, errorCallback)
Stops the scanner

- `table` represents the table to delete from.
- `whereClause` represents the optional WHERE clause to apply when deleting. Passing null will delete all rows.
- `whereArgs` represents arguments to be added in the whereClause.
- `useExternalDb` represents whether the database is external or not.

### db.beginTransaction()
Begins a transaction in IMMEDIATE mode.

### db.endTransaction(isOperationSuccessful,useExternalDb)
End a transaction

- `isOperationSuccessful` represents whether operation is succ.
- `useExternalDb` represents whether the database is external or not.

### db.getDatabaseVersion()
Returns the database version.


### db.bulkInsert(query, dataModels)
Stops the scanner

- `query` represents toolbar title.
- `dataModels` represents toolbar title.


