//
//  ViewController.m
//  FileShow
//
//  Created by zyy on 2019/1/9.
//  Copyright © 2019年 zyy. All rights reserved.
//

#import "ViewController.h"
#import "FirstViewController.h"
#import <QuickLook/QuickLook.h>
#import <AFNetworking/AFNetworking.h>
#import "QSPDownloadTool.h"

@interface ViewController ()<QLPreviewControllerDataSource,UIDocumentInteractionControllerDelegate , QSPDownloadToolDelegate>

@property(nonatomic,strong) QLPreviewController * previewVC;

@property(nonatomic,strong) NSURL * fileUrlStr;

@property(nonatomic,strong)UIDocumentInteractionController * documentInteractionController;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton * but = [UIButton buttonWithType:UIButtonTypeCustom];
    but.frame = CGRectMake(40, 600, 50, 100);
    [but setTitle:@"点击分享" forState:UIControlStateNormal];
    [but setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    
    [but addTarget:self action:@selector(click) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:but];
    
//    self.fileUrlStr = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"test" ofType:@"pdf"]];
//    self.fileUrlStr = [NSURL URLWithString:@"http://192.168.12.10:80/static-server/pic/10000000/PreciseTeachingResearch/2019/20190109/40b5652194734a719641423e313214c2//2019-01-09-14:12:25.856file.pdf"];
    //http://192.168.12.10:80/static-server/pic/10000000/PreciseTeachingResearch/2019/20190109/40b5652194734a719641423e313214c2//2019-01-09-14:12:25.856file.pdf
    
//    self.previewVC = [[QLPreviewController alloc] init];
//    self.previewVC.dataSource = self;
//    [self addChildViewController:self.previewVC];
//    self.previewVC.view.frame = CGRectMake(0, 0, self.view.frame.size.width, 500);
//    [self.view addSubview:self.previewVC.view];
 
//    [self loadFile];
    
    [[QSPDownloadTool shareInstance] addDownloadToolDelegate:self];
    
    UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(100, 600, 50, 100);
    [button setTitle:@"下载" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(uplod) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    
}

-(void)uplod{
    [[QSPDownloadTool shareInstance] addDownloadTast:@"http://192.168.12.10:80/static-server/pic/10000000/PreciseTeachingResearch/2019/20190109/40b5652194734a719641423e313214c2//2019-01-09-14:12:25.856file.pdf" andCourseName:@"1" andCourseDuration:@"2" andGroupName:@"3"];
}

-(void)downloadToolDidFinish:(QSPDownloadTool *)tool downloadSource:(QSPDownloadSource *)source{
    NSLog(@" 下载完成   %@   %@ " , source , source.location );
    
    self.fileUrlStr = [NSURL fileURLWithPath:source.location];
    
    self.previewVC = [[QLPreviewController alloc] init];
    self.previewVC.dataSource = self;
    [self addChildViewController:self.previewVC];
    self.previewVC.view.frame = CGRectMake(0, 0, self.view.frame.size.width, 500);
    [self.view addSubview:self.previewVC.view];
    
}

-(void)loadFile{
    
    AFHTTPSessionManager * manager = [AFHTTPSessionManager manager];
    NSURL *url = [NSURL URLWithString:@"http://192.168.12.10:80/static-server/pic/10000000/PreciseTeachingResearch/2019/20190109/40b5652194734a719641423e313214c2//2019-01-09-14:12:25.856file.pdf"];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    NSURLSessionDownloadTask *download = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        
        //监听下载进度
        //completedUnitCount 已经下载的数据大小
        //totalUnitCount     文件数据的中大小
        NSLog(@"%f",1.0 *downloadProgress.completedUnitCount / downloadProgress.totalUnitCount);
        
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        
        NSString *fullPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:response.suggestedFilename];
        
        NSLog(@"targetPath:%@",targetPath);
        NSLog(@"fullPath:%@",fullPath);
        
        return [NSURL fileURLWithPath:fullPath];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        
        NSLog(@"成功 %@",filePath);
        
        self.fileUrlStr = filePath;
        
        self.previewVC = [[QLPreviewController alloc] init];
        self.previewVC.dataSource = self;
        [self addChildViewController:self.previewVC];
        self.previewVC.view.frame = CGRectMake(0, 0, self.view.frame.size.width, 500);
        [self.view addSubview:self.previewVC.view];
        
    }];
    [download resume];
}


-(void)click{
    
    UIAlertController * vc = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction * action = [UIAlertAction actionWithTitle:@"用其他应用打开" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self showFileToOtherApp];
        
    }];
    [vc addAction:action];
    
    UIAlertAction * act = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [vc addAction:act];
    
    [self presentViewController:vc animated:YES completion:nil];
}

-(void)showFileToOtherApp{
    _documentInteractionController = [UIDocumentInteractionController
                                      interactionControllerWithURL:self.fileUrlStr];
    [_documentInteractionController setDelegate:self];
    [_documentInteractionController presentPreviewAnimated:YES];
    [_documentInteractionController presentOpenInMenuFromRect:CGRectZero inView:self.view animated:YES];
}

-(NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller{
    return 1;
}

- (id <QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index{
    
    //读取沙盒中的文件
    
    return self.fileUrlStr;
    
}



@end
