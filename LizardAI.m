//
//  LizardAI.m
//  HungryLizards
//

#import "LevelScene.h"
#import "LizardAI.h"
#import "GameBug.h"
#import "GameConsts.h"

@implementation LizardAI

static inline float bezierat( float a, float b, float c, float d, ccTime t )
{
	return (powf(1-t,3) * a +
			3*t*(powf(1-t,2))*b +
			3*powf(t,2)*(1-t)*c +
			powf(t,3)*d );
}

@synthesize isOnLeftSide, currentState, doublingEffectTimeout, closestFound, stonePlace, levelIndex, index, isError;

@synthesize closestBug = _closestBug;
@synthesize catchArea = _catchArea;
@synthesize leftCatchAreas = _leftCatchAreas;
@synthesize rightCatchAreas = _rightCatchAreas;
@synthesize catchAreas = _catchAreas;

@synthesize levelDelagate = _levelDelagate;

- (id)init
{
    if (self = [super init])
    {
        front_place_influence[0] = LEFT_PLACE_INFLUENCE;
        front_place_influence[1] = RIGHT_PLACE_INFLUENCE;
        self.leftCatchAreas      = [[[NSMutableArray alloc] init] autorelease];
        self.rightCatchAreas     = [[[NSMutableArray alloc] init] autorelease];
        self.catchAreas          = [[[NSMutableArray alloc] init] autorelease];
        isError                  = NO;
    }

    return self;
}

- (void)getCurvePoints
{
    float time_moment = 0.05;

    ccBezierConfig curve = curves[!isOnLeftSide];

    while (time_moment < 1.0)
    {
        float x = bezierat(0, curve.controlPoint_1.x, curve.controlPoint_2.x, curve.endPosition.x, time_moment);
        float y = bezierat(0, curve.controlPoint_1.y, curve.controlPoint_2.y, curve.endPosition.y, time_moment);

        CGPoint point = ccp(x + places[!isOnLeftSide].x, y + 70 * HEIGHT_RATIO);

        CCSprite *sprite = [CCSprite spriteWithFile:@"res/src/empty.png"];
        [sprite setDisplayFrame:[CCSpriteFrame frameWithTexture:[sprite texture] rect:CGRectMake(0, 0, 72, 16)]];

        [sprite setPosition:point];

        if (IS_IPHONE)
            [sprite setPosition:ccp(point.x + (78 * WIDTH_RATIO), point.y + 58 * HEIGHT_RATIO)];
        else
            [sprite setPosition:ccp(point.x + (64 * WIDTH_RATIO), point.y + 40 * HEIGHT_RATIO)];

        [sprite setScale:SCALE_RATIO];

        [self.leftCatchAreas addObject:sprite];

        time_moment += 0.02;
    }

    time_moment = 0.02;

    curve = curves[isOnLeftSide];

    while (time_moment < 1.0)
    {
        float x = bezierat(0, curve.controlPoint_1.x, curve.controlPoint_2.x, curve.endPosition.x, time_moment);
        float y = bezierat(0, curve.controlPoint_1.y, curve.controlPoint_2.y, curve.endPosition.y, time_moment);

        CGPoint point = ccp(x + places[isOnLeftSide].x, y + 70 * HEIGHT_RATIO);

        CCSprite *sprite = [CCSprite spriteWithFile:@"res/src/empty.png"];
        [sprite setDisplayFrame:[CCSpriteFrame frameWithTexture:[sprite texture] rect:CGRectMake(0, 0, 72, 16)]];

        if (IS_IPHONE)
            [sprite setPosition:ccp(point.x - (78 * WIDTH_RATIO), point.y + 58 * HEIGHT_RATIO)];
        else
            [sprite setPosition:ccp(point.x - (64 * WIDTH_RATIO), point.y + 40 * HEIGHT_RATIO)];

        [sprite setScale:SCALE_RATIO];

        [self.rightCatchAreas addObject:sprite];

        time_moment += 0.02;
    }

    [self.catchAreas addObject:self.leftCatchAreas];
    [self.catchAreas addObject:self.rightCatchAreas];

    [self transformCatchAreas];
}

- (void)transformCatchAreas
{
    for (int i = 0; i < self.catchAreas.count ; i++)
    {
        NSMutableArray *leftSideArray  = [[[NSMutableArray alloc] init] autorelease];
        NSMutableArray *rightSideArray = [[[NSMutableArray alloc] init] autorelease];

        int j = 0;

        while ([[[self.catchAreas objectAtIndex:i] objectAtIndex:j] boundingBox].origin.y < [[[self.catchAreas objectAtIndex:i] objectAtIndex:j + 1] boundingBox].origin.y )
        {
            [leftSideArray addObject:[[self.catchAreas objectAtIndex:i] objectAtIndex:j]];
            j++;
        }

        for (;j < [[self.catchAreas objectAtIndex:i] count]; j++)
            [rightSideArray addObject:[[self.catchAreas objectAtIndex:i] objectAtIndex:j]];

        rightSideArray = (NSMutableArray *)[rightSideArray sortedArrayUsingComparator:^(id a, id b)
                                            {
                                                return NSOrderedDescending;
                                            }];

        [[self.catchAreas objectAtIndex:i] setArray:[NSArray arrayWithObjects:leftSideArray, rightSideArray, nil]];
    }
}

- (void)setError
{
    int errorProb = arc4random() % (10 - levelIndex);

    if (levelIndex > 4)
        errorProb += (10 - levelIndex) / 2;

    NSMutableArray *seedArray = [[[NSMutableArray alloc] init] autorelease];

    for (int i = 0; i < 15; i++)
        [seedArray addObject:@"0"];

    for (int i = 0; i < errorProb; i++)
        [seedArray replaceObjectAtIndex:arc4random() % 15 withObject:@"1"];

    if (levelIndex == 0)
        for (int i = 0; i < (errorProb * 2); i++)
            [seedArray replaceObjectAtIndex:arc4random() % 15 withObject:@"1"];

    NSString *errorFactor = [seedArray objectAtIndex:arc4random() % 15];

    isError = [errorFactor isEqualToString:@"1"];
}

- (double)findLizardTime:(int)_index forItem:(int)itemIndex forCoincidence:(BOOL)coincidence
{
    int generalIndex;

    if (!coincidence)
        generalIndex = [[[self.catchAreas objectAtIndex:_index] objectAtIndex:0] count] + itemIndex;
    else
        generalIndex = itemIndex;

    double rvalue = generalIndex * 0.02;

    return rvalue;
}

- (double)catchingTargetForIndex:(BOOL)_index
{
    int i = 0;
    BOOL arrayIndex = _index;

    while (i <= ([[[self.catchAreas objectAtIndex:!isOnLeftSide] objectAtIndex:arrayIndex] count] - 1))
    {
        if ([[[[self.catchAreas objectAtIndex:!isOnLeftSide] objectAtIndex:arrayIndex] objectAtIndex:i] boundingBox].origin.y > self.closestBug.startPos.y)
        {
            self.catchArea = [[[self.catchAreas objectAtIndex:!isOnLeftSide] objectAtIndex:arrayIndex] objectAtIndex:i];
            break;
        }
        i++;
    }

    BOOL coincidence   = jumpType == Behind ? YES : NO;
    double bug_start_pos = self.closestBug.position.x;

    bug_x = bug_start_pos - self.catchArea.position.x;

    if (bug_x < 0)
        bug_x = -bug_x;

    double bugProportion = SCREEN_WIDTH / bug_x;
    double bugTime = bugFlightDuration / bugProportion;

    double myTime  = [self findLizardTime:isOnLeftSide forItem:i forCoincidence:coincidence];

    time_to_wait = bugTime - myTime;

    if (jumpType != Behind)
    {
        if (bugFlightDuration == 8.0)
            time_to_wait *= 1.1;

        if (bugFlightDuration == 7.0)
            time_to_wait *= 1.1;

        if (bugFlightDuration == 6.0)
            time_to_wait *= 1.1;

        if (bugFlightDuration == 4.0)
            time_to_wait *= 1.1;

        if (bugFlightDuration == 3.0)
        {
            time_to_wait *= 1.4;

            if (jumpType == Ahead && x_diff < 100 * WIDTH_RATIO)
                time_to_wait = 0.001;
        }

        if (bugFlightDuration == 2.0)
        {
            time_to_wait *= 1.6;

            if (jumpType == Ahead && x_diff < 150 * WIDTH_RATIO)
                time_to_wait = 0.001;
        }
    }

    if (jumpType == Behind)
    {
        if (bugFlightDuration <= 4.0)
            time_to_wait *= 0.8;
    }
    return time_to_wait >= 0 ? time_to_wait : 0;
}

- (double)calculation
{
    if (stonePlace <= 1)
    {
        if (bug_direction > 0)
        {
            if (liz_x <= bug_x)
                jumpType = Further;

            else
                jumpType = Behind;
        }
        else
        {
            if (liz_x <= bug_x)
                jumpType = Ahead;
            else
                jumpType = NoSense;
        }
    }
    else
    {
        if (bug_direction > 0)
        {
            if (liz_x <= bug_x)
                jumpType = NoSense;
            else
                jumpType = Ahead;
        }
        else
        {
            if (liz_x <= bug_x)
                jumpType = Behind;

            else
                jumpType = Further;
        }
    }

    switch (jumpType)
    {
        case Behind:
            return [self catchingTargetForIndex:0];

        case Ahead:
            return [self catchingTargetForIndex:x_diff >= 350 * WIDTH_RATIO ? 1 : 0];

        case Further:
            return [self catchingTargetForIndex:x_diff >= 50 * WIDTH_RATIO ? 1 : 0];
            break;

        case NoSense:
            return -1;
    }

    return 1;
}

- (BOOL)isClosestEaten
{
    if (!self.levelDelagate)
        return NO;

    for (int i = 0; i < self.levelDelagate.bugs.count;i++)
        if (self.closestBug == [[self.levelDelagate bugs] objectAtIndex:i])
            return NO;

    NSArray *swarm = [(LevelLayer *)self.levelDelagate currentSwarm];

    for (int i = 0; i < swarm.count; i++)
        if (self.closestBug == [swarm objectAtIndex:i])
            return NO;

    return YES;
}

- (GameBug *)findClosestBug:(NSMutableArray *)bugs
{
    double bug_diff = 1000.0, swarm_diff = 1000.0;
    int cl_index    = -1;

    for (int i = 0; i < bugs.count; i++)
    {
        if([[bugs objectAtIndex:i] currentType] == BugType_BumbleBee && doublingEffectTimeout <= 0)
            continue;

        double diff = self.position.x - [(GameBug *)[bugs objectAtIndex:i] position].x;

        if (diff < 0.0)
            diff = -diff;

        if (bug_diff > diff)
        {
            bug_diff = diff;
            cl_index = i;
        }
    }

    NSArray *swarm = nil;

    if (self.levelDelagate)
        swarm = [(LevelLayer *)self.levelDelagate currentSwarm];

    if (swarm.count == 0)
        swarm = nil;

    int flies_count = swarm.count, cl_index_in_swarm = -1;

    for (int i = 0; i < flies_count; i++)
    {
        double diff = self.position.x - [(GameBug *)[swarm objectAtIndex:i] position].x;

        if (diff < 0.0)
            diff = -diff;

        if (swarm_diff > diff)
        {
            swarm_diff = diff;
            cl_index_in_swarm = i;
        }
    }

    closestFound = YES;

    if (cl_index < 0 && cl_index_in_swarm < 0)
        return nil;
    else
        return swarm == nil ? [bugs objectAtIndex:cl_index] : [swarm objectAtIndex:cl_index_in_swarm];
}

- (void)firstCheck:(GameBug *)bug
{
    bugFlightDuration = bug.timeFlying;
    bug_direction     = bug.currentDirection;
    liz_x             = self.position.x;
    bug_x             = bug.position.x;
    bug_y             = bug.position.y;
    y_diff            = bug_y - self.position.y;
    liz_time          = (y_diff / 0.5) * 0.0165;
    last_x_diff       = x_diff;
    x_diff            = liz_x - bug_x;

    if (x_diff < 0)
        x_diff = -x_diff;

    double  bug_time     = (x_diff / 0.5) * 0.0165;
    time_to_wait = bug_time - liz_time;

    if (time_to_wait < 0)
        time_to_wait = - time_to_wait;
}

- (double)calculateJumpTimeOut:(NSMutableArray *)bugs
{
    self.closestBug = [self findClosestBug:bugs];

    if (self.closestBug == nil)
        goto m2;

    closestFound = YES;
    [self firstCheck:self.closestBug];

    time_to_wait =  [self calculation];

    if (time_to_wait <= 0)
        goto m2;
    else
        currentState = LizardIdle;
    goto m3;

    if (bugs.count == 0)
    {

    m2:;
        time_to_wait = 0.000000;
        currentState = LizardWaiting;
    }

    else
        if (closestFound)
            currentState = LizardIdle;
m3:;

    if (time_to_wait != 0 && self.closestBug.currentType != BugType_FruitFly)
        [self setError];

    if ([[GameLevel sharedGameLevel] currentLevelIndex] == 9)
        time_to_wait /= 1.45;

    if (self.closestBug.currentType == BugType_FruitFly && self.closestBug.isFlying)
    {
        float distance = self.position.x - self.closestBug.position.x;

        if (distance < 0)
            distance = -distance;

        if (distance > 200)
            time_to_wait = 0.01;
        else
            time_to_wait -= 0.4;
    }

    return time_to_wait;

}

- (void)dealloc
{
    self.closestBug = nil;
    self.catchArea = nil;
    self.leftCatchAreas = nil;
    self.rightCatchAreas = nil;
    self.catchAreas = nil;
    self.levelDelagate = nil;

    [super dealloc];
}

@end