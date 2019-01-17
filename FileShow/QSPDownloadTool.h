//
//  QSPDownloadTool.h
//  QSPDownload_Demo
//
//  Created by 綦 on 17/3/21.
//  Copyright © 2017年 PowesunHolding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Downloadheader.h"

typedef NS_ENUM(NSInteger, QSPDownloadSourceStyle) {
    QSPDownloadSourceStyleDown = 0,//下载
    QSPDownloadSourceStyleSuspend = 1,//暂停
    QSPDownloadSourceStyleStop = 2,//停止
    QSPDownloadSourceStyleFinished = 3,//完成
    QSPDownloadSourceStyleFail = 4//失败
};

@class QSPDownloadSource;
@protocol QSPDownloadSourceDelegate <NSObject>
@optional
- (void)downloadSource:(QSPDownloadSource *)source changedStyle:(QSPDownloadSourceStyle)style;
- (void)downloadSource:(QSPDownloadSource *)source didWriteData:(NSData *)data totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite;
@end

@interface QSPDownloadSource : NSObject <NSCoding>
//地址路径
@property (copy, nonatomic, readonly) NSString *netPath;
//本地路径
@property (copy, nonatomic, readonly) NSString *location;
//下载状态
@property (assign, nonatomic) QSPDownloadSourceStyle style;
//下载任务
@property (strong, nonatomic, readonly) NSURLSessionDataTask *task;
//文件名称
@property (strong, nonatomic, readonly) NSString *fileName;
//已下载的字节数
@property (assign, nonatomic, readonly) int64_t totalBytesWritten;
//文件字节数
@property (assign, nonatomic, readonly) int64_t totalBytesExpectedToWrite;
//是否离线下载
@property (assign, nonatomic, getter=isOffLine) BOOL offLine;
//代理
@property (weak, nonatomic) id<QSPDownloadSourceDelegate> delegate;
//课程名字
@property (copy , nonatomic,readonly) NSString * courseTitle;
//课程时长
@property (copy , nonatomic , readonly) NSString * courseDuration;
//教研组
@property (copy , nonatomic , readonly) NSString * groupName;
@end


@class QSPDownloadTool;
@protocol QSPDownloadToolDelegate <NSObject>

- (void)downloadToolDidFinish:(QSPDownloadTool *)tool downloadSource:(QSPDownloadSource *)source;

@end

typedef NS_ENUM(NSInteger, QSPDownloadToolOffLineStyle) {
    QSPDownloadToolOffLineStyleDefaut = 0,//默认离线后暂停
    QSPDownloadToolOffLineStyleAuto = 1,//根据保存的状态自动处理
    QSPDownloadToolOffLineStyleFromSource = 2//根据保存的状态自动处理
};
@interface QSPDownloadTool : NSObject

/**
 下载的所有任务资源
 */
@property (strong, nonatomic, readonly) NSArray *downloadSources;
//离线后的下载方式
@property (assign, nonatomic) QSPDownloadToolOffLineStyle offLineStyle;

+ (instancetype)shareInstance;

/**
 按字节计算文件大小
 
 @param tytes 字节数
 @return 文件大小字符串
 */
+ (NSString *)calculationDataWithBytes:(int64_t)tytes;

/**
 添加下载任务

 @param netPath 下载地址
 @return 下载任务数据模型
 */
////// netPath 网络下载地址   videoTitle视频的title  videoAuthor 视频的发布者  VideoCoverUrl视频的封面图片URL  videoTime视频的发布时间  offLine都为yes 离线下载  vc当前控制器
- (void)addDownloadTast:(NSString *)netPath andCourseName:(NSString *)courseName andCourseDuration:(NSString *)courseDuration andGroupName:(NSString *)groupName;

/**
 添加代理
 
 @param delegate 代理对象
 */
- (void)addDownloadToolDelegate:(id<QSPDownloadToolDelegate>)delegate;
/**
 移除代理

 @param delegate 代理对象
 */
- (void)removeDownloadToolDelegate:(id<QSPDownloadToolDelegate>)delegate;

/**
 暂停下载任务

 @param source 下载任务数据模型
 */
- (void)suspendDownload:(QSPDownloadSource *)source;
/**
 暂停所有下载任务
 */
- (void)suspendAllTask;

/**
 继续下载任务

 @param source 下载任务数据模型
 */
- (void)continueDownload:(QSPDownloadSource *)source;
/**
 开启所有下载任务
 */
- (void)startAllTask;
/**
 停止下载任务

 @param source 下载任务数据模型
 */
- (void)stopDownload:(QSPDownloadSource *)source;
/**
 停止所有下载任务
 */
- (void)stopAllTask;

/**
 查看是否当前视频已经缓存或者是正在缓存
 */
-(QSPDownloadSourceStyle)exitDownloadTask:(NSString *)pathString;

@end


@interface QSPDownloadToolDelegateObject : NSObject

@property (weak, nonatomic) id<QSPDownloadToolDelegate> delegate;

@end
