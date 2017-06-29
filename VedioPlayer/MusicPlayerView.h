//
//  MusicPlayerView.h
//  VedioPlayer
//
//  Created by yanghuang on 2017/5/27.
//  Copyright © 2017年 com.yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VedioPlayerView.h"
#import "VedioModel.h"
#import "MusicSlider.h"

@interface MusicPlayerView : VedioPlayerView
/**  初始音乐  */
- (void)setUp:(VedioModel *)model;
/**  更换不播放  */
- (void)changeMusic:(VedioModel *)musicModel;
/**  更换音乐并播放  */
- (void)changAndPlayMusic:(VedioModel *)musicModel;
@end
