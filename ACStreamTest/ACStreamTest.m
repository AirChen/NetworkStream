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
    void* buffer = malloc(16 * 1024);
    memset(buffer, 0, 16 * 1024);
    
    ACStream *stream = [[ACStream alloc] initWithItemLength:4 * 1024];
    NSString *dataStr = @"Hello world!";
    NSData *data = [dataStr dataUsingEncoding:NSUTF8StringEncoding];
    BOOL writeFlg = [stream write:data];
    XCTAssertTrue(writeFlg, @"If write correct, return YES.");
    
    NSInteger readLen = [stream read:0 withData:buffer];
    XCTAssertTrue((readLen == 0), @"read length shouldn't be zero.");
    
    readLen = [stream read:data.length withData:buffer];
    XCTAssertTrue((readLen == data.length), @"read success.");
}

@end
