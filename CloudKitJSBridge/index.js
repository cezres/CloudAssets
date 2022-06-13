import { PromisesApi, CKEnvironment, CKDatabaseType, CKDBAssetUploadUrlResponse, CKDBAsset, createCKDBRecordFieldStringValue, createCKDBRecordFieldInt64Value, toInt64, createCKDBRecordFieldAssetValue } from "@apple/cktool.database";
import { createConfiguration } from "@apple/cktool.target.browser"

export function wk_callback(value) {
    webkit.messageHandlers.bridge.postMessage(value)
}

var api = new PromisesApi({
    configuration: createConfiguration(),
    security: { 
        "UserTokenAuth": "",
    }
});
var defaultParams = {}

export function configureEnvironment(containerId, environment, userToken) {
    api = new PromisesApi({
        configuration: createConfiguration(),
        security: { 
            "UserTokenAuth": userToken,
        }
    });
    defaultParams = {
        containerId: containerId,
        environment: environment,
        databaseType: CKDatabaseType.PUBLIC,
        zoneName: "_defaultZone",
    };
    console.log(defaultParams)
    console.log(api)
}

export function createAssetUploadUrl(id, recordType, fieldName, size) {
    api.createAssetUploadUrl({
        ...defaultParams,
        body: {
            recordType: recordType,
            fieldName: fieldName,
            size: toInt64(size)
        }
    }).then( response => {
        console.log(response.result)
        wk_callback({ ...response, id: id, data: response.result.url })
    }).catch(error => {
        console.log(error)
        wk_callback({ id: id, error: error })
    })
}

export function createResourceRecord(id, recordName, name, version, pathExtension, fileChecksum, receipt, size) {
    api.createRecord({
        ...defaultParams,
        body: {
            recordType: "Resource",
            recordName: recordName,
            fields: {
                "name": createCKDBRecordFieldStringValue({ 
                    value: name 
                }),
                "version": createCKDBRecordFieldInt64Value({ 
                    value: toInt64(version) 
                }),
                "pathExtension": createCKDBRecordFieldStringValue({
                    value: pathExtension
                }),
                "asset": createCKDBRecordFieldAssetValue({ 
                    value: { fileChecksum: fileChecksum, receipt: receipt, size: toInt64(size) } 
                }),
            }
        }
    }).then(response => {
        console.log(response)
        wk_callback({ ...response, id: id, data: convertResourceRecord(response.result.record) })
    }).catch(error => {
        console.log(error)
        wk_callback({ id: id, error: error })
    })
}

export function createResourceIndexesRecord(id, recordName, version, fileChecksum, receipt, size) {
    api.createRecord({
        ...defaultParams,
        body: {
            recordType: "ResourceIndexes",
            recordName: recordName,
            fields: {
                "version": createCKDBRecordFieldInt64Value({
                    value: toInt64(version)
                }),
                "indexes": createCKDBRecordFieldAssetValue({ 
                    value: { fileChecksum: fileChecksum, receipt: receipt, size: toInt64(size) } 
                })
            }
        }
    }).then( response => {
        wk_callback({ ...response, id: id, data: convertResourceIndexesRecord(response.result.record) })
    }).catch( error => {
        wk_callback({ id: id, error: error })
    })
}

export function queryResourceRecords(id) {
    api.queryRecords({
        ...defaultParams,
        body: {
            query: {
                recordType: "Resource",
            },
            resultsLimit: 20,
        }
    }).then( response => {
        const resources = response.result.records.map( element => {
            return convertResourceRecord(element)
        })
        wk_callback({ ...response, data: resources, id: id })
    }).catch( error => {
        wk_callback({error: error.message, id: id})
    })
}

export function queryResourceIndexRecords(id) {
    api.queryRecords({
        ...defaultParams,
        body: {
            query: {
                recordType: "ResourceIndexes"
            },
            resultsLimit: 20,
        }
    }).then( response => {
        console.log(response)
        const indexs = response.result.records.map( element => {
            return convertResourceIndexesRecord(element)
        })
        wk_callback({ ...response, id: id, data: indexs})
    }).catch( error => {
        console.log(error)
        wk_callback({error: error.message, id: id})
    })
}

export function searchResourceIndexesRecord(id, recordName) {
    api.getRecord({
        ...defaultParams,
        recordName: recordName,
    }).then( response => {
        wk_callback({ ...response, id: id, data: convertResourceIndexesRecord(response.result.record) })
    }).catch( error => {
        wk_callback({ id: id, error: error })
    })
}

export function updateResourceIndexesRecord(id, recordName, version, fileChecksum, receipt, size) {
    api.updateRecord({
        ...defaultParams,
        recordName: recordName,
        force: "true",
        body: {
            recordType: "ResourceIndexes",
            fields: {
                "version": createCKDBRecordFieldInt64Value({
                    value: toInt64(version)
                }),
                "indexes": createCKDBRecordFieldAssetValue({ 
                    value: { fileChecksum: fileChecksum, receipt: receipt, size: toInt64(size) } 
                })
            }
        }
    }).then( response => {
        wk_callback({ ...response, id: id, data: convertResourceIndexesRecord(response.result.record) })
    }).catch( error => {
        wk_callback({ error: error})
        createResourceIndexRecord(id, recordName, version, fileChecksum, receipt, size)
    })
}

export function deleteRecord(id, recordName) {
    api.deleteRecord({
        ...defaultParams,
        recordName: recordName,
    }).then( response => {
        console.log(response)
        wk_callback({ ...response, id: id, data: recordName })
    }).catch( error => {
        console.log(error)
        wk_callback({ id: id, error: error })
    })
}

function convertResourceRecord(record) {
    return {
        recordName: record.recordName,
        name: record.fields.name.value,
        version: record.fields.version.value.toNumber(),
        pathExtension: record.fields.pathExtension.value,
        asset: convertCKDBAsset(record.fields.asset.value)
    }
}

function convertResourceIndexesRecord(record) {
    return {
        recordName: record.recordName,
        version: record.fields.version.value.toNumber(),
        indexes: convertCKDBAsset(record.fields.indexes.value)
    }
}

function convertCKDBAsset(asset) {
    return {
        downloadUrl: asset.downloadUrl,
        fileChecksum: asset.fileChecksum,
        size: asset.size.toNumber(),
    }
}

console.log("CKToolJS - injected")
