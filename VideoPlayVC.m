//
//  VideoPlayVC.m
//  Contingency
//
//  Created by mm on 2017/1/9.
//  Copyright © 2017年 mm. All rights reserved.
//

#import "VideoPlayVC.h"
#import "VideoModel.h"
#import <SocketRocket/SRWebSocket.h>
#import "MM_SQLite_DB.h"
#import "DDH264Decoder.h"

@interface VideoPlayVC ()<SRWebSocketDelegate>
@property(nonatomic,strong) SRWebSocket *websocket;
@property(nonatomic,strong) DDH264Decoder *MMDecoder;
@property(nonatomic,strong) UIImageView *imageview;
@end

@implementation VideoPlayVC



- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.MMtitle = @"监控";
    
    
    [self.view addSubview:self.imageview];
    
    AVCodec *codec = avcodec_find_decoder(AV_CODEC_ID_H264);
    AVCodecContext *codecCtx = avcodec_alloc_context3(codec);
    avcodec_open2(codecCtx, codec, nil);
    
    self.view.transform = CGAffineTransformMakeRotation (M_PI_2);
    
    self.websocket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"写自己的视频流地址"]]];//视频流地址 例如 ws://xxx.xxx.xxx.xx:xxx/h264
    self.websocket.delegate = self;
    
    [self.websocket open];
    MMLog(@"%@",_videomodel.name);
    
    /**
     在AVCodecContext中会保存很多解码需要的信息，比如视频的长和宽，但是现在我们还不知道。
     
     这些信息存储在h264流的SPS（序列参数集）和PPS（图像参数集）中。
     
     对于每个nal unit，起始码后面第一个字节的后5位，代表这个nal unit的类型。7代表SPS，8代表PPS。一般在SPS和PPS后面的是IDR帧，无需前面帧的信息就可以解码，用5来代表
     */

    
    
//    UILabel *lbl = [[UILabel alloc] init];
//    lbl.frame = CGRectMake(self.view.centerX-50, self.view.centerY - 100, 100, 40);
//    lbl.text = @"敬请期待";
//    [self.view addSubview:lbl];
    
    UIBarButtonItem *barbtn = [UIBarButtonItem itemWithTarget:self action:@selector(back) Image:@"back_icon" title:@"返回"];
    self.navigationItem.leftBarButtonItem = barbtn;
}

#pragma mark - SRWebSocket delegate
- (void)webSocketDidOpen:(SRWebSocket *)webSocket;{
    NSLog(@"Websocket Connected");
    NSLog(@"已经连接上");
    NSError *error;
    
    UserInfo *user = [MM_SQLite_DB UserInfo_Selecte][0];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:@{@"id":_videomodel.code,
                                                                 @"is_sub":@false,
                                                                 @"user":user.name,
                                                                 @"passw":user.password}
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    
    NSString *jsonString = [[NSString alloc] initWithData:jsonData
                                                 encoding:NSUTF8StringEncoding];
    [webSocket send:jsonString];
}


- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error;{
    NSLog(@":( Websocket Failed With Error %@", error);
    webSocket = nil;
}


- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message;{
    NSData *data = [NSData dataWithBytes:(__bridge const void * _Nullable)(message) length:[message length]];
    NSMutableData *h264Data = [[NSMutableData alloc] init];
    [h264Data appendData:data];
    
    //去解码
    [self.MMDecoder H264decoderWithVideoData:h264Data completion:^(UIImage *picture) {
        NSLog(@"得到要显示的东西");
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.imageview.image = picture;
        });
    }];
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;{
    
    NSLog(@"WebSocket closed");
    
    webSocket = nil;
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

//返回按钮
-(void)back{
    if (self.navigationController.viewControllers.count == 1) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }else{
        [self.navigationController popViewControllerAnimated:YES];
    }
}

-(DDH264Decoder *)MMDecoder{
    if (_MMDecoder == nil) {
        _MMDecoder = [[DDH264Decoder alloc] init];
        [self.MMDecoder initH264DecoderWithWidth:self.view.frame.size.width height:self.view.frame.size.height];
    }
    return _MMDecoder;
}



-(UIImageView *)imageview{
    if (_imageview == nil) {
        _imageview = [[UIImageView alloc] init];
        _imageview.frame = CGRectMake(0, 0, self.view.frame.size.height, self.view.frame.size.width);
        _imageview.backgroundColor = [UIColor blackColor];
//        _imageview.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _imageview;
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.navigationController setNavigationBarHidden:!self.navigationController.navigationBarHidden animated:YES];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
   
}

@end
