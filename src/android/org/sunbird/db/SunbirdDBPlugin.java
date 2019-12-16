package org.sunbird.db;

import android.support.annotation.NonNull;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

public class SunbirdDBPlugin extends CordovaPlugin {

    private static final String METHOD_INIT = "init";
    private static final String METHOD_OPEN = "open";
    private static final String METHOD_CLOSE = "close";
    private static final String METHOD_COPY_DATABASE = "copyDatabase";
    private static final String METHOD_READ = "read";
    private static final String METHOD_INSERT = "insert";
    private static final String METHOD_DELETE = "delete";
    private static final String METHOD_UPDATE = "update";
    private static final String METHOD_EXECUTE = "execute";
    private static final String METHOD_BEGIN_TRANSACTION = "beginTransaction";
    private static final String METHOD_END_TRANSACTION = "endTransaction";


    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {

        switch (action) {
            case METHOD_INIT:
                doInit(args, callbackContext);
                break;
            case METHOD_OPEN:
                doOpen(args, callbackContext);
                break;
            case METHOD_CLOSE:
                doClose(args, callbackContext);
                break;
            case METHOD_COPY_DATABASE:
                doCopyDatabase(args, callbackContext);
                break;
            case METHOD_READ:
                doRead(args, callbackContext);
                break;
            case METHOD_INSERT:
                doInsert(args, callbackContext);
                break;
            case METHOD_UPDATE:
                doUpdate(args, callbackContext);
                break;
            case METHOD_DELETE:
                doDelete(args, callbackContext);
                break;
            case METHOD_EXECUTE:
                doExecute(args, callbackContext);
                break;
            case METHOD_BEGIN_TRANSACTION:
                doBeginTransaction();
                break;
            case METHOD_END_TRANSACTION:
                doEndTransaction(args);
                break;
        }

        return true;
    }

    private void doEndTransaction(JSONArray args) throws JSONException {
        getOperator(args.getBoolean(1)).endTransaction(args.getBoolean(0));
    }

    private void doBeginTransaction() {
        getOperator(false).beginTransaction();
    }

    private void doExecute(JSONArray args, CallbackContext callbackContext) {
        try {
            JSONArray resultArray = getOperator(args.getBoolean(1)).execute(args.getString(0));
            callbackContext.success(resultArray);
        } catch (Exception e) {
            e.printStackTrace();
            callbackContext.error(e.getMessage());
        }
    }

    private void doInsert(JSONArray args, CallbackContext callbackContext) {
        try {
            long number = getOperator(args.getBoolean(2)).insert(args.getString(0), args.getJSONObject(1));
            callbackContext.success((int) number);
        } catch (Exception e) {
            e.printStackTrace();
            callbackContext.error(e.getMessage());
        }
    }

    private void doRead(JSONArray args, CallbackContext callbackContext) {
        try {
            JSONArray resultArray = getOperator(args.getBoolean(9)).read(
                    args.getBoolean(0),
                    args.getString(1),
                    toStringArray(args.getJSONArray(2)),
                    args.getString(3),
                    toStringArray(args.getJSONArray(4)),
                    args.getString(5),
                    args.getString(6),
                    args.getString(7),
                    args.getString(8)
            );
            callbackContext.success(resultArray);
        } catch (Exception e) {
            e.printStackTrace();
            callbackContext.error(e.getMessage());
        }
    }

    private void doUpdate(JSONArray args, CallbackContext callbackContext){
        try {
            int count = getOperator(args.getBoolean(4)).update(
                    args.getString(0),
                    args.getString(1),
                    toStringArray(args.getJSONArray(2)),
                    args.getJSONObject(3)
            );
            callbackContext.success(count);
        } catch (Exception e) {
            e.printStackTrace();
            callbackContext.error(e.getMessage());
        }
    }

    private void doDelete(JSONArray args, CallbackContext callbackContext) {
        try {
            int count = getOperator(args.getBoolean(3)).delete(
                    args.getString(0),
                    args.getString(1),
                    toStringArray(args.getJSONArray(2))
            );
            callbackContext.success(count);
        } catch (Exception e) {
            e.printStackTrace();
            callbackContext.error(e.getMessage());
        }
    }

    private void doInit(JSONArray args, CallbackContext callbackContext) throws JSONException {
        List<Migration> migrationList = prepareMigrations(args);

        SunbirdDBContext sunbirdDBContext = new SunbirdDBContext();
        sunbirdDBContext.setContext(cordova.getContext())
                .setDbName(args.getString(0))
                .setDbVersion(args.getInt(1))
                .setMigrationList(migrationList);


        SunbirdDBHelper.init(sunbirdDBContext, callbackContext);
    }

    private void doOpen(JSONArray args, CallbackContext callbackContext) throws JSONException {
        try {
            SunbirdDBHelper.initExternalDatabase(new SunbirdDBContext(cordova.getContext(),args.getString(0).replace("file://", "")),callbackContext);
            callbackContext.success();
        } catch (Exception e) {
            e.printStackTrace();
            callbackContext.error(e.getMessage());
        }
    }

    private void doClose(JSONArray args, CallbackContext callbackContext) throws JSONException {
        try {
            SunbirdDBHelper.getInstance().close();
        } catch (Exception e) {
            e.printStackTrace();
            callbackContext.error(e.getMessage());
        }
    }

    private void doCopyDatabase(JSONArray args, CallbackContext callbackContext) throws JSONException {
        ;
        try {
            String destination = args.getString(0).replace("file://", "");
            String dbName = getOperator(false).getDBName();
            FileUtil.cp(cordova.getContext().getDatabasePath(dbName).getPath(), destination);
            callbackContext.success();
        } catch (Exception e) {
            e.printStackTrace();
            callbackContext.error(e.getMessage());
        }
    }

    private List<Migration> prepareMigrations(JSONArray args) throws JSONException {
        List<Migration> migrationList = new ArrayList<>();
        JSONArray migrationArray = args.getJSONArray(2);
        int size = migrationArray.length();
        for (int i = 0; i < size; i++) {
            migrationList.add(createMigration(migrationArray.getJSONObject(i)));
        }
        return migrationList;
    }

    private Migration createMigration(JSONObject migrationObject) throws JSONException {
        List<String> queryList = new ArrayList<>();
        JSONArray queryArray = migrationObject.getJSONArray("queryList");
        int querySize = queryArray.length();
        for (int j = 0; j < querySize; j++) {
            queryList.add(queryArray.getString(j));
        }

        Migration migration = new Migration();
        migration.setQueryList(queryList)
                .setTargetDbVersion(migrationObject.getInt("targetDbVersion"));
        return migration;
    }

    private String[] toStringArray(JSONArray array) throws JSONException {
        int length = array.length();
        String[] values = new String[length];
        for (int i = 0; i < length; i++) {
            values[i] = array.getString(i);
        }
        return values;
    }

    private SQLiteOperator getOperator(boolean useexternalDbOperator) {
        return SunbirdDBHelper.getInstance().operator(useexternalDbOperator);
    }
}