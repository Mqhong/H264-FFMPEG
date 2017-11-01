//
//  DDH264Decoder.m
//  LiveVedioPlayer
//
//  Created by mm on 2017/1/11.
//  Copyright © 2017年 mm. All rights reserved.
//

#import "DDH264Decoder.h"

#import "swscale.h"
#import "avformat.h"
#import <AVFoundation/AVFoundation.h>


@interface DDH264Decoder()

@property (assign,nonatomic) AVFrame *frame;
@property (assign,nonatomic) AVCodec *codec;
@property (assign,nonatomic) AVCodecContext *codecCtx;
@property (assign,nonatomic) AVPacket packet;
@property (assign,nonatomic) AVFormatContext *formatCtx;

@end

@implementation DDH264Decoder



/**
 初始化视频解码器

 @param width 宽度
 @param height 高度
 @return YES:解码成功
 */
-(BOOL)initH264DecoderWithWidth:(int)width height:(int)height{
    /*注册所有的编码器，解析器，码流过滤器，只需要初始化一次*/
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        avcodec_register_all();
        av_register_all();
        avformat_network_init();
    });
    /*查找指定格式的解析器，这里我们使用h264的解析器*/
    avformat_network_init();
    self.codec = avcodec_find_decoder(AV_CODEC_ID_H264);
    av_init_packet(&_packet);
    if (self.codec != nil) {
        self.codecCtx = avcodec_alloc_context3(self.codec);
        //每个包一个视频帧
        self.codecCtx->frame_number = 1;
        self.codecCtx->codec_type = AVMEDIA_TYPE_VIDEO;
        
        //视频的宽度和高度
        self.codecCtx->width = width;
        self.codecCtx->height = height;
        
        //打开codec 打开指定解析器
        int ret = avcodec_open2(self.codecCtx, self.codec, NULL);
        if ( ret >= 0) {
            self.frame = av_frame_alloc();
            if (self.frame == NULL) {
                NSLog(@"av_frame_alloc failed");
                return NO;
            }else{
                NSLog(@"av_frame_alloc success");
            }
        }else{
            NSLog(@"open codec error :%d",ret);
        }
    }
    return (BOOL)self.frame;
}

/**
 视频解码

 @param VideoData 被解码视频数据
 @param completion 图片
 */
-(void)H264decoderWithVideoData:(NSData *)VideoData completion:(void (^)(UIImage *picture)) completion{
    @autoreleasepool {
        _packet.data = (uint8_t *)VideoData.bytes;
        _packet.size = (int)VideoData.length ;
 
        av_log_set_level(AV_LOG_QUIET);
        
        int getPicture;
        avcodec_send_packet(_codecCtx, &_packet);
        getPicture = avcodec_receive_frame(self.codecCtx, self.frame);

        av_packet_unref(&_packet);
        
//        if (getPicture == 0) {
        AVPicture picture;
        avpicture_alloc(&picture, AV_PIX_FMT_RGB24, self.codecCtx->width, self.codecCtx->height);
        
        struct SwsContext *img_convert_ctx = sws_getContext(self.codecCtx->width,
                                                            self.codecCtx->height,
                                                            AV_PIX_FMT_YUV420P,
                                                            self.codecCtx->width,
                                                            self.codecCtx->height,
                                                            AV_PIX_FMT_RGB24,
                                                            SWS_FAST_BILINEAR,
                                                            NULL,
                                                            NULL,
                                                            NULL);
        //图像处理
        sws_scale(img_convert_ctx,
                  (const uint8_t* const*)self.frame->data,
                  self.frame->linesize,
                  0,
                  self.codecCtx->height,
                  picture.data,
                  picture.linesize);
        sws_freeContext(img_convert_ctx);
        img_convert_ctx = NULL;
        
        
        
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
        CFDataRef data = CFDataCreate(kCFAllocatorDefault,
                                      picture.data[0],
                                      picture.linesize[0] * self.codecCtx->height);
        
        CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGImageRef cgImage = CGImageCreate(self.codecCtx->width,
                                           self.codecCtx->height,
                                           8,
                                           24,
                                           picture.linesize[0],
                                           colorSpace,
                                           bitmapInfo,
                                           provider,
                                           NULL,
                                           NO,
                                           kCGRenderingIntentDefault);
        UIImage *image = [UIImage imageWithCGImage:cgImage];

        if (completion) {
            NSLog(@"传送picture");
            completion(image);
        }
        
        avpicture_free(&picture);
        CGImageRelease(cgImage);
        CGColorSpaceRelease(colorSpace);
        CGDataProviderRelease(provider);
        CFRelease(data);
//        }
    }
}


-(void)releaseH264Decoder{
    if (self.codecCtx) {
        avcodec_close(self.codecCtx);
        avcodec_free_context(&_codecCtx);
        self.codecCtx = NULL;
    }
    
    if (self.frame) {
        av_frame_free(&_frame);
        self.frame = NULL;
    }
    av_packet_unref(&_packet);
    
}


@end
