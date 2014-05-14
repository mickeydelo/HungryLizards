//
//  LizardAI.h
//  HungryLizards
//

#import "cocos2d.h"
#import <Foundation/Foundation.h>
#import "GameConfig.h"
#import "GameObject.h"

@class GameBug;
@class GameObject;

enum
{
    LizardIdle      = 0,
    LizardBlink     = 1,
    LizardJump      = 2,
    LizardEat       = 3,
    LizardWaiting   = 4,
    LizardStartJump = 5
};

enum
{
    InFront    = 0,
    FromBehind = 1
};

enum
{
    Further = 0,
    Behind  = 1,
    Ahead   = 2,
    NoSense = 3
};

@class GameLizard;

@protocol LizardDelegate <NSObject>

- (int)getAvailableStonePosition:(GameLizard*)lizard;
- (NSMutableArray *)bugs;
- (int)currentLevelIndex;
- (GameMode)currentGameMode;
- (void)fadeToBlack;

@end

@interface LizardAI : GameObject
{
      int   stonePlace;
      int    jumpType;
      int    bugPosition;
      int    currentState;
      int    bug_direction;
      double x_diff;
      double y_diff;
      double bugFlightDuration;
      double deviation;
      double liz_x;
      double bug_x;
      double bug_y;
      double liz_time;
      double last_x_diff;
      float  doublingEffectTimeout;
      int    index;

      BOOL isOnLeftSide;
      BOOL closestFound;
      BOOL isGettingFurther;

      long double time_to_wait;
      long double front_place_influence[2];

      ccBezierConfig lizardBezier1;
      ccBezierConfig lizardBezier2;
      ccBezierConfig lizardBezier3;
      ccBezierConfig lizardBezier4;

      ccBezierConfig lizardBezier5;
      ccBezierConfig lizardBezier6;
      ccBezierConfig lizardBezier7;
      ccBezierConfig lizardBezier8;

      ccBezierConfig curves[2];

      CGPoint        places[2];
      CGPoint        lizardStartPos1;
      CGPoint        lizardStartPos2;
      CGPoint        lizardStartPos3;
      CGPoint        lizardStartPos4;

     BOOL isError;
}

@property (nonatomic, retain) GameBug        *closestBug;
@property (nonatomic, retain) CCSprite       *catchArea;
@property (nonatomic, retain) NSMutableArray *leftCatchAreas;
@property (nonatomic, retain) NSMutableArray *rightCatchAreas;
@property (nonatomic, retain) NSMutableArray *catchAreas;

@property (nonatomic, assign) id<LizardDelegate> levelDelagate;

@property (nonatomic) BOOL    isError;
@property (nonatomic) int                     index;
@property (nonatomic) int   stonePlace;
@property (nonatomic) BOOL  isOnLeftSide;
@property (nonatomic) int   currentState;
@property (nonatomic) float doublingEffectTimeout;
@property (nonatomic) BOOL  closestFound;
@property (nonatomic) int   levelIndex;

- (BOOL)isClosestEaten;
- (GameBug *)findClosestBug:(NSMutableArray *)bugs;
- (void)firstCheck:(GameBug *)bug;
- (double)calculateJumpTimeOut:(NSMutableArray *)bugs;
- (void)getCurvePoints;

@end
