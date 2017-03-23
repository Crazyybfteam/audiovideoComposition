//
//  ViewController.m
//  VideoRecoderDemo
//
//  Created by Damon on 16/8/29.
//  Copyright © 2016年 damonvvong. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreAudioKit/CoreAudioKit.h>
#import <CoreMedia/CoreMedia.h>
#include "amrFileCodec.h"
@interface ViewController ()<AVCaptureFileOutputRecordingDelegate>
{
    AVAudioRecorder *recorder;
    NSString* path;
}

@property (nonatomic, strong) AVCaptureSession			 *captureSession;			/**< 捕捉会话 */
@property (nonatomic,   weak) AVCaptureDeviceInput		 *captureVideoInput;		/**< 视频捕捉输出 */
@property (nonatomic, strong) AVCaptureMovieFileOutput	 *captureMovieFileOutput;	/**< 视频输出流 */
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer; /**< 相机拍摄预览图层 */

@property   (nonatomic, strong)NSURL *videoUrl;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //
    //	self.captureSession = ({
    //
    //		AVCaptureSession *session = [[AVCaptureSession alloc] init];
    //		if ([session canSetSessionPreset:AVCaptureSessionPresetHigh]) {
    //			[session setSessionPreset:AVCaptureSessionPresetHigh];
    //		}
    //		session;
    //
    //	});
    //	NSError *error = nil;
    //	[self setupSessionInputs:&error];
    //
    //	//初始化设备输出对象，用于获得输出数据
    //	self.captureMovieFileOutput = ({
    //		AVCaptureMovieFileOutput *output = [[AVCaptureMovieFileOutput alloc]init];
    //		// 设置录制模式
    //		AVCaptureConnection *captureConnection=[output connectionWithMediaType:AVMediaTypeVideo];
    //		if ([captureConnection isVideoStabilizationSupported ]) {
    //			captureConnection.preferredVideoStabilizationMode=AVCaptureVideoStabilizationModeAuto;
    //		}
    //		//将设备输出添加到会话中
    //		if ([self.captureSession canAddOutput:output]) {
    //			[self.captureSession addOutput:output];
    //		}
    //		output;
    //	});
    //
    //
    //	//创建视频预览层，用于实时展示摄像头状态
    //	self.captureVideoPreviewLayer = ({
    //		AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.captureSession];
    //		previewLayer.frame=  CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    //		previewLayer.videoGravity=AVLayerVideoGravityResizeAspectFill;//填充模式
    //		[self.view.layer addSublayer:previewLayer];
    //		self.view.layer.masksToBounds = YES;
    //		previewLayer;
    //
    //	});
    //
    //
    //	[self.captureSession startRunning];
    
    //    _videoUrl   =   [NSURL fileURLWithPath:[[NSBundle mainBundle]   pathForResource:@"IMG_1158" ofType:@"MOV"]];
    //    [self   compression];
    
    //    NSURL   *audioUrl   =   [NSURL fileURLWithPath:[[NSBundle mainBundle]   pathForResource:@"lijianlive" ofType:@"m4a"]];
    //    [self   musicCompression:audioUrl];
    [self recordSession];
}

- (IBAction)recordAction:(UIButton *)sender {
    [recorder stop];
    [self musicCompression:[NSURL fileURLWithPath:path]];
}

#pragma mark 录音成wav和m4a测试
-   (void)recordSession
{
    //设置录音路径
    path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]
            stringByAppendingPathComponent:@"musicxx.caf"];
    AVAudioSession  *audioSession   =   [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryRecord error:nil];
    NSError *error  =   nil;
    recorder   =   [[AVAudioRecorder alloc]initWithURL:[NSURL fileURLWithPath:path] settings:[self audioRecordingSttings] error:&error];
    recorder.meteringEnabled    =   YES;
    if ([recorder prepareToRecord]) {
        recorder.meteringEnabled    =   YES;
        [recorder record];
    }
}


-   (NSDictionary *)audioRecordingSttings
{
    NSDictionary    *result =   nil;
    NSMutableDictionary *recordSetting  =   [[NSMutableDictionary alloc]init];
    //设置录音格式
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
    //设置录音采样率
    [recordSetting setValue:[NSNumber numberWithInt:8000] forKey:AVSampleRateKey];
    //设置录音通道数
    [recordSetting setValue:[NSNumber numberWithInt:1] forKey:AVNumberOfChannelsKey];
    //设置线性采样位数
    [recordSetting setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    //设置录音质量
    [recordSetting setValue:[NSNumber numberWithInt:AVAudioQualityHigh] forKey:AVEncoderAudioQualityKey];
    
    result  =   [NSDictionary dictionaryWithDictionary:recordSetting];
    return result;
}




#pragma mark 音频文件压缩

-   (void)musicCompression:(NSURL*)audioUrl
{
    NSLog(@"压缩前大小 %ldMB",(long)[self getFileSize:[audioUrl path]]);
    NSData  *pcmData    =   [NSData dataWithContentsOfURL:audioUrl];
    
    NSData   *amrData    =   EncodeWAVEToAMR(pcmData, 1, 16);
    NSString* amrpath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]
                         stringByAppendingPathComponent:@"music.amr"];
    BOOL isfinish   =   [amrData writeToFile:amrpath atomically:YES];
    if (isfinish) {
        NSLog(@"压缩后大小 %ldMB",(long)[self getFileSize:amrpath]);
    }
    
}


#pragma mark 视频文件压缩
- (void)compression{
    NSLog(@"压缩前大小 %ldMB",(long)[self getFileSize:[_videoUrl path]]);
    // 创建AVAsset对象
    AVAsset* asset = [AVAsset assetWithURL:_videoUrl];
    /*
     创建AVAssetExportSession对象
     压缩的质量
     AVAssetExportPresetLowQuality 最low的画质最好不要选择实在是看不清楚
     AVAssetExportPresetMediumQuality 使用到压缩的话都说用这个
     AVAssetExportPresetHighestQuality 最清晰的画质
     */
    AVAssetExportSession * session = [[AVAssetExportSession alloc]
                                      initWithAsset:asset presetName:AVAssetExportPresetMediumQuality];
    //优化网络
    session.shouldOptimizeForNetworkUse = YES;
    //转换后的格式
    //拼接输出文件路径 为了防止同名 可以根据日期拼接名字 或者对名字进行MD5加密
    NSString* path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]
                      stringByAppendingPathComponent:@"hello.mp4"];
    //判断文件是否存在，如果已经存在删除
    [[NSFileManager defaultManager]removeItemAtPath:path error:nil];
    //设置输出路径
    session.outputURL = [NSURL fileURLWithPath:path];
    //设置输出类型 这里可以更改输出的类型 具体可以看文档描述
    session.outputFileType = AVFileTypeMPEG4;
    [session exportAsynchronouslyWithCompletionHandler:^{
        NSLog(@"%@",[NSThread currentThread]);
        //压缩完成
        if(session.status==AVAssetExportSessionStatusCompleted) {
            //在主线程中刷新UI界面，弹出控制器通知用户压缩完成 dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"导出完成");
            //            CompressURL = session.outputURL;
            NSLog(@"压缩后大小 %ldMB",(long)[self getFileSize:[session.outputURL path]]);
        }
    }];
}


/// 初始化 捕捉输入
- (BOOL)setupSessionInputs:(NSError **)error {
    
    // 添加 摄像头
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:({
        
        [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
    }) error:error];
    
    if (!videoInput) { return NO; }
    
    if ([self.captureSession canAddInput:videoInput]) {
        [self.captureSession addInput:videoInput];
    }else{
        return NO;
    }
    
    // 添加 话筒
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:({
        
        [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        
    }) error:error];
    
    if (!audioInput)  { return NO; }
    
    if ([self.captureSession canAddInput:audioInput]) {
        [self.captureSession addInput:audioInput];
    }else{
        return NO;
    }
    
    return YES;
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    if (![self.captureMovieFileOutput isRecording]) {
        AVCaptureConnection *captureConnection=[self.captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        captureConnection.videoOrientation=[self.captureVideoPreviewLayer connection].videoOrientation;
        [self.captureMovieFileOutput startRecordingToOutputFileURL:({
            // 录制 缓存地址。
            NSURL *url = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"temp.mov"]];
            if ([[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
                [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
            }
            url;
        }) recordingDelegate:self];
    }else{
        [self.captureMovieFileOutput stopRecording];//停止录制
        
        
    }
}
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error{
    [self videoCompression];
}


-(void)videoCompression{
    NSLog(@"begin");
    NSURL *tempurl = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"temp.mov"]];
    //加载视频资源
    AVAsset *asset = [AVAsset assetWithURL:tempurl];
    //创建视频资源导出会话
    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetMediumQuality];
    //创建导出视频的URL
    session.outputURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"tempLow.mov"]];
    //必须配置输出属性
    session.outputFileType = @"com.apple.quicktime-movie";
    //导出视频
    [session exportAsynchronouslyWithCompletionHandler:^{
        NSLog(@"end");
        NSInteger      fileSize    =   [self getFileSize:[session.outputURL path]];
        NSLog(@"fileSize=======%d",fileSize);
    }];
}


-   (NSInteger)getFileSize:(NSString*) path
{
    NSFileManager *filemanager = [[NSFileManager alloc]init];
    if([filemanager fileExistsAtPath:path])
    {
        NSDictionary *attributes = [filemanager attributesOfItemAtPath:path error:nil];
        NSNumber *theFileSize;
        if ( (theFileSize = [attributes objectForKey:NSFileSize]) )
            return [theFileSize intValue];
        else return -1;
    }
    else {
        return -1;
    }
}
@end
