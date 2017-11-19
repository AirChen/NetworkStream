#import <Foundation/Foundation.h>

@interface ACStream : NSObject
- (instancetype)initWithItemLength:(NSInteger)length;
- (BOOL)write:(NSData *) data;
- (NSInteger)read:(NSInteger)dataLength withData:(void *)buffer;
- (NSInteger)size;
@end
