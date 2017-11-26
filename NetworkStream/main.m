#import <Foundation/Foundation.h>
#import "ACStream.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSMutableData *sourceData = [NSMutableData data];
        for (int i = 0; i < 1024; i++) {
            NSString *dataStr = @"Hello world.";
            [sourceData appendData:[dataStr dataUsingEncoding:NSUTF8StringEncoding]];
        }
        
        __block void* readBuffer = malloc(sourceData.length);
        memset(readBuffer, 0, sourceData.length);
        
        ACStream *stream = [[ACStream alloc] initWithItemLength:4 * 1024];
        
        //write queue
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSInteger subDataCount = sourceData.length / 1024;
            NSInteger lastDataLength = sourceData.length % 1024;
            
            NSInteger writeTotalLength = 0;
            for (int i = 0; i < subDataCount; i++) {
                [stream write:[sourceData subdataWithRange:NSMakeRange(writeTotalLength, 1024)]];
                writeTotalLength += 1024;
            }
            
            if (lastDataLength != 0)
                [stream write:[sourceData subdataWithRange:NSMakeRange(writeTotalLength, lastDataLength)]];
            NSLog(@"write finished.");
        });
        
        //read queue
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSInteger readLength = 8 * 1024;
            while (readLength == 0) {
                readLength = [stream read:readLength withData:readBuffer];
            }
            
            //some things.
            
            free(readBuffer);
            NSLog(@"read finished.");
        });
    }
    return 0;
}
