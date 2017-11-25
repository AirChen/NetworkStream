//
//  ACStreamTest.m
//  ACStreamTest
//
//  Created by air on 2017/11/25.
//  Copyright © 2017年 Air_chen. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ACStream.h"

@interface ACStreamTest : XCTestCase

@end

@implementation ACStreamTest

- (void)testWrite {
    ACStream *stream = [[ACStream alloc] initWithItemLength:1024 * 16];
    NSData *data = [NSData data];
    BOOL writeFlg = [stream write:data];
    XCTAssertFalse(writeFlg, @"Data length shouldn't equal to zero.");
    
    NSString *dataStr = @"Hello world!";
    data = [dataStr dataUsingEncoding:NSUTF8StringEncoding];
    writeFlg = [stream write:data];
    XCTAssertTrue(writeFlg, @"If write correct, return YES.");
}

- (void)testRead {
    
}

- (void)testMutableThreads {
    
}

@end
