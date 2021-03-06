//
//  QSPDownloadTool.m
//  QSPDownload_Demo
//
//  Created by 綦 on 17/3/21.
//  Copyright © 2017年 PowesunHolding. All rights reserved.
//

#import "QSPDownloadTool.h"
#import <UIKit/UIKit.h>


@interface QSPDownloadSource ()

@property (strong, nonatomic) NSFileHandle *fileHandle;

@end

@implementation QSPDownloadSource
- (NSFileHandle *)fileHandle
{
    if (_fileHandle == nil) {
        NSURL *url = [NSURL fileURLWithPath:self.location];
        NSLog(@"-----------%@", self.location);
        _fileHandle = url ? [NSFileHandle fileHandleForWritingToURL:url error:nil] : nil;
    }
    
    return _fileHandle;
}
- (void)setStyle:(QSPDownloadSourceStyle)style
{
    if ([self.delegate respondsToSelector:@selector(downloadSource:changedStyle:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate downloadSource:self changedStyle:style];
        });
    }
    
    _style = style;
}
- (void)setNetPath:(NSString *)netPath
{
    _netPath = netPath;
}
- (void)setLocation:(NSString *)location
{
    _location = location;
}
- (void)setTask:(NSURLSessionDataTask *)task
{
    _task = task;
}
- (void)setFileName:(NSString *)fileName
{
    _fileName = fileName;
}
- (void)setTotalBytesWritten:(int64_t)totalBytesWritten
{
    _totalBytesWritten = totalBytesWritten;
}
- (void)setTotalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    _totalBytesExpectedToWrite = totalBytesExpectedToWrite;
}
-(void)setGroupName:(NSString *)groupName{
    _groupName = groupName;
}
-(void)setCourseTitle:(NSString *)courseTitle{
    _courseTitle = courseTitle;
}
-(void)setCourseDuration:(NSString *)courseDuration{
    _courseDuration = courseDuration;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        self.netPath = [aDecoder decodeObjectForKey:@"netPath"];
        self.style = [aDecoder decodeIntegerForKey:@"style"];
        self.task = nil;
        self.fileName = [aDecoder decodeObjectForKey:@"fileName"];
        self.location = [QSPDownloadTool_DownloadDataDocument_Path stringByAppendingPathComponent:self.fileName];
        self.totalBytesWritten = [aDecoder decodeInt64ForKey:@"totalBytesWritten"];
        self.totalBytesExpectedToWrite = [aDecoder decodeInt64ForKey:@"totalBytesExpectedToWrite"];
        self.offLine = [aDecoder decodeBoolForKey:@"offLine"];
        self.groupName = [aDecoder decodeObjectForKey:@"groupName"];
        self.courseTitle = [aDecoder decodeObjectForKey:@"courseTitle"];
        self.courseDuration = [aDecoder decodeObjectForKey:@"courseDuration"];
    }
    
    return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.netPath forKey:@"netPath"];
    [aCoder encodeObject:self.location forKey:@"location"];
    [aCoder encodeInteger:self.style forKey:@"style"];
    [aCoder encodeObject:nil forKey:@"task"];
    [aCoder encodeObject:self.fileName forKey:@"fileName"];
    [aCoder encodeInt64:self.totalBytesWritten forKey:@"totalBytesWritten"];
    [aCoder encodeInt64:self.totalBytesExpectedToWrite forKey:@"totalBytesExpectedToWrite"];
    [aCoder encodeBool:self.offLine forKey:@"offLine"];
    [aCoder encodeObject:self.courseDuration forKey:@"courseDuration"];
    [aCoder encodeObject:self.groupName forKey:@"groupName"];
    [aCoder encodeObject:self.courseTitle forKey:@"courseTitle"];
}

@end


@interface QSPDownloadTool ()<NSURLSessionDataDelegate>

@property (strong, nonatomic) NSMutableArray *downloadSources;
@property (strong, nonatomic) NSURLSession *session;
@property (strong, nonatomic) NSMutableArray *delegateArr;

@end

@implementation QSPDownloadTool

static QSPDownloadTool *_shareInstance;

#pragma mark - 属性方法
- (NSMutableArray *)downloadSources
{
    if (_downloadSources == nil) {
        _downloadSources = [NSMutableArray arrayWithCapacity:1];
        NSArray *arr = [NSArray arrayWithContentsOfFile:QSPDownloadTool_DownloadSources_Path];
        
        for (NSData *data in arr) {
            QSPDownloadSource *source = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[source.netPath stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]]];
            [source setTask:[self.session dataTaskWithRequest:request]];
            [_downloadSources addObject:source];
            
            if (source.isOffLine) {
                if (self.offLineStyle == QSPDownloadToolOffLineStyleDefaut) {
                    if (source.style == QSPDownloadSourceStyleDown || source.style == QSPDownloadSourceStyleSuspend) {
                        source.style = QSPDownloadSourceStyleDown;
                        [self suspendDownload:source];
                    }
                }
                else if (self.offLineStyle == QSPDownloadToolOffLineStyleAuto)
                {
                    if (source.style == QSPDownloadSourceStyleDown || source.style == QSPDownloadSourceStyleSuspend || source.style == QSPDownloadSourceStyleFail) {
                        source.style = QSPDownloadSourceStyleSuspend;
                        [self continueDownload:source];
                    }
                }
                else if (self.offLineStyle == QSPDownloadToolOffLineStyleFromSource)
                {
                    if (source.style == QSPDownloadSourceStyleDown) {
                        source.style = QSPDownloadSourceStyleSuspend;
                        [self continueDownload:source];
                    }
                }
            }
        }
    }
    
    return _downloadSources;
}
- (QSPDownloadToolOffLineStyle)offLineStyle
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:QSPDownloadTool_OffLineStyle_Key];
}
- (void)setOffLineStyle:(QSPDownloadToolOffLineStyle)offLineStyle
{
    [[NSUserDefaults standardUserDefaults] setInteger:self.offLineStyle forKey:QSPDownloadTool_OffLineStyle_Key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSURLSession *)session
{
    if (_session == nil) {
        //可以上传下载HTTP和HTTPS的后台任务(程序在后台运行)。 在后台时，将网络传输交给系统的单独的一个进程,即使app挂起、推出甚至崩溃照样在后台执行。
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"QSPDownload"];
        _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    }
    
    return _session;
}
- (NSMutableArray *)delegateArr
{
    if (_delegateArr == nil) {
        _delegateArr = [NSMutableArray arrayWithCapacity:1];
    }
    
    return _delegateArr;
}
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shareInstance = [super allocWithZone:zone];
        [[NSNotificationCenter defaultCenter] addObserver:_shareInstance selector:@selector(terminateAction:) name:UIApplicationWillTerminateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:_shareInstance selector:@selector(saveDownloadSource) name:UIApplicationDidEnterBackgroundNotification object:nil];
    });
    
    return _shareInstance;
}
+ (void)initialize {
    if (![[NSFileManager defaultManager] fileExistsAtPath:QSPDownloadTool_DownloadDataDocument_Path]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:QSPDownloadTool_DownloadDataDocument_Path withIntermediateDirectories:YES attributes:nil error:nil];
    }
}
- (void)terminateAction:(NSNotification *)sender
{
    [self saveDownloadSource];
}
- (void)saveDownloadSource
{
    NSMutableArray *mArr = [[NSMutableArray alloc] initWithCapacity:1];
    for (QSPDownloadSource *souce in self.downloadSources) {
        if (souce.isOffLine) {
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:souce];
            [mArr addObject:data];
        }
    }
    
    [mArr writeToFile:QSPDownloadTool_DownloadSources_Path atomically:YES];
}
+ (instancetype)shareInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shareInstance = [[self alloc] init];
    });
    
    return _shareInstance;
}

/**
 按字节计算文件大小

 @param tytes 字节数
 @return 文件大小字符串
 */
+ (NSString *)calculationDataWithBytes:(int64_t)tytes
{
    NSString *result;
    double length;
    if (tytes > QSPDownloadTool_Limit) {
        length = tytes/QSPDownloadTool_Limit;
        if (length > QSPDownloadTool_Limit) {
            length /= QSPDownloadTool_Limit;
            if (length > QSPDownloadTool_Limit) {
                length /= QSPDownloadTool_Limit;
                if (length > QSPDownloadTool_Limit) {
                    length /= QSPDownloadTool_Limit;
                    result = [NSString stringWithFormat:@"%.2fTB", length];
                }
                else
                {
                    result = [NSString stringWithFormat:@"%.2fGB", length];
                }
            }
            else
            {
                result = [NSString stringWithFormat:@"%.2fMB", length];
            }
        }
        else
        {
            result = [NSString stringWithFormat:@"%.2fKB", length];
        }
    }
    else
    {
        result = [NSString stringWithFormat:@"%lliB", tytes];
    }
    
    return result;
}

/**
 添加下载任务
 
 @param netPath 下载地址
 @return 下载任务数据模型
 */
- (void)addDownloadTast:(NSString *)netPath andCourseName:(NSString *)courseName andCourseDuration:(NSString *)courseDuration andGroupName:(NSString *)groupName
{
//    QSPDownloadSourceStyle style = [self exitDownloadTask:netPath];
//    if (style == QSPDownloadSourceStyleFinished || style == QSPDownloadSourceStyleDown) {
//
//        NSString * messageStr = style==QSPDownloadSourceStyleFinished ? @"视频已下载，请在我的缓存中查看":@"视频正在下载，请在我的缓存中查看";
//
//        UIAlertController * control = [UIAlertController alertControllerWithTitle:@"提示" message:messageStr preferredStyle:UIAlertControllerStyleAlert];
//        UIAlertAction * action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//
//        }];
//        [control addAction:action];
//
//        [vc presentViewController:control animated:YES completion:nil];
//
//        return;
//    }
    
    QSPDownloadSource *source = [[QSPDownloadSource alloc] init];
    [source setNetPath:netPath];
    
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[netPath stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]]];
    [source setTask:[self.session dataTaskWithRequest:request]];
//    [source setFileName:[self getFileName:[[netPath componentsSeparatedByString:@"/"] lastObject]]];
    [source setFileName:[self getFileName:[self getVideoName]]];

    [source setLocation:[QSPDownloadTool_DownloadDataDocument_Path stringByAppendingPathComponent:source.fileName]];
    
    [source setCourseDuration:courseDuration];
    [source setCourseTitle:courseName];
    [source setGroupName:groupName];
    
    source.style = QSPDownloadSourceStyleDown;
    source.offLine = YES;
    //开始下载任务
    [source.task resume];
    [(NSMutableArray *)self.downloadSources addObject:source];
    [self saveDownloadSource];
//    return source;
    
    
//    UIAlertController * control = [UIAlertController alertControllerWithTitle:@"提示" message:@"视频已加入队列，请在我的离线缓存中查看!" preferredStyle:UIAlertControllerStyleAlert];
//    UIAlertAction * action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//
//    }];
//    [control addAction:action];
    
//    [vc presentViewController:control animated:YES completion:nil];
    
    
}

-(NSString *)getVideoName{
    NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
    
    NSTimeInterval a=[dat timeIntervalSince1970];
    
    NSString*timeString = [NSString stringWithFormat:@"%0.f", a];
    
    return [NSString stringWithFormat:@"%@.pdf" , timeString];
}

-(NSString *)getDownloadTime{
    
    NSDateFormatter * format = [[NSDateFormatter alloc] init];
    format.dateFormat = @"YYYY.MM.dd";//YYYY-MM-dd HH:mm:ss
    return [format stringFromDate:[NSDate date]];
}

- (NSString *)getFileName:(NSString *)sourceName
{
    NSArray *arr = [sourceName componentsSeparatedByString:@"."];
    NSString *type = arr.count > 1 ? [arr lastObject] : nil;
    NSString *name = type ? [sourceName substringToIndex:sourceName.length - type.length - 1] : sourceName;
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *result = sourceName;
    int count = 0;
    do {
        if ([manager fileExistsAtPath:[QSPDownloadTool_DownloadDataDocument_Path stringByAppendingPathComponent:result]]) {
            count++;
            result = type ? [NSString stringWithFormat:@"%@ (%i).%@", name, count, type] : [NSString stringWithFormat:@"%@ (%i)", name, count];
        }
        else
        {
            [manager createFileAtPath:[QSPDownloadTool_DownloadDataDocument_Path stringByAppendingPathComponent:result] contents:nil attributes:nil];
            return result;
        }
    } while (1);
}
- (void)addDownloadToolDelegate:(id<QSPDownloadToolDelegate>)delegate
{
    for (QSPDownloadToolDelegateObject *obj in self.delegateArr) {
        if (obj.delegate == delegate) {
            return;
        }
    }
    
    QSPDownloadToolDelegateObject *delegateObj = [[QSPDownloadToolDelegateObject alloc] init];
    delegateObj.delegate = delegate;
    [self.delegateArr addObject:delegateObj];
}
- (void)removeDownloadToolDelegate:(id<QSPDownloadToolDelegate>)delegate
{
    for (QSPDownloadToolDelegateObject *obj in self.delegateArr) {
        if (obj.delegate == delegate) {
            [self.delegateArr removeObject:delegate];
            return;
        }
    }
}

/**
 暂停下载任务
 
 @param source 下载任务数据模型
 */
- (void)suspendDownload:(QSPDownloadSource *)source
{
    if (source.style == QSPDownloadSourceStyleDown || source.style == QSPDownloadSourceStyleFail) {
        [source.task cancel];
        source.style = QSPDownloadSourceStyleSuspend;
    }
    else
    {
        NSLog(@"不能暂停未开始的下载任务！");
    }
}
- (void)suspendAllTask
{
    for (QSPDownloadSource *source in self.downloadSources) {
        [self suspendDownload:source];
    }
}
/**
 继续下载任务
 
 @param source 下载任务数据模型
 */
- (void)continueDownload:(QSPDownloadSource *)source
{
    if (source.style == QSPDownloadSourceStyleSuspend || source.style == QSPDownloadSourceStyleFail) {
        source.style = QSPDownloadSourceStyleDown;
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[source.netPath stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]]];
        [request setValue:[NSString stringWithFormat:@"bytes=%lld-", source.totalBytesWritten] forHTTPHeaderField:@"Range"];
        source.task = [self.session dataTaskWithRequest:request];
        [source.task resume];
    }
    else
    {
        NSLog(@"不能继续未暂停的下载任务！");
    }
}
- (void)startAllTask
{
    for (QSPDownloadSource *source in self.downloadSources) {
        [self continueDownload:source];
    }
}
/**
 停止下载任务
 
 @param source 下载任务数据模型
 */
- (void)stopDownload:(QSPDownloadSource *)source
{
    if (source.style == QSPDownloadSourceStyleDown) {
        [source.task cancel];
    }
    
    source.style = QSPDownloadSourceStyleStop;
    [source.fileHandle closeFile];
    source.fileHandle = nil;
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtURL:[NSURL fileURLWithPath:source.location] error:&error];
    if (error) {
        NSLog(@"----------删除文件失败！\n%@\n%@", error, source.location);
    }
    [(NSMutableArray *)self.downloadSources removeObject:source];
    [self saveDownloadSource];
}
- (void)stopAllTask
{
    for (QSPDownloadSource *source in self.downloadSources) {
        [self stopDownload:source];
    }
}
#pragma mark - NSURLSessionDataDelegate代理方法
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    NSLog(@"%s  expectedContentLength %lld", __FUNCTION__ ,  response.expectedContentLength);
    NSLog(@"%lld" , dataTask.response.expectedContentLength);
    dispatch_async(dispatch_get_main_queue(), ^{
        for (QSPDownloadSource *source in self.downloadSources) {
            if (source.task == dataTask) {
                source.totalBytesExpectedToWrite = source.totalBytesWritten + response.expectedContentLength;
            }
        }
    });
    
    NSHTTPURLResponse * sss =(NSHTTPURLResponse*)response;
    NSLog(@"allHeaderFields ==  %@" , sss.allHeaderFields);
    
    // 允许处理服务器的响应，才会继续接收服务器返回的数据
    completionHandler(NSURLSessionResponseAllow);
}
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    dispatch_async(dispatch_get_main_queue(), ^{
        for (QSPDownloadSource *source in self.downloadSources) {
            if (source.task == dataTask) {
                [source.fileHandle seekToEndOfFile];
                [source.fileHandle writeData:data];
                source.totalBytesWritten += data.length;
                if ([source.delegate respondsToSelector:@selector(downloadSource:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:)]) {
                    [source.delegate downloadSource:source didWriteData:data totalBytesWritten:source.totalBytesWritten totalBytesExpectedToWrite:source.totalBytesExpectedToWrite];
                }
            }
        }
    });
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error) {
        NSLog(@"%@", error);
        NSLog(@"%@", error.userInfo);
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        QSPDownloadSource *currentSource = nil;
        for (QSPDownloadSource *source in self.downloadSources) {
            if (source.fileHandle) {
                [source.fileHandle closeFile];
                source.fileHandle = nil;
            }
            
            if (error) {
                if (source.task == task && source.style == QSPDownloadSourceStyleDown) {
                    source.style = QSPDownloadSourceStyleFail;
                    if (error.code == -997) {
                        [self continueDownload:source];
                    }
                }
            }
            else
            {
                if (source.task == task) {
                    currentSource = source;
                    break;
                }
            }
        }
        
        if (currentSource) {
            currentSource.style = QSPDownloadSourceStyleFinished;
            [(NSMutableArray *)self.downloadSources removeObject:currentSource];
            [self saveDownloadSource];
            for (QSPDownloadToolDelegateObject *delegateObj in self.delegateArr) {
                if ([delegateObj.delegate respondsToSelector:@selector(downloadToolDidFinish:downloadSource:)]) {
                    [delegateObj.delegate downloadToolDidFinish:self downloadSource:currentSource];
                }
            }
            //下载完成了
            
            NSArray *arr = [NSArray arrayWithContentsOfFile:QSPDownloadTool_DownloadFinishedSources_Path];
            NSMutableArray *mArr = [NSMutableArray arrayWithArray:arr];
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:currentSource];
            [mArr insertObject:data atIndex:0];
            [mArr writeToFile:QSPDownloadTool_DownloadFinishedSources_Path atomically:YES];
            
        }
    });
}

-(QSPDownloadSourceStyle)exitDownloadTask:(NSString *)pathString{
    
    for (QSPDownloadSource * source in self.downloadSources) {
        if ([source.netPath isEqualToString:pathString]) {
            
            return QSPDownloadSourceStyleDown;//下载中
        }
    }
    NSArray *arr = [NSArray arrayWithContentsOfFile:QSPDownloadTool_DownloadFinishedSources_Path];
    for (NSData *data in arr) {
        QSPDownloadSource *source = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if ([source.netPath isEqualToString:pathString]) {
            
            return QSPDownloadSourceStyleFinished;//已下载
        }
    }
    return QSPDownloadSourceStyleFail;//这里表明可以继续下载
}

- (UIViewController *)getCurrentVC
{
    UIViewController *result = nil;
    
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal)
    {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow * tmpWin in windows)
        {
            if (tmpWin.windowLevel == UIWindowLevelNormal)
            {
                window = tmpWin;
                break;
            }
        }
    }
    
    UIView *frontView = [[window subviews] objectAtIndex:0];
    id nextResponder = [frontView nextResponder];
    
    if ([nextResponder isKindOfClass:[UIViewController class]])
        result = nextResponder;
    else
        result = window.rootViewController;
    
    return result;
}

@end


@implementation QSPDownloadToolDelegateObject

@end

