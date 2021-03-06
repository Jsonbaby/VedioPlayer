//
//  MusicPlayerView.m
//  VedioPlayer
//
//  Created by yanghuang on 2017/5/27.
//  Copyright © 2017年 com.yang. All rights reserved.
//

#import "MusicPlayerView.h"
#import <Masonry/Masonry.h>

@interface MusicPlayerView ()<MusicSliderDelegate>

@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, strong) AVPlayerItem *playerItem;

@property (nonatomic, strong) MusicSlider *timeSlider;

//@property (nonatomic, strong) UILabel *timeNowLabel;

/**  播放说明  */
@property (nonatomic, strong) UILabel *musicTitle;


@property (nonatomic, strong) UILabel *timeTotalLabel;

@property (nonatomic, strong) UIButton *playButton;


/*
 * 是否处于seek阶段/seek中间会存在一个不同步问题
 * 所以在seek中间不处理 addPeriodicTimeObserverForInterval
 */
@property (nonatomic, assign) BOOL isSeeking;
//是否拖拽中
@property (nonatomic, assign) BOOL isDragging;
//播放状态
@property (nonatomic, assign) VedioStatus playerStatus;
//总播放时长
@property (nonatomic, assign) CGFloat totalTime;
//文件模型
@property (nonatomic, strong) VedioModel *musicModel;

@property (nonatomic, strong) id timeObserver;
@end


@implementation MusicPlayerView

#pragma mark 初始化组件\初始化playerListener

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.frame = CGRectMake(0, 0, SCREEN_WIDTH, 40);
        [self initUI];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initUI];
    }
    return self;
}

- (void)initUI {
    
    self.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.8];
    self.playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.playButton setImage:[UIImage imageNamed:@"ico_play"] forState:UIControlStateNormal];
    
    [self.playButton addTarget:self action:@selector(playButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.playButton];
    
    __weak typeof(self) weakself = self;
    [self.playButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(weakself).offset(8);
        make.centerY.equalTo(weakself).offset(3);
        make.width.mas_equalTo(40);
        make.height.mas_equalTo(40);
    }];
    
//    self.timeNowLabel = [[UILabel alloc]init];
//    self.timeNowLabel.textColor = [UIColor whiteColor];
//    self.timeNowLabel.font = [UIFont systemFontOfSize:13];
//    self.timeNowLabel.text = @"00:00";
//    
//    [self addSubview:self.timeNowLabel];
//    
//    [self.timeNowLabel mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.leading.equalTo(weakself.playButton.mas_trailing).offset(5);
//        make.centerY.equalTo(weakself);
//        make.height.mas_equalTo(15);
//        make.width.mas_equalTo(37);
//    }];
    self.musicTitle = [[UILabel alloc] init];
    self.musicTitle.textColor = [UIColor whiteColor];
    self.musicTitle.font = [UIFont systemFontOfSize:12];
    self.musicTitle.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.musicTitle];
    
    [self.musicTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakself).offset(10);
        make.left.equalTo(weakself).offset(60);
        make.right.equalTo(weakself).offset(-60);
        make.height.mas_equalTo(15);
        
    }];
    

    
    self.timeSlider = [[MusicSlider alloc] initWithFrame:CGRectMake(55, 6, weakself.frame.size.width - 108, self.frame.size.height-6)];
    [self addSubview:self.timeSlider];
    
    
    
    
    self.timeTotalLabel = [[UILabel alloc]init];
    self.timeTotalLabel.textColor = [UIColor whiteColor];
    self.timeTotalLabel.font = [UIFont systemFontOfSize:13];
    self.timeTotalLabel.text = @"00:00";
    [self addSubview:self.timeTotalLabel];
    [self.timeTotalLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(weakself).offset(-13);
        make.centerY.equalTo(weakself).offset(3);
        make.height.mas_equalTo(15);
        make.width.mas_equalTo(37);
    }];
    
    self.timeSlider.delegate = self;
    self.timeSlider.trackBackgoundColor = [UIColor whiteColor];
    self.timeSlider.playProgressBackgoundColor = [UIColor orangeColor];
    [self.playButton setImage:[UIImage imageNamed:@"ico_play"] forState:UIControlStateNormal];
    self.playerStatus = VedioStatusPause;
}

- (void)setUp:(VedioModel *)model {
    self.musicModel = model;
    self.musicTitle.text = model.MusicTitle;
}


#pragma mark 初始化播放文件，只允许在播放按钮事件使用
- (void)initMusic {
    self.player = [[AVPlayer alloc]init];
    [self initPlayerItem];
    [self addPlayerListener];
}

//修改playerItem
- (void)initPlayerItem {
    if (self.musicModel && ![self.musicModel.musicURL isEqualToString:@""]) {
        
        self.playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:self.musicModel.musicURL]];
        [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
    }
}

//添加监听文件,所有的监听
- (void)addPlayerListener {
    
    //自定义播放状态监听
    [self addObserver:self forKeyPath:@"playerStatus" options:NSKeyValueObservingOptionNew context:nil];
    if (self.player) {
        //播放速度监听
        [self.player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:nil];
    }
    
    if (self.playerItem) {
        //播放状态监听
        [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        //缓冲进度监听
        [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
        
        //播放中监听，更新播放进度
        __weak typeof(self) weakSelf = self;
        self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 30) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            float currentPlayTime = (double)weakSelf.playerItem.currentTime.value/weakSelf.playerItem.currentTime.timescale;
            if (weakSelf.playerItem.currentTime.value<0) {
                currentPlayTime = 0.1; //防止出现时间计算越界问题
            }
            //拖拽期间不更新数据
            if (!weakSelf.isDragging) {
                weakSelf.timeSlider.value = currentPlayTime;
                //weakSelf.timeNowLabel.text = [VedioPlayerConfig convertTime:currentPlayTime];
            }
        }];
        
    }
    
    //给AVPlayerItem添加播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    //监听应用后台切换
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appEnteredBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    //播放中被打断
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInterruption:) name:AVAudioSessionInterruptionNotification object:[AVAudioSession sharedInstance]];
    //拔掉耳机监听？？
}

//销毁player,无奈之举 因为avplayeritem的制空后依然缓存的问题。
- (void)destroyPlayer {
    
    [self.playerItem removeObserver:self forKeyPath:@"status"];
    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.player removeObserver:self forKeyPath:@"rate"];
    [self.player removeTimeObserver:self.timeObserver];
    
    self.playerItem = nil;
    self.player = nil;
    
    self.playerStatus = VedioStatusPause;
    self.timeSlider.value = 0;
    //self.timeNowLabel.text = @"00:00";
}

- (void)changeMusic:(VedioModel *)musicModel {
    if (musicModel && ![musicModel.musicURL isEqualToString:@""]) {
        if (self.playerItem && self.player) {
            [self destroyPlayer];
            self.musicModel = musicModel;
            self.musicTitle.text = musicModel.MusicTitle;
        }
    } else {
        [self pause];
    }
}

- (void)changAndPlayMusic:(VedioModel *)musicModel {
    if (musicModel && ![musicModel.musicURL isEqualToString:@""]) {
        
            [self destroyPlayer];
            self.musicModel = musicModel;
            self.musicTitle.text = musicModel.MusicTitle;
            
            [self initMusic];
            [self play];
    
    } else {
        [self pause];
    }

}


#pragma mark 播放，暂停
- (void)play{
    if (self.player && self.playerStatus == VedioStatusPause) {
        NSLog(@"通过播放停止");
        self.playerStatus = VedioStatusBuffering;
        [self.player play];
    }
}

- (void)pause{
    if (self.player && self.playerStatus != VedioStatusPause) {
        NSLog(@"通过暂停停止");
        self.playerStatus = VedioStatusPause;
        [self.player pause];
    }
}

#pragma mark 监听播放完成事件
-(void)playerFinished:(NSNotification *)notification{
    NSLog(@"播放完成");
    [self.playerItem seekToTime:kCMTimeZero];
    [self pause];
}

#pragma mark 播放失败
-(void)playerFailed{
    NSLog(@"播放失败");
    [self destroyPlayer];
}

#pragma mark 播放被打断
- (void)handleInterruption:(NSNotification *)notification {
    [self pause];
}

#pragma mark 进入后台，暂停音频
- (void)appEnteredBackground {
    [self pause];
}

#pragma mark 监听捕获
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItem *item = (AVPlayerItem *)object;
        if ([self.playerItem status] == AVPlayerStatusReadyToPlay) {
            //获取音频总长度
            CMTime duration = item.duration;
            [self setMaxDuratuin:CMTimeGetSeconds(duration)];
            NSLog(@"AVPlayerStatusReadyToPlay -- 音频时长%f",CMTimeGetSeconds(duration));
            
        }else if([self.playerItem status] == AVPlayerStatusFailed) {
            
            [self playerFailed];
            NSLog(@"AVPlayerStatusFailed -- 播放异常");
            
        }else if([self.playerItem status] == AVPlayerStatusUnknown) {
            
            [self pause];
            NSLog(@"AVPlayerStatusUnknown -- 未知原因停止");
        }
    } else if([keyPath isEqualToString:@"loadedTimeRanges"]) {
        AVPlayerItem *item = (AVPlayerItem *)object;
        NSArray * array = item.loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue]; //本次缓冲的时间范围
        NSTimeInterval totalBuffer = CMTimeGetSeconds(timeRange.start) + CMTimeGetSeconds(timeRange.duration); //缓冲总长度
        self.timeSlider.trackValue = totalBuffer;
        //当缓存到位后开启播放，取消loading
        if (totalBuffer >self.timeSlider.value && self.playerStatus != VedioStatusPause) {
            [self.player play];
        }
        NSLog(@"---共缓冲---%.2f",totalBuffer);
    } else if ([keyPath isEqualToString:@"rate"]){
        AVPlayer *item = (AVPlayer *)object;
        if (item.rate == 0) {
            if (self.playerStatus != VedioStatusPause) {
                self.playerStatus = VedioStatusBuffering;
            }
        } else {
            self.playerStatus = VedioStatusPlaying;
            
        }
        NSLog(@"---播放速度---%f",item.rate);
    } else if([keyPath isEqualToString:@"playerStatus"]){
        switch (self.playerStatus) {
            case VedioStatusBuffering:
                [self.timeSlider.sliderBtn showActivity:YES];
                break;
            case VedioStatusPause:
                [self.playButton setImage:[UIImage imageNamed:@"ico_play"] forState:UIControlStateNormal];
                [self.timeSlider.sliderBtn showActivity:NO];
                break;
            case VedioStatusPlaying:
                [self.playButton setImage:[UIImage imageNamed:@"ico_stop"] forState:UIControlStateNormal];
                [self.timeSlider.sliderBtn showActivity:NO];
                break;
                
            default:
                break;
        }
    }
}

#pragma mark 监听拖拽事件,拖拽中、拖拽开始、拖拽结束

// 开始拖动
- (void)beiginSliderScrubbing {
    self.isDragging = YES;
}

// 拖动值发生改变
- (void)sliderScrubbing {
    if (self.totalTime != 0) {
        //self.timeNowLabel.text = [VedioPlayerConfig convertTime:self.timeSlider.value];
    }
}

// 结束拖动
- (void)endSliderScrubbing {
    self.isDragging = NO;
    CMTime time = CMTimeMake(self.timeSlider.value, 1);
    //self.timeNowLabel.text = [VedioPlayerConfig convertTime:self.timeSlider.value];
    if (self.playerStatus != VedioStatusPause) {
        [self.player pause];
        [self.playerItem seekToTime:time completionHandler:^(BOOL finished) {
            [self.player play];
            self.playerStatus = VedioStatusBuffering; //结束拖动后处于一个缓冲状态?如果直接拖到结束呢？
        }];
    }
}

#pragma mark 播放按钮事件
- (void)playButtonAction:(id)sender {
    if (self.player) {
        if (self.playerStatus == VedioStatusPause) {
            [self play];
        } else {
            [self pause];
        }
    } else {
        [self initMusic];
        [self play];
    }
}

#pragma mark 设置时间轴最大时间
- (void)setMaxDuratuin:(float)duration{
    _totalTime = duration;
    self.timeSlider.maximumValue = duration;
    self.timeTotalLabel.text = [VedioPlayerConfig convertTime:duration];
}

- (void)dealloc
{
    [self destroyPlayer];
    [self removeObserver:self forKeyPath:@"playerStatus"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
