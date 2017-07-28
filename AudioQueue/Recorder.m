//
//  Recorder.m
//  AudioQueue
//
//  Created by Charles Wang on 16/5/8.
//  Copyright © 2016年 CHW. All rights reserved.
//

#import "Recorder.h"
#import <CoreFoundation/CFURL.h>

@interface Recorder()

@property (nonatomic,assign) AQRecorderState pAqData;

//录制音频队列回调声明
static void HandleInputBuffer (
                               void *aqData,
                               AudioQueueRef inAQ,
                               AudioQueueBufferRef inBuffer,
                               const AudioTimeStamp *inStartTime,
                               UInt32 inNumPackets,
                               const AudioStreamPacketDescription *inPacketDesc
                               );
//写入一个音频缓冲区到磁盘
OSStatus AudioFileWritePackets(
                      pAqData-> mAudioFile,
                      false,
                      inBuffer-> mAudioDataByteSize,
                      inPacketDesc,
                      pAqData-> mCurrentPacket,
                      &inNumPackets,
                      inBuffer->mAudioData
                      
);

OSStatus AudioQueueEnqueueBuffer (                    // 1
                         pAqData->mQueue,                         // 2
                         inBuffer,                                // 3
                         0,                                       // 4
                         NULL                                     // 5
);


@end

@implementation Recorder

static void HandleInputBuffer (
                               void *aqData,
                               AudioQueueRef inAQ,  //音频队列的回调
                               AudioQueueBufferRef inBuffer, //录制的音频数据的音频队列缓冲区
                               const AudioTimeStamp *inStartTime,//在音频缓冲队列中的第一个样本的采样时间
                               UInt32 inNumPackets,//The number of packet descriptions in the inPacketDesc parameter.0表示CBR数据
                               const AudioStreamPacketDescription *inPacketDesc //
                               )
{
    _pAqData = ( AQRecorderState *)aqData;
    if (inNumPackets == 0 && pAqData->mDataFormat.mBytesPerPacket != 0)
    {
        inNumPackets = inBuffer->mAudioDataByteSize / pAqData->mDataFormat.mBytesPerPacket;
    }
    if (AudioFileWritePackets(
                              pAqData->mAudioFile,
                              false,
                              inBuffer-> mAudioDataByteSize,
                              inPacketDesc,
                              pAqData-> mCurrentPacket,
                              &inNumPackets,
                              inBuffer->mAudioData
                              
                              ) == noErr
        )
    {
        pAqData->mCurrentPacket += inNumPackets;
    }
    
    if (pAqData->mIsRuning == 0) {
        return;
    }
    
    AudioQueueEnqueueBuffer(
                            pAqData->mQueue,
                            inBuffer,
                            0,
                            NULL
                            );
}

void DeriveBufferSize (
                       AudioQueueRef                audioQueue,                  // 1
                       AudioStreamBasicDescription  &ASBDescription,             // 2
                       Float64                      seconds,                     // 3
                       UInt32                       *outBufferSize               // 4
) {
    static const int maxBufferSize = 0x50000;                 // 5
    
    int maxPacketSize = ASBDescription.mBytesPerPacket;       // 6
    if (maxPacketSize == 0) {                                 // 7
        UInt32 maxVBRPacketSize = sizeof(maxPacketSize);
        AudioQueueGetProperty (
                               audioQueue,
                               kAudioQueueProperty_MaximumOutputPacketSize,
                               // in Mac OS X v10.5, instead use
                               //   kAudioConverterPropertyMaximumOutputPacketSize
                               &maxPacketSize,
                               &maxVBRPacketSize
                               );
    }
    
    Float64 numBytesForTime =
    ASBDescription.mSampleRate * maxPacketSize * seconds; // 8
    *outBufferSize =
    UInt32 (numBytesForTime < maxBufferSize ?
            numBytesForTime : maxBufferSize);                     // 9
}

OSStatus SetMagicCookieForFile (
                                AudioQueueRef inQueue,                                      // 1
                                AudioFileID   inFile                                        // 2
) {
    OSStatus result = noErr;                                    // 3
    UInt32 cookieSize;                                          // 4
    
    if (
        AudioQueueGetPropertySize (                         // 5
                                   inQueue,
                                   kAudioQueueProperty_MagicCookie,
                                   &cookieSize
                                   ) == noErr
        ) {
        char* magicCookie =
        (char *) malloc (cookieSize);                       // 6
        if (
            AudioQueueGetProperty (                         // 7
                                   inQueue,
                                   kAudioQueueProperty_MagicCookie,
                                   magicCookie,
                                   &cookieSize
                                   ) == noErr
            )
            result =    AudioFileSetProperty (                  // 8
                                              inFile,
                                              kAudioFilePropertyMagicCookieData,
                                              cookieSize,
                                              magicCookie
                                              );
        free (magicCookie);                                     // 9
    }
    return result;                                              // 10
}

- (void)setDataFormat
{
    struct AQRecorderState aqData;                                       // 1
    
    aqData.mDataFormat.mFormatID         = kAudioFormatLinearPCM; // 2
    aqData.mDataFormat.mSampleRate       = 44100.0;               // 3
    aqData.mDataFormat.mChannelsPerFrame = 2;                     // 4
    aqData.mDataFormat.mBitsPerChannel   = 16;                    // 5
    aqData.mDataFormat.mBytesPerPacket   =                        // 6
    aqData.mDataFormat.mBytesPerFrame =
    aqData.mDataFormat.mChannelsPerFrame * sizeof (SInt16);
    aqData.mDataFormat.mFramesPerPacket  = 1;                     // 7
    
    AudioFileTypeID fileType             = kAudioFileAIFFType;    // 8
    aqData.mDataFormat.mFormatFlags =                             // 9
    kLinearPCMFormatFlagIsBigEndian
    | kLinearPCMFormatFlagIsSignedInteger
    | kLinearPCMFormatFlagIsPacked;
}

//创建一个录制音频的队列
OSStatus AudioQueueNewInput (                              // 1
                    &aqData.mDataFormat,                          // 2
                    HandleInputBuffer,                            // 3
                    &aqData,                                      // 4
                    NULL,                                         // 5
                    kCFRunLoopCommonModes,                        // 6
                    0,                                            // 7
                    &aqData.mQueue                                // 8
);

//从音频队列中获取完整的音频格式
UInt32 dataFormatSize = sizeof (aqData.mDataFormat);       // 1

OSStatus AudioQueueGetProperty (                                    // 2
                       aqData.mQueue,                                         // 3
                       kAudioQueueProperty_StreamDescription,                 // 4
                       // in Mac OS X, instead use
                       //    kAudioConverterCurrentInputStreamDescription
                       &aqData.mDataFormat,                                   // 5
                       &dataFormatSize                                        // 6
);

// 创建用于记录的音频文件
CFURLRef audioFileURL =
CFURLCreateFromFileSystemRepresentation (            // 1
                                         NULL,                                            // 2
                                         (const UInt8 *) filePath,                        // 3
                                         strlen (filePath),                               // 4
                                         false                                            // 5
                                         );

AudioFileCreateWithURL (                                 // 6
                        audioFileURL,                                        // 7
                        fileType,                                            // 8
                        &aqData.mDataFormat,                                 // 9
                        kAudioFileFlags_EraseFile,                           // 10
                        &aqData.mAudioFile                                   // 11
);

//设置音频队列缓冲区
DeriveBufferSize (                               // 1
                  aqData.mQueue,                               // 2
                  aqData.mDataFormat,                          // 3
                  0.5,                                         // 4
                  &aqData.bufferByteSize                       // 5
);

//准备一组音频队列缓冲区
for (int i = 0; i < kNumberBuffers; ++i) {           // 1
    AudioQueueAllocateBuffer (                       // 2
                              aqData.mQueue,                               // 3
                              aqData.bufferByteSize,                       // 4
                              &aqData.mBuffers[i]                          // 5
                              );
    
    AudioQueueEnqueueBuffer (                        // 6
                             aqData.mQueue,                               // 7
                             aqData.mBuffers[i],                          // 8
                             0,                                           // 9
                             NULL                                         // 10
                             );
}

//Record Audio
aqData.mCurrentPacket = 0;                           // 1
aqData.mIsRunning = true;                            // 2

OSStatus AudioQueueStart (                                    // 3
                 aqData.mQueue,                                   // 4
                 NULL                                             // 5
);
// Wait, on user interface thread, until user stops the recording
OSStatus AudioQueueStop (                                     // 6
                aqData.mQueue,                                   // 7
                true                                             // 8
);

aqData.mIsRunning = false;                           // 9

//录音结束 清空
OSStatus AudioQueueDispose (                                 // 1
                   aqData.mQueue,                                  // 2
                   true                                            // 3
);

OSStatus AudioFileClose (aqData.mAudioFile);
@end
