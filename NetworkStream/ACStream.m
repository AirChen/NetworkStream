#import "ACStream.h"

@interface ACStream()
@property(nonatomic, strong)NSMutableArray* dataArray;
@property(nonatomic, assign)NSInteger dataLength;
//标志位，记录位置
@property(nonatomic, assign)NSInteger writeInnerIndex;
@property(nonatomic, assign)NSInteger writeIndex;
@property(nonatomic, assign)NSInteger readInnerIndex;
@property(nonatomic, assign)NSInteger readIndex;
@end

@implementation ACStream
- (instancetype)initWithItemLength:(NSInteger) length {
    self = [super init];
    if (self) {
        _dataLength = length;
        _dataArray = [NSMutableArray array];
        
        [self reset];
    }
    return self;
}

- (void)reset {
    _writeInnerIndex = -1;
    _writeIndex = -1;
    _readIndex = -1;
    _readInnerIndex = -1;
}

- (BOOL)write:(NSData *)data {
    return [self tryWrite:data];
}

- (BOOL)tryWrite:(NSData*)data {
    if (data.length == 0)
        return NO;
    @synchronized(self){
        NSInteger basedIndex = _writeIndex;
        NSInteger basedInnerIndex = _writeInnerIndex;
        
        NSInteger totalLength = (basedIndex + 1) * _dataLength + basedInnerIndex + 1 + data.length;
        _writeIndex = totalLength / _dataLength - 1;
        _writeInnerIndex = totalLength % _dataLength - 1;
        
        void* buffer = malloc(_dataLength);
        memset(buffer, 0, _dataLength);
        
        //写入的第一个data有可能接在上一个未写满的data之后。
        if (basedInnerIndex != -1){
            NSData* lastData = [_dataArray lastObject];
            [lastData getBytes:(buffer) range:NSMakeRange(0, basedInnerIndex + 1)];
            [_dataArray removeLastObject];
        }
        
        BOOL firstFlag = YES;
        NSInteger allWriteLength = 0;
        for (; basedIndex <= _writeIndex; basedIndex++) {
            NSInteger beginIndex = 0;
            NSInteger length = (basedIndex == _writeIndex && _writeInnerIndex != -1) ? _writeInnerIndex + 1 : _dataLength;
            if (firstFlag) {
                beginIndex = basedInnerIndex + 1;
                length = (basedIndex == _writeIndex) ? data.length : _dataLength - basedInnerIndex - 1;
            }else{
                if (basedIndex == _writeIndex && _writeInnerIndex == -1) {
                    break;
                }
            }
            
            [data getBytes:buffer + beginIndex range:NSMakeRange(allWriteLength, length)];
            allWriteLength += length;
            
            //第一个写入的data有可能是两部分组成，一个是已有的，能一个是从输入data里添加的。
            length = firstFlag ? length + basedInnerIndex + 1 : length;
            [_dataArray addObject:[NSData dataWithBytes:buffer length:length]];
            
            firstFlag = NO;
        }
        free(buffer);
    }
    
    return YES;
}

- (NSInteger)read:(NSInteger)dataLength withData:(void *)buffer {
    while ([self size] == 0) {
        [NSThread sleepForTimeInterval:0.01];
    }
    return [self tryRead:dataLength withData:buffer];
}

- (NSInteger)tryRead:(NSInteger)dataLength withData:(void *)buffer {
    if([self size] == 0)
        return -1;
    
    if (dataLength == 0)
        return 0;
    
    NSInteger allReadLength = 0;
    @synchronized(self){
        /*
         1.读数据 based标志 <----> end标志 间的数据
         2.删除subData，清理标志位
         */
        
        NSInteger basedIndex = _readIndex;
        NSInteger basedInnderIndex = _readInnerIndex;
        
        NSInteger endIndex = _writeIndex;
        NSInteger endInnerIndex = _writeInnerIndex;
        
        if (dataLength < [self size]) {
            //更新end标志位
            NSInteger totalLength = (basedIndex + 1) * _dataLength + basedInnderIndex + 1 + dataLength;
            endIndex = totalLength / _dataLength - 1;
            endInnerIndex = totalLength % _dataLength - 1;
        }
    
        BOOL firstFlag = YES;
        for (; basedIndex <= endIndex; basedIndex++) {
            NSInteger length = (basedIndex == endIndex && endInnerIndex != -1) ? endInnerIndex + 1 : _dataLength;
            NSInteger beginIndex = 0;
            
            if (firstFlag) {
                length = (basedIndex == endIndex) ? MIN(dataLength, endInnerIndex - basedInnderIndex) : _dataLength - basedInnderIndex - 1;
                beginIndex = basedInnderIndex + 1;
            }else{
                if (basedIndex == endIndex && endInnerIndex == -1) {
                    break;
                }
            }
            
            NSData* readData = [_dataArray objectAtIndex:basedIndex + 1];
            [readData getBytes:(buffer + allReadLength) range:NSMakeRange(beginIndex, length)];
            allReadLength += length;
            firstFlag = NO;
        }
        
        if (dataLength >= [self size]) {
            [self reset];
            [_dataArray removeAllObjects];
        }else{
            _readInnerIndex = endInnerIndex;
            _readIndex = endIndex;
            //删除读完的数据，更新标志位
            if (endIndex != -1) {
                endIndex++;
                [_dataArray removeObjectsInRange:NSMakeRange(0, endIndex)];
                _readIndex -= endIndex;
                _writeIndex -= endIndex;
            }
        }
    }
    return allReadLength;
}

- (NSInteger)size {
    return (_writeIndex - _readIndex) * _dataLength + (_writeInnerIndex - _readInnerIndex);
}

-(void)dealloc {
    [self.dataArray removeAllObjects];
    self.dataArray = nil;
}
@end
