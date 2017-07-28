//
//  Recorder.h
//  AudioQueue
//
//  Created by Charles Wang on 16/5/8.
//  Copyright © 2016年 CHW. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <AudioToolbox/AudioQueue.h>

static const int kNumberBuffers = 3;    //设置使用音频队列缓冲区的数目

@interface Recorder : NSObject

typedef struct AQRecorderState {
    AudioStreamBasicDescription mDataFormat;    //指定音频队列mQueue字段
    AudioQueueRef mQueue;   //由你的应用在录制音频时被创建
    AudioQueueBufferRef mBuffers[kNumberBuffers];   //音频队列管理的音频队列缓冲区的指针
    AudioFileID mAudioFile; //音频文件对象
    UInt32 bufferByteSize;  //每个音频缓冲区的大小
    SInt64 mCurrentPacket;  //音频缓冲区的下标
    bool mIsRuning; //  音频队列是否在运行
}AQRecorderState;

@property (nonatomic, assign) AQRecorderState recorderState;

@end
