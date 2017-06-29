//
//  ViewController.m
//  VedioPlayer
//
//  Created by yanghuang on 2017/4/24.
//  Copyright © 2017年 com.yang. All rights reserved.
//

#import "ViewController.h"
#import "MusicPlayerView.h"

@interface ViewController ()<VedioPlayerViewDelegate>
@property (nonatomic, strong) MusicPlayerView *playerView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
    UIButton *changeMusic = [[UIButton alloc] initWithFrame:CGRectMake(100,150, 60, 40)];
    changeMusic.backgroundColor = [UIColor blueColor];
    [changeMusic addTarget:self  action:@selector(change) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:changeMusic];

    VedioModel *model = [[VedioModel alloc]init];
    model.musicURL = @"http://resource.zjcitybao.com/advert/%E7%BE%BD%E8%82%BF%20-%20Sleepless%C2%A0Starlight.mp3";
    model.MusicTitle = @"郁葱-www.hao123.com/ccs/ss";
    self.playerView = [[MusicPlayerView alloc]initWithFrame:CGRectMake(0, 200, 320, 73)];
    self.playerView.delegate = self;
    [self.playerView setUp:model];
    [self.view addSubview:self.playerView];
    
    
}


- (void)change {
    VedioModel *model = [[VedioModel alloc]init];
    model.musicURL = @"http://resource.zjcitybao.com/advert/044a5b16adb39ccc01a7088fe71ba60e.m4a";
    model.MusicTitle = @"keke-www.hao123.com/ccs/ss";

    [self.playerView changeMusic:model];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//播放失败的代理方法
-(void)playerViewFailed:(VedioPlayerView *)player {
    NSLog(@"播放失败的代理方法");
}
//缓存中的代理方法
-(void)playerViewBuffering:(VedioPlayerView *)player {
    NSLog(@"缓存中的代理方法");
}
//播放完毕的代理方法
-(void)playerViewFinished:(VedioPlayerView *)player {
    NSLog(@"播放完毕的代理方法");
}

@end
