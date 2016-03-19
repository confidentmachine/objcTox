//
//  OCTMessageFile.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTObject.h"
#import "OCTToxConstants.h"
#import "OCTManagerConstants.h"

/**
 * Message that contains file, that has been send/received. Represents pending, canceled and loaded files.
 *
 * Please note that all properties of this object are readonly.
 * You can change some of them only with appropriate method in OCTSubmanagerObjects.
 */
@interface OCTMessageFile : OCTObject

/**
 * The current state of file. Only in case if it is OCTMessageFileTypeReady
 * the file can be shown to user.
 */
@property OCTMessageFileType fileType;

/**
 * Size of file in bytes.
 */
@property OCTToxFileSize fileSize;

/**
 * Name of the file as specified by sender. Note that actual fileName in path
 * may differ from this fileName.
 */
@property (nullable) NSString *fileName;

/**
 * Path of file on disk. If you need fileName to show to user please use
 * `fileName` property. filePath has it's own random fileName.
 */
@property (nullable) NSString *filePath;

/**
 * Uniform Type Identifier of file.
 */
@property (nullable) NSString *fileUTI;

@end

RLM_ARRAY_TYPE(OCTMessageFile)
