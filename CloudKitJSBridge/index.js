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

export function createResourceIndexRecord(id, recordName, version, fileChecksum, receipt, size) {
    api.createRecord({
        ...defaultParams,
        body: {
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
        wk_callback({ ...response, id: id, data: convertResourceIndexRecord(response.result.record) })
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

export function queryAssetIndexsRecords(id, continuationToken) {
    // if (continuationToken) {
    //     api.queryRecords({
    //         ...defaultParams,
    //         body: {
    //             continuationToken: continuationToken,
    //             resultsLimit: 10,
    //         }
    //     }).then( value => {
    //         const indexs = value.result.records.map( element => {
    //             return convertAssetIndexs(element)
    //         })
    //         wk_callback({id: id, result: indexs, continuationToken: value.result.continuationToken})
    //     }).catch( error => {
    //         wk_callback({error: error.message, id: id})
    //     })
    // } else {
        api.queryRecords({
            ...defaultParams,
            body: {
                query: {
                    recordType: "AssetIndexs"
                },
                resultsLimit: 10,
            }
        }).then( response => {
            console.log(response)
            const indexs = response.result.records.map( element => {
                return convertAssetIndexsRecord(element)
            })
            wk_callback({ ...response, id: id, data: indexs})
        }).catch( error => {
            console.log(error)
            wk_callback({error: error.message, id: id})
        })
    // }
}

export function createAssetIndexsRecord(id, recordName, version, fileChecksum, receipt, size) {
    api.createRecord({
        ...defaultParams,
        body: {
            recordType: "AssetIndexs",
            recordName: recordName,
            fields: {
                "version": createCKDBRecordFieldInt64Value({ 
                    value: toInt64(version) 
                }),
                "indexs": createCKDBRecordFieldAssetValue({ 
                    value: { fileChecksum: fileChecksum, receipt: receipt, size: toInt64(size) } 
                }),
            }
        }
    }).then( response => {
        console.log(response)
        wk_callback({ ...response, id: id, data: convertAssetIndexsRecord(response.result.record) })
    }).catch( error => {
        console.log(error)
        wk_callback({error: error.message, id: id})
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

function convertAssetIndexsRecord(record) {
    return {
        recordName: record.recordName,
        version: record.fields.version.value.toNumber(),
        indexs: convertCKDBAsset(record.fields.indexs.value)
    }
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

function convertResourceIndexRecord(record) {
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
