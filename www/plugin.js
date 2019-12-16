var exec = require('cordova/exec');

var PLUGIN_NAME = 'db';

var db = {

    init: function(dbName, dbVersion, migrations, callback) {
        exec(callback, null, PLUGIN_NAME, "init", [dbName, dbVersion, migrations]);
    },

    open: function(filePath, callback) {
        exec(callback, null, PLUGIN_NAME, "open", [filePath]);
    },

    close: function(isExternalDb, callback) {
        exec(callback, null, PLUGIN_NAME, "close", [isExternalDb]);
    },

    copyDatabase: function(destination,callback) {
        exec(callback, null, PLUGIN_NAME, "copyDatabase", [destination]);
    },

    read: function(distinct,
         table,
         columns,
         selection,
         selectionArgs,
         groupBy,
         having,
         orderBy,
         limit,
         useExternalDb,
         success,
         error) {

        exec(success, error, PLUGIN_NAME, "read", [distinct,
            table,
            columns,
            selection,
            selectionArgs,
            groupBy,
            having,
            orderBy,
            limit,
            useExternalDb]);
    },

    execute: function(query,useExternalDb, success, error) {
        exec(success, error, PLUGIN_NAME, "execute", [query, useExternalDb]);
    },

    insert: function(table, model,useExternalDb, success, error) {
        exec(success, error, PLUGIN_NAME, "insert", [table, model,useExternalDb]);
    },

    update: function(table, whereClause, whereArgs, model,useExternalDb, success, error) {
        exec(success, error, PLUGIN_NAME, "update", [table, whereClause, whereArgs, model,useExternalDb]);
    },

    delete: function(table, whereClause, whereArgs, useExternalDb, success, error) {
        exec(success, error, PLUGIN_NAME, "delete", [table, whereClause, whereArgs,useExternalDb]);
    },

    beginTransaction: function() {
        exec(null, null, PLUGIN_NAME, "beginTransaction", []);
    },
    
    endTransaction: function(isOperationSuccessful,useExternalDb) {
        exec(null, null, PLUGIN_NAME, "endTransaction", [isOperationSuccessful,useExternalDb]);
    },
    
    getDatabaseVersion: function() {
        exec(null, null, PLUGIN_NAME, "getDatabaseVersion", []);
    },

    bulkInsert: function(query, dataModels) {
        exec(null, null, PLUGIN_NAME, "bulkInsert", [query, dataModels]);
    }

};


module.exports = db;
