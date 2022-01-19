# sb-cordova-plugin-db

This plugin provides all neccesary elements to perform DataBase operations on Android and iOS.

## Installation

With ionic:

`ionic cordova plugin add sb-cordova-plugin-db`

for Cordova installation

`cordova plugin add sb-cordova-plugin-db`

### init
Initialises data base, by createing DataBase if not created or upgrading in case already created DataBase.

Need to pass `dataBaseName` and `dataBaseVersion` as argument. On success, there are two things to handle, `onCreate` and `onUpgrade` as showed below.
```js
db.init(this.context.dbName,
this.dBVersion,
[],
(value) => {
    if (value.method === 'onCreate') {
        // Handle newly created DataBase
    } else if (value.method === 'onUpgrade') {
        // Handle upgraded DataBase
    }
});
```

### open
Open DataBase file (.db) located on a specific location. Pass the `dbFilePath` as argument.
```js
db.open(dbFilePath,
    (value) => {
        resolve();
    }, (value) => {
        reject();
    }
);
```

### copyDatabase
If DB copy has to be created, you need to pass the destination where new copy has to be created as argument `destinationPath`. On success you can access  the new copy of DB at new provided path.
```js
db.copyDatabase(destinationPath, (success: boolean) => {
    console.log('Success');
}, (error: string) => {
  console.log('Error');
});
```

### read
Read data from a specific DataBase. Following options are avilable as argument to this method:
`table` table name from where to read data
`columns` columns from where to read data
`whereClause` 
`whereClauseArgs`
`groupBy`
`having`
`orderBy`
`limit`
`useExternalDb`
```js
db.read(!!readQuery.distinct,
  table,
  columns,
  whereClause,
  whereClauseArgs,
  groupBy,
  having,
  orderBy,
  limit,
  useExternalDb,
  (json: any[]) => {
  }, (error: string) => {
    console.log('Error');
});
```

### execute
To execute DB query provide the `query` as argument to this method. If you want to use external DataBase make `useExternalDb` as true.
```js
db.execute(query, useExternalDb, (value) => {
  console.log('Query executed successfull ', value);
}, error => {
  console.log('Query failed to execute ', error);
});
```

### insert
For DB insert operation use this method. `table` on which table to execute insertion, `insertQuery` insert query to be executed and `useExternalDb` as true if table resides in external database.
```js
db.insert(table, insertQuery, useExternalDb,
    (number: number) => {
        console.log('Insert operation successfull');
    }, (error: string) => {
        console.log('Error occured while insert operation');
    }
);
```

### update
To execute update operation on a database use this method with following arguments described below. Arguments are similar to create method.
```js
db.update(
    table,
    whereClause,
    whereClauseArgs,
    modelJson,
    useExternalDb,
    (count: any) => {
        console.log('Success');
    }, (error: string) => {
        console.log('Error');
    });
```

### delete
For deletion use this method with folowing arguments shown below.
```js
const successCallback => (response) {
  console.log('Success');
};
const errorCallback => (response) {
  console.log('Success');
};

db.delete(
  table,
  whereClause,
  whereArgs,
  useExternalDb,
  successCallback,
  errorCallback
);
```

### beginTransaction
To start a DataBase transaction call this method. It doesn't return any value, i.e it's return type is `void`.
```js
db.beginTransaction();
```

### endTransaction
To end/close a database transaction, call this method with 2 arguments i.e `isOperationSuccessful` and `useExternalDb`.
```js
db.endTransaction(isOperationSuccessful, useExternalDb);
```

## Support

|Platform|
|--|
|Android|
|iOS|
|Web|