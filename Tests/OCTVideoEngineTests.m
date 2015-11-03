//
//  OCTVideoEngineTests.m
//  objcTox
//
//  Created by Chuong Vu on 8/12/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "OCTVideoEngine.h"
#import "OCTPixelBufferPool.h"
#import "OCTVideoView.h"
#import "OCTToxAV.h"

@import AVFoundation;

@interface OCTVideoEngine (Testing)

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) dispatch_queue_t processingQueue;
@property (nonatomic, weak) OCTVideoView *videoView;
@property (strong, nonatomic) OCTPixelBufferPool *pixelPool;

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection;

@end

@interface OCTVideoEngineTests : XCTestCase

@property (strong, nonatomic) OCTVideoEngine *videoEngine;
@property (strong, nonatomic) id mockedToxAV;
@property (strong, nonatomic) id mockedCaptureSession;

@end

@implementation OCTVideoEngineTests

- (void)setUp
{
    [super setUp];
    self.videoEngine = [OCTVideoEngine new];
    self.mockedToxAV = OCMClassMock([OCTToxAV class]);
    self.videoEngine.toxav = self.mockedToxAV;
    self.mockedCaptureSession = OCMClassMock([AVCaptureSession class]);
    self.videoEngine.captureSession = self.mockedCaptureSession;

    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [self.mockedToxAV stopMocking];
    self.mockedToxAV = nil;
    [self.mockedCaptureSession stopMocking];
    self.mockedCaptureSession = nil;
    self.videoEngine = nil;
    [super tearDown];
}

- (void)testInit
{
    XCTAssertNotNil(self.videoEngine);
}

- (void)testStartSendingVideo
{
    OCMStub([self.mockedCaptureSession isRunning]).andReturn(NO);

    [self.videoEngine startSendingVideo];

    dispatch_sync(self.videoEngine.processingQueue, ^{
        OCMVerify([self.mockedCaptureSession startRunning]);
    });
}

- (void)testStopSendingVideo
{
    OCMStub([self.mockedCaptureSession isRunning]).andReturn(YES);

    [self.videoEngine stopSendingVideo];

    dispatch_sync(self.videoEngine.processingQueue, ^{
        OCMVerify([self.mockedCaptureSession stopRunning]);
    });
}

- (void)testIsSendingVideo
{
    OCMStub([self.mockedCaptureSession isRunning]).andReturn(YES);

    XCTAssertTrue([self.videoEngine isSendingVideo]);
}

- (void)testGetVideoCallPreview
{
    id mockedCapturePreviewLayer = OCMClassMock([AVCaptureVideoPreviewLayer class]);
    OCMStub([mockedCapturePreviewLayer layerWithSession:self.mockedCaptureSession]).andReturn(mockedCapturePreviewLayer);

    dispatch_sync(self.videoEngine.processingQueue, ^{
        [self.videoEngine getVideoCallPreview:^(CALayer *layer) {
            XCTAssertEqualObjects(layer, mockedCapturePreviewLayer);
        }];
    });
}

- (void)testVideoFeed
{
    id mockedVideoView = OCMClassMock([OCTVideoView class]);
    OCMStub([mockedVideoView alloc]).andReturn(mockedVideoView);
    OCMStub([mockedVideoView initWithFrame:CGRectZero]).andReturn(mockedVideoView);

    OCTView *view = [self.videoEngine videoFeed];

    XCTAssertEqualObjects(view, mockedVideoView);
}

- (void)testReceiveVideoFrame
{
    OCTToxAVVideoWidth width = 10;
    OCTToxAVVideoHeight height = 10;

    id mockedPixelPool = OCMClassMock([OCTPixelBufferPool class]);
    self.videoEngine.pixelPool = mockedPixelPool;

    OCMStub([mockedPixelPool createPixelBuffer:[OCMArg anyPointer] width:10 height:10]).andReturn(NO);

    self.videoEngine.videoView = OCMClassMock([OCTVideoView class]);

    [self.videoEngine receiveVideoFrameWithWidth:width
                                          height:height
                                          yPlane:nil
                                          uPlane:nil
                                          vPlane:nil
                                         yStride:10
                                         uStride:10
                                         vStride:10
                                    friendNumber:10];

    dispatch_sync(self.videoEngine.processingQueue, ^{
        OCMVerify([mockedPixelPool createPixelBuffer:[OCMArg anyPointer]
                                               width:width
                                              height:height]);
    });
}

@end