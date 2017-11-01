//
//  DDH264Decoder.h
//  LiveVedioPlayer
//
//  Created by mm on 2017/1/11.
//  Copyright © 2017年 mm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "avcodec.h"

@interface DDH264Decoder : NSObject

/* 初始化编码器 */
-(BOOL)initH264DecoderWithWidth:(int)width height:(int)height;

/*解码视频数据并返回图片*/
-(void)H264decoderWithVideoData:(NSData *)VideoData completion:(void (^)(UIImage *picture)) completion;


/* 释放解码器 */
-(void)releaseH264Decoder;
@end
