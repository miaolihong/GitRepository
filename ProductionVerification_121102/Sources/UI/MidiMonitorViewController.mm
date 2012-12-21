//
//  MidiMonitorViewController.m
//  MidiMonitor
//
//  Created by Pete Goodliffe on 10/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//  

#import "MidiMonitorViewController.h"

#import "PGMidi.h"
#import "iOSVersionDetection.h"
#import <CoreMIDI/CoreMIDI.h>
#import <AudioToolbox/AudioToolbox.h>
#import "UpdateFirmwareData.h"
#define NUMBERS	@"0123456789"

UInt8 RandomNoteNumber() { return UInt8(rand() / (RAND_MAX / 8)); }


//UInt8 updateFirmwareCmdSend[64];
UInt8 updateFirmwareCmdSend[48];// = {0xf0,0x00,0x20,0x2b,0x69,0x32};
UInt32 updateFirmwareReadPointer = 0;
UInt32 updateFirmwareWritePointer = 0;
BOOL updateFirmwareReqResponded = NO;//0x71
UInt8 updateFirmwareAllowed = NO;//0x71
BOOL updateFirmwareAckReceived = NO;//0x72
UInt8 updateFirmwarePacketAckNoError = NO;//0x72
//BOOL updateFirmwareFlag = NO;
BOOL updateFirmwareInProgress = NO;
BOOL updateFirmwareFinished = NO;
UInt32 numberOfBytesUpdated = 0;
BOOL updateErrorCode[5] = {0,0,0,0,0};
UInt16 timecount = 0;

NSString *timestamp;
NSString *yearOfDateTimestamp;
NSString *monthOfDateTimestamp;
NSString *dayOfDateTimestamp;
NSString *textDateTimestamp;
NSDate *textDate;

UInt8 rcvcmd;
BOOL deviceAttached = NO;
BOOL selfCheckRequestResponded = NO;

UInt8 deviceClass;
UInt8 deviceID[2];
UInt8 deviceNameLength;
UInt8 deviceNameArray[10];
NSString *deviceName;
UInt8 deviceFirmwareVersion[3];
UInt8 deviceProductionDate[3];
UInt8 deviceSerialNumber[3];

UInt8 devicePowerMode;
UInt8 devicePowerSupply;
UInt8 deviceBatteryState;
UInt8 deviceHeadphoneState;
UInt8 deviceKickState;
UInt8 deviceHiHatState;
BOOL ledStatus = NO;
BOOL nextStepButtonPressed = NO;
UInt8 statusProgress = 0;
UInt8 processProgress = 0;
UInt8 tempProcessProgress = 0;
BOOL enterStepFiveForTheFirstTime = YES;
BOOL serialNumberSetForOneProduct = NO;

UInt8 deviceNote = 0;
UInt8 deviceVelocity[9] = {0,0,0,0,0,0,0,0,0};
BOOL deviceNoteReachedMax[9] = {NO,NO,NO,NO,NO,NO,NO,NO,NO};
BOOL deviceNoteReachedMiddle[9] = {NO,NO,NO,NO,NO,NO,NO,NO,NO};
BOOL noteOnReceived[9] = {NO,NO,NO,NO,NO,NO,NO,NO,NO};
BOOL deviceAllNotesReachedMax = NO;
BOOL noteOffReceived[9] = {NO,NO,NO,NO,NO,NO,NO,NO,NO};
BOOL allNotesOffReceived = NO;
BOOL hihatCloseNoteOnReceived = NO;
BOOL hihatCloseNoteOffReceived = NO;

UInt8 deviceVolume = 0;
UInt8 testVoiceNumber = 0;
double voiceInterval = 0.3;
UInt8 muteLeftRight = 0;
UInt8 errorCode = 0;
UInt32 serialNumberToWrite;
UInt32 serialNumberAsDecimal;

NSTimer *updateTimer;

NSDateFormatter *yearFormatter;
NSDateFormatter *monthFormatter;
NSDateFormatter *dayFormatter;
NSDateFormatter *textDateFormatter;
UInt8 jj;

UIAlertView *resetSerialNumberAlertView;
UIAlertView *serialNumberSetAlertView;
UIAlertView *serialNumberSetAlertView1;
UIAlertView *updateFirmwareAlertView;

//NSString *receiveMidiPacket;
/*
OSStatus RenderTone(
                    void *inRefCon, 
                    AudioUnitRenderActionFlags 	*ioActionFlags, 
                    const AudioTimeStamp 		*inTimeStamp, 
                    UInt32 						inBusNumber, 
                    UInt32 						inNumberFrames, 
                    AudioBufferList 			*ioData)

{
	// Fixed amplitude is good enough for our purposes
	const double amplitude = 0.25;
    
	// Get the tone parameters out of the view controller
	MidiMonitorViewController *viewController =
    (__bridge MidiMonitorViewController *)inRefCon;
	double theta = viewController->theta;
	double theta_increment = 2.0 * M_PI * 200.0 / viewController->sampleRate;
    //    double theta_increment = 2.0 * M_PI * viewController->frequency / viewController->sampleRate;
	// This is a mono tone generator so we only need the first buffer
	const int channel = 0;
	Float32 *buffer = (Float32 *)ioData->mBuffers[channel].mData;
	
	// Generate the samples
	for (UInt32 frame = 0; frame < inNumberFrames; frame++) 
	{
		buffer[frame] = sin(theta) * amplitude;
		
		theta += theta_increment;
		if (theta > 2.0 * M_PI)
		{
			theta -= 2.0 * M_PI;
		}
	}
	
	// Store the theta back in the view controller
	viewController->theta = theta;
    
	return noErr;
}

void ToneInterruptionListener(void *inClientData, UInt32 inInterruptionState)
{
	MidiMonitorViewController *viewController =
    (__bridge MidiMonitorViewController *)inClientData;
	
	[viewController stop];
}
*/
@interface MidiMonitorViewController () <PGMidiDelegate, PGMidiSourceDelegate,UITextFieldDelegate>
- (void) updateCountLabel;
- (void) addString:(NSString*)string;
- (void) sendMidiDataInBackground;
- (void) sendLedControlMidiInBackground;
- (void) updateSerialNumberString;

@end

@implementation MidiMonitorViewController

#pragma mark PGMidiDelegate
@synthesize displayUpdateProgress;
@synthesize ledControlButton;
@synthesize ledControlButton1;
@synthesize serialNumberString;
@synthesize countLabel;
@synthesize dateButton0;
@synthesize dateButton1;
@synthesize serialNumberConfig;
@synthesize pickerView;
@synthesize displayCurrentDate;
@synthesize displayFirstStep;
@synthesize displaySecondStep;
@synthesize displayThirdStep;
@synthesize displayFourthStep;
@synthesize displayDeviceName;
@synthesize displayDeviceSerialNumber;
@synthesize displayDeviceVersionNumber;
@synthesize displayDeviceProductionDate;
@synthesize displayHeadphonePlugState;
@synthesize displayKickPlugState;
@synthesize displayHiHatPlugState;
@synthesize displayDeviceBatteryLevel;
@synthesize displayDevicePowerState;
@synthesize displayVoiceLevel;
@synthesize displayDrumPad0;
@synthesize displayDrumPad1;
@synthesize displayDrumPad2;
@synthesize displayDrumPad3;
@synthesize displayDrumPad4;
@synthesize displayDrumPad5;
@synthesize displayDrumPad6;
@synthesize displayDrumPad7;
@synthesize displayDrumPad8;
@synthesize ledControlSwitch1;
@synthesize makeVoiceInterval;
@synthesize serialNumberButton;
@synthesize yearOfDateText;
@synthesize monthOfDateText;
@synthesize dayOfDateText;
@synthesize midi;
@synthesize soundFileURLRef0;
@synthesize soundFileObject0;
@synthesize soundFileURLRef1;
@synthesize soundFileObject1;
@synthesize soundFileURLRef2;
@synthesize soundFileObject2;
@synthesize soundFileURLRef3;
@synthesize soundFileObject3;
@synthesize soundFileURLRef4;
@synthesize soundFileObject4;
@synthesize soundFileURLRef5;
@synthesize soundFileObject5;
@synthesize soundFileURLRef6;
@synthesize soundFileObject6;
@synthesize soundFileURLRef7;
@synthesize soundFileObject7;
@synthesize soundFileURLRef8;
@synthesize soundFileObject8;
@synthesize soundFileURLRef9;
@synthesize soundFileObject9;
@synthesize soundFileURLRef10;
@synthesize soundFileObject10;
@synthesize soundFileURLRef11;
@synthesize soundFileObject11;

#pragma mark UIViewController

- (void) viewWillAppear:(BOOL)animated
{
    [self clearTextView];
    [self updateCountLabel];
    IF_IOS_HAS_COREMIDI
    (
//        [self addString:@""];
//      [self addString:@"支持Core MIDI"];
    )
    else
    {
//        [self addString:@"You are running iOS before 4.2. CoreMIDI is not supported."];
    }
}

#pragma mark IBActions

- (IBAction)ledControlButtonPressed {
    ledControlButton.hidden = YES;
    ledControlButton1.hidden = NO;
    ledStatus ^= 1;
//    display
    [self performSelectorInBackground:@selector(sendLedControlMidiInBackground) withObject:nil];
}
- (IBAction)ledControl1ButtonPressed {
    ledControlButton.hidden = NO;
    ledControlButton1.hidden = YES;
    ledStatus ^= 1;
    [self performSelectorInBackground:@selector(sendLedControlMidiInBackground) withObject:nil];
}

- (IBAction)resetSerialNumberButtonPressed:(UIButton *)sender {
    resetSerialNumberAlertView = [[UIAlertView alloc]initWithTitle:@"提示" message:@"是否要重置序列号？" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"取消", nil];
    [resetSerialNumberAlertView show];
//    [resetSerialNumberAlertView release];
//    serialNumberConfig.text = @"000001";
//    serialNumberToWrite = 1;
}
- (IBAction)updateFirmware:(UIButton *)sender {
    updateFirmwareAlertView = [[UIAlertView alloc]initWithTitle:@"" message:@"确定更新固件？" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"取消", nil];
    [updateFirmwareAlertView show];
}

- (IBAction)dateButtonPressed{
    serialNumberButton.enabled = NO;
    yearOfDateText.enabled = NO;
    monthOfDateText.enabled = NO;
    dayOfDateText.enabled = NO;
    serialNumberConfig.enabled = NO;
    
    dateButton0.hidden = YES;
    dateButton1.hidden = NO;
    pickerView.hidden = NO;
    
/*    textDateTimestamp = [[[NSString alloc]init]autorelease];
    [textDateTimestamp stringByAppendingString:yearOfDateText.text];
    [textDateTimestamp stringByAppendingString:monthOfDateText.text];
    [textDateTimestamp stringByAppendingString:dayOfDateText.text];
*/    
/*    textDateFormatter = [[[NSDateFormatter alloc] init]autorelease];
//    [textDateFormatter setDateStyle:NSDateFormatterShortStyle]; 
    
//    textDateFormatter.dateFormat = @"YY-MM-dd";
    textDateFormatter.dateFormat = @"YYMMdd";
    self.pickerView.date = [textDateFormatter dateFromString: textDateTimestamp];
 */
    
    self.pickerView.date = [NSDate date];
    yearFormatter = [[[NSDateFormatter alloc] init]autorelease];
    yearFormatter.dateFormat = @"YY";
    yearOfDateTimestamp = [yearFormatter stringFromDate:[NSDate date]];
    yearOfDateText.text = [NSString stringWithFormat: @"%@",yearOfDateTimestamp];
    yearOfDateString = (UInt8)[[yearOfDateText text] intValue];    
    monthFormatter = [[[NSDateFormatter alloc] init]autorelease];
    monthFormatter.dateFormat = @"MM";
    monthOfDateTimestamp = [monthFormatter stringFromDate:[NSDate date]];
    monthOfDateText.text = [NSString stringWithFormat: @"%@",monthOfDateTimestamp];
    monthOfDateString = (UInt8)[[monthOfDateText text] intValue];
    dayFormatter = [[[NSDateFormatter alloc] init]autorelease];
    dayFormatter.dateFormat = @"dd";
    dayOfDateTimestamp = [dayFormatter stringFromDate:[NSDate date]];
    dayOfDateText.text = [NSString stringWithFormat: @"%@",dayOfDateTimestamp];
    dayOfDateString = (UInt8)[[dayOfDateText text] intValue];
    yearOfDateText.text = [NSString stringWithFormat:@"%02d",yearOfDateString];
    monthOfDateText.text = [NSString stringWithFormat:@"%02d",monthOfDateString];
    dayOfDateText.text = [NSString stringWithFormat:@"%02d",dayOfDateString];

}

- (IBAction)dateButton1Pressed{
    serialNumberButton.enabled = YES;
    yearOfDateText.enabled = YES;
    monthOfDateText.enabled = YES;
    dayOfDateText.enabled = YES;
    serialNumberConfig.enabled = YES;
    
    dateButton1.hidden = YES;
    dateButton0.hidden = NO;
    pickerView.hidden = YES;
    
    yearOfDateString = (UInt8)[[yearOfDateText text] intValue];
    monthOfDateString = (UInt8)[[monthOfDateText text] intValue];
    dayOfDateString = (UInt8)[[dayOfDateText text] intValue];
    textDateFormatter = [[[NSDateFormatter alloc] init]autorelease];
//    [textDateFormatter setDateStyle:NSDateFormatterShortStyle];
    textDateTimestamp = [textDateFormatter stringFromDate: pickerView.date];
    
//    yearOfDateText.text = [NSString stringWithFormat:@"%02d",yearOfDateString];
//    monthOfDateText.text = [NSString stringWithFormat:@"%02d",monthOfDateString];
//    dayOfDateText.text = [NSString stringWithFormat:@"%02d",dayOfDateString];
}

- (IBAction)dateAction{
    
    yearFormatter = [[[NSDateFormatter alloc] init]autorelease];
    yearFormatter.dateFormat = @"YY";
    yearOfDateTimestamp = [yearFormatter stringFromDate:pickerView.date];
    yearOfDateText.text = [NSString stringWithFormat: @"%@",yearOfDateTimestamp];
    yearOfDateString = (UInt8)[[yearOfDateText text] intValue];    
    monthFormatter = [[[NSDateFormatter alloc] init]autorelease];
    monthFormatter.dateFormat = @"MM";
    monthOfDateTimestamp = [monthFormatter stringFromDate:pickerView.date];
    monthOfDateText.text = [NSString stringWithFormat: @"%@",monthOfDateTimestamp];
    monthOfDateString = (UInt8)[[monthOfDateText text] intValue];
    dayFormatter = [[[NSDateFormatter alloc] init]autorelease];
    dayFormatter.dateFormat = @"dd";
    dayOfDateTimestamp = [dayFormatter stringFromDate:pickerView.date];
    dayOfDateText.text = [NSString stringWithFormat: @"%@",dayOfDateTimestamp];
    dayOfDateString = (UInt8)[[dayOfDateText text] intValue];
}

- (IBAction)voiceTimeInterval:(UISlider *)sender {
    if(makeVoiceInterval.value<0.23){
        makeVoiceInterval.value = 0;
    }else if(makeVoiceInterval.value <0.36){
        makeVoiceInterval.value = 0.25;
    }else{
        makeVoiceInterval.value = 0.4;
    }
    voiceInterval = makeVoiceInterval.value;
}

- (IBAction)serialNumberSet {
    [serialNumberConfig resignFirstResponder];
    if(serialNumberSetForOneProduct == YES){
        serialNumberSetAlertView1 = [[UIAlertView alloc]initWithTitle:@"" message:@"已对本产品生成过一次序列号，是否继续生成序列号？" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"取消", nil];
        [serialNumberSetAlertView1 show];
    }
    else if(statusProgress == 5)
    {
    serialNumberToWrite = (UInt32)[[serialNumberConfig text] intValue];
    yearOfDateString = (UInt8)[[yearOfDateText text] intValue];
    monthOfDateString = (UInt8)[[monthOfDateText text] intValue];
    dayOfDateString = (UInt8)[[dayOfDateText text] intValue];
    
    UInt8 serialNumberCommand[] = {0xf0,0x00,0x20,0x2b,0x69,0x30,0x00,0x01,0x08,0x43,0x55,0x42,0x45,0x41,0x54,0x00,0x00,(UInt8)(serialNumberToWrite%1000000/100000),(UInt8)(serialNumberToWrite%100000/10000),(UInt8)(serialNumberToWrite%10000/1000),(UInt8)(serialNumberToWrite%1000/100),(UInt8)(serialNumberToWrite%100/10),(UInt8)(serialNumberToWrite%10),(UInt8)(yearOfDateString/10),(UInt8)(yearOfDateString%10),(UInt8)(monthOfDateString/10),(UInt8)(monthOfDateString%10),(UInt8)(dayOfDateString/10),(UInt8)(dayOfDateString%10),0xf7};
    //{0xf0,0x00,0x20,0x2b,0x69,0x30,0x00,0x01,0x08,0x42,0x65,0x61,0x74,0x42,0x6f,0x78,0x00,0x00,0x00,0x00,0x00,0x01,0xf7};
    [self performSelectorOnMainThread:@selector(addString:)
                           withObject:nil//[NSString stringWithFormat:@"MIDI发送:[%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x]",serialNumberCommand[0],serialNumberCommand[1],serialNumberCommand[2],serialNumberCommand[3],serialNumberCommand[4],serialNumberCommand[5],serialNumberCommand[6],serialNumberCommand[7],serialNumberCommand[8],serialNumberCommand[9],serialNumberCommand[10],serialNumberCommand[11],serialNumberCommand[12],serialNumberCommand[13],serialNumberCommand[14],serialNumberCommand[15],serialNumberCommand[16],serialNumberCommand[17],serialNumberCommand[18],serialNumberCommand[19],serialNumberCommand[20],serialNumberCommand[21],serialNumberCommand[22],serialNumberCommand[23],serialNumberCommand[24],serialNumberCommand[25],serialNumberCommand[26],serialNumberCommand[27],serialNumberCommand[28],serialNumberCommand[29],serialNumberCommand[30],serialNumberCommand[31],serialNumberCommand[32]]
                        waitUntilDone:NO];
    [midi sendBytes:serialNumberCommand size:sizeof(serialNumberCommand)];
        serialNumberToWrite++;
    if(serialNumberToWrite>=1000000){
        serialNumberToWrite = 1;
    }
    serialNumberConfig.text = [NSString stringWithFormat:@"%06ld",serialNumberToWrite];
    
        const UInt8 selfcheckreq111[] = {0xf0,0x00,0x20,0x2b,0x69,0x01,0xf7};//refresh serialnumber
        [midi sendBytes:selfcheckreq111 size:sizeof(selfcheckreq111)];
        serialNumberSetForOneProduct = YES;
    }
    else
    {
        serialNumberSetAlertView = [[UIAlertView alloc]initWithTitle:@"" message:@"检测未完成，是否继续生成序列号？" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"取消", nil];
        [serialNumberSetAlertView show];
//        [serialNumberSetAlertView release];
    }
}

- (IBAction)clearTextView
{
    //All initialization
//    textView.text = nil;
    displayDeviceName.text = nil;
    displayDeviceProductionDate.text = nil;
    displayDeviceSerialNumber.text = nil;
    displayDeviceVersionNumber.text = nil;
    displayHeadphonePlugState.on = NO;
    displayKickPlugState.on = NO;
    displayHiHatPlugState.on = NO;
    displayDeviceBatteryLevel.value = 0;
    displayVoiceLevel.value = 0;
    displayDevicePowerState.text = @"电池状态";
    deviceAllNotesReachedMax = NO;
    displayDrumPad0.text = [NSString stringWithFormat:@"Hi-Hat Open"];
    displayDrumPad0.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
    displayDrumPad1.text = [NSString stringWithFormat:@"Tom 2"];
    displayDrumPad1.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
    displayDrumPad2.text = @"Crash 1";
    displayDrumPad2.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
    displayDrumPad3.text = @"Snare";
    displayDrumPad3.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
    displayDrumPad4.text = @"Tom 1";
    displayDrumPad4.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
    displayDrumPad5.text = @"Ride";
    displayDrumPad5.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
    displayDrumPad6.text = @"Hi-Hat Pedal";
    displayDrumPad6.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
    displayDrumPad7.text = @"Kick";
    displayDrumPad7.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
    if(deviceAttached){
        displayDrumPad8.text = @"请进入第一步";
    }else{
        displayDrumPad8.text = @"请连接设备";
    }
    displayDrumPad8.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
    displayFirstStep.textColor = [UIColor blackColor];
    displaySecondStep.textColor = [UIColor blackColor];
    displayThirdStep.textColor = [UIColor blackColor];
    displayFourthStep.textColor = [UIColor blackColor];
    //displayDrumPad0.highlighted = YES;
    memset(deviceNameArray, 0, 10);
    memset(deviceFirmwareVersion,0,3);
    memset(deviceProductionDate,0,3);
    memset(deviceSerialNumber,0,3);
    memset(deviceVelocity,0,9);
    memset(noteOnReceived,0,9);
    memset(noteOffReceived,0,9);
    memset(deviceNoteReachedMax,0,9);
    memset(deviceNoteReachedMiddle,0,9);
    deviceVolume = 0;
    devicePowerMode = 0;
    devicePowerSupply = 0;
    deviceKickState = 0;
    deviceHiHatState = 0;
    deviceBatteryState = 0;
    deviceHeadphoneState = 0;
    
    hihatCloseNoteOnReceived = NO;
    hihatCloseNoteOffReceived = NO;
    
    selfCheckRequestResponded = NO;
//    deviceAttached = NO;
    ledStatus = NO;
    statusProgress = 0;
    processProgress = 0;
    enterStepFiveForTheFirstTime = YES;
    errorCode = 0;
    
    
    ledControlButton.hidden = NO;
    ledControlButton1.hidden = YES;
    if(deviceAttached){
        displayFirstStep.textColor = [UIColor redColor];
    }else{
        displayFirstStep.textColor = [UIColor blackColor];
    }
    displaySecondStep.textColor = [UIColor blackColor];
    displayThirdStep.textColor = [UIColor blackColor];
    displayFourthStep.textColor = [UIColor blackColor];
//    serialNumberButton.enabled = NO;
    
    
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init]autorelease];
    formatter.dateFormat = @"今天:YY年MM月dd日";
    timestamp = [formatter stringFromDate:[NSDate date]];
    displayCurrentDate.text = [NSString stringWithFormat: @"%@",timestamp];
//    NSString * tempCurrentDate = [NSString stringWithFormat: @"%@",timestamp];
//    NSLog(displayCurrentDate.text);
//    if(displayCurrentDate.text!= tempCurrentDate)
//    if(![displayCurrentDate.text isEqualToString:tempCurrentDate])
/*    {
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"新的一天开始了" message:@"是否重置序列号？" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Cancel", nil];
        [alertView show];
        [alertView release];
    }
    displayCurrentDate.text = tempCurrentDate;
//    serialNumberConfig.text = [NSString stringWithFormat:@"%@", serialNumberString];
    [tempCurrentDate release];
 */
}

const char *ToString(BOOL b) { return b ? "YES":"NO"; }

NSString *ToString(PGMidiConnection *connection)
{
    return [NSString stringWithFormat:@"< PGMidi: 名称：%@ 网络连接：%s >",
            connection.name, ToString(connection.isNetworkSession)];
}

- (IBAction) listAllInterfaces
{
//    if(textView.hidden){
    IF_IOS_HAS_COREMIDI
    ({
//        [self addString:@"\n设备列表"];
        for (PGMidiSource *source in midi.sources)
        {
//            NSString *description = [NSString stringWithFormat:@"输入:%@", ToString(source)];
//            [self addString:description];
        }
//        [self addString:@""];
        for (PGMidiDestination *destination in midi.destinations)
        {
//            NSString *description = [NSString stringWithFormat:@"输出:%@", ToString(destination)];
//            [self addString:description];
        }
    })
//    }
//    textView.hidden ^=1;
//    countLabel.hidden ^= 1;
    UIAlertView *alertView1 = [[UIAlertView alloc]initWithTitle:@"关于" message:@"作者：缪立鸿\n版本：1.09_121116\n联系方式：miaolihong@medeli.com\n特别鸣谢：李蔚" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [alertView1 show];
    [alertView1 release];
    
}

- (IBAction)stepBackward{
    if(statusProgress > 1){
        if(statusProgress >= 4){
            enterStepFiveForTheFirstTime = YES;
            statusProgress = 3;
        }else{
            statusProgress = 1;
        }
    }
    if(processProgress > 1){
        if(processProgress >=4){
            processProgress = 2;
        }else{
            processProgress = 1;
        }
    }
    countLabel.text = [NSString stringWithFormat: @"[%02d:%02d]", statusProgress,processProgress];
    
    displayFirstStep.textColor = [UIColor blackColor];
    displaySecondStep.textColor = [UIColor blackColor];
    displayThirdStep.textColor = [UIColor blackColor];
    displayFourthStep.textColor = [UIColor blackColor];
    switch(processProgress){
        case 0:
        {
            displayFirstStep.textColor = [UIColor redColor];
            break;
        }
        case 1:
        {
            displayFirstStep.textColor = [UIColor redColor];
            break;
        }
        case 2:
        {
            displaySecondStep.textColor = [UIColor redColor];
            break;
        }
        case 3:
        {
            displayThirdStep.textColor = [UIColor redColor];
            break;
        }
        case 4:
        {
            displayThirdStep.textColor = [UIColor redColor];
            break;
        }
        case 5:
        {
            displayFourthStep.textColor = [UIColor redColor];
            break;
        }
        default:
            break;
    }
}

- (IBAction)operationInstruction{
    UIAlertView *operationInstructionAlertView = [[UIAlertView alloc]initWithTitle:@"操作说明" message:@"1.将产品的所有连接线插入（踏板、耳机、iPad、电源线）\n2.敲击鼓盘，观察所有鼓盘LED灯依次亮起红色、蓝色、绿色\n3.观察第一步部分信息，确认无误\n4.敲击鼓盘，确认第二步信息都在打开状态\n5.系统自动播放音频，确认音量自小到大依次递增\n6.敲击鼓盘直到iPad上所有鼓盘亮绿灯\n7.右下角的文本框底色变绿，并出现“通过，请生成序列号”后，点击右侧“生成序列号”按钮，观察第一步中的序列号及生产日期是否和右侧写入的一致\n8.断开所有连线，并重复1－8的步骤检查下一台产品" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [operationInstructionAlertView show];
    [operationInstructionAlertView release];
}


- (IBAction)deviceModeConfigSwitch {
    tempProcessProgress = processProgress;
    processProgress = 50;
    if(self.displayDeviceModeConfigSwitch.on){
        const UInt8 deviceModeConfigOnCmd[] = {0xf0,0x00,0x20,0x2b,0x69,0x06,0x01,0xf7};//refresh serialnumber
        [midi sendBytes:deviceModeConfigOnCmd size:sizeof(deviceModeConfigOnCmd)];
    }else{
        const UInt8 deviceModeConfigOffCmd[] = {0xf0,0x00,0x20,0x2b,0x69,0x06,0x00,0xf7};//refresh serialnumber
        [midi sendBytes:deviceModeConfigOffCmd size:sizeof(deviceModeConfigOffCmd)];
    }
}


- (void)alertView:(UIAlertView *)theAlertView
clickedButtonAtIndex:(NSInteger)buttonIndex
{
//    UInt16 i;
//    printf("%d",buttonIndex);
    if(theAlertView == updateFirmwareAlertView){
        if(buttonIndex == 0){
//        UInt8 updateFirmwareData[] = {0xf0,0x00,0x20,0x2b,0x69,0x05,0x20,0xf7};
            memset(updateErrorCode,0,5);
//            for(i = 0;i<40000;i++){
//                updateFirmwareData[i] = (UInt8)i;
//            }
            //only for testing data
            UInt8 updateFirmwareReq[] = {0xf0,0x00,0x20,0x2b,0x69,0x31,0x01,0x00,0x01,0x01,0x02,0x00,0x09,0x01,0x08,((sizeof(updateFirmwareData)/16)%10000/1000),((sizeof(updateFirmwareData)/16)%1000/100),((sizeof(updateFirmwareData)/16)%100/10),((sizeof(updateFirmwareData)/16)%10),0xf7};
            [midi sendBytes:updateFirmwareReq size:sizeof(updateFirmwareReq)];
        
//            while(!updateFirmwareReqResponded);
//            updateFirmwareReqResponded = NO;
//            serialNumberConfig.text = @"Responded";
//            if(!updateFirmwareAllowed){
//                [serialNumberConfig.text stringByAppendingString:@"not allowed"];
//            }
//            while(1);
//            updateFirmwareFlag = YES;
            updateFirmwareReqResponded = NO;
            updateFirmwareAllowed = NO;
            updateFirmwareAckReceived = YES;
            updateFirmwarePacketAckNoError = YES;
            updateFirmwareInProgress = YES;
            updateFirmwareReadPointer = 0;
            updateFirmwareWritePointer = 0;
            numberOfBytesUpdated = 0;
            statusProgress = 99;
//            updateTimer = [NSTimer scheduledTimerWithTimeInterval: 0.001	//can only in (ms) class! too slow!!
//                                                         target: self
//                                                       selector: @selector(handleUpdateTimer)
//                                                       userInfo: nil
//                                                        repeats: YES];
            displayUpdateProgress.hidden = NO;
            }
    }
    if(theAlertView == resetSerialNumberAlertView){
        if(buttonIndex == 0){
            serialNumberConfig.text = @"000001";
//          serialNumberToWrite = 1;
        }
    }
    if((theAlertView == serialNumberSetAlertView)||(theAlertView == serialNumberSetAlertView1)){
        if(buttonIndex == 0){
            serialNumberToWrite = (UInt32)[[serialNumberConfig text] intValue];
                        yearOfDateString = (UInt8)[[yearOfDateText text] intValue];
            monthOfDateString = (UInt8)[[monthOfDateText text] intValue];
            dayOfDateString = (UInt8)[[dayOfDateText text] intValue];
            UInt8 serialNumberCommand[] = {0xf0,0x00,0x20,0x2b,0x69,0x30,0x01,0x08,0x00,0x43,0x55,0x42,0x45,0x41,0x54,0x00,0x00,(UInt8)(serialNumberToWrite%1000000/100000),(UInt8)(serialNumberToWrite%100000/10000),(UInt8)(serialNumberToWrite%10000/1000),(UInt8)(serialNumberToWrite%1000/100),(UInt8)(serialNumberToWrite%100/10),(UInt8)(serialNumberToWrite%10),(UInt8)(yearOfDateString/10),(UInt8)(yearOfDateString%10),(UInt8)(monthOfDateString/10),(UInt8)(monthOfDateString%10),(UInt8)(dayOfDateString/10),(UInt8)(dayOfDateString%10),0xf7};
            [midi sendBytes:serialNumberCommand size:sizeof(serialNumberCommand)];
//            countLabel.text = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x", serialNumberCommand[17],serialNumberCommand[18],serialNumberCommand[19],serialNumberCommand[20],serialNumberCommand[21],serialNumberCommand[22]];

            serialNumberToWrite++;
            if(serialNumberToWrite>=1000000){
                serialNumberToWrite = 1;
            }
            serialNumberConfig.text = [NSString stringWithFormat:@"%06ld",serialNumberToWrite];
            if(statusProgress>2){
            const UInt8 selfcheckreq111[] = {0xf0,0x00,0x20,0x2b,0x69,0x01,0xf7};//refresh serialnumber
            [midi sendBytes:selfcheckreq111 size:sizeof(selfcheckreq111)];
                serialNumberSetForOneProduct = YES;
            }
        }
    }
}

/*
- (void) handleUpdateTimer{
    if(updateFirmwareInProgress){
        //[self performSelectorInBackground:@selector(sendUpdateData) withObject:nil];
        //[self performSelectorOnMainThread:@selector(refreshUpdateProgress) withObject:nil waitUntilDone:NO];
        [self sendUpdateData];
        [self refreshUpdateProgress];
    }else{
        [updateTimer invalidate];
        updateTimer= nil;
        numberOfBytesUpdated = 0;
        updateFirmwareReadPointer = 0;
        updateFirmwareWritePointer = 0;
        UIAlertView *updateFirmwareFinishedAlertView = [[UIAlertView alloc]initWithTitle:@"更新完成" message:@"更新成功！"delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [updateFirmwareFinishedAlertView show];
        [updateFirmwareFinishedAlertView release];
    }
}

*/
- (void) refreshUpdateProgress{
    
    if(timecount++ >= 50){
        timecount = 0;
        displayUpdateProgress.value =((float)numberOfBytesUpdated*100/(float)sizeof(updateFirmwareData));
    }
}


- (void) sendUpdateData{
    UInt16 i;
    UInt8 checksum;
//    UInt8 updateFirmwareCmdSend[48];// = {0xf0,0x00,0x20,0x2b,0x69,0x32};
//    if(updateFirmwareReqResponded && updateFirmwareAllowed)
    {
//        yearOfDateText.text = @"aa";
//        if(updateFirmwareAckReceived && updateFirmwarePacketAckNoError)
        {
            monthOfDateText.text = [NSString stringWithFormat: @"%02ld",(numberOfBytesUpdated/16) ];
            updateFirmwareCmdSend[0] = 0xf0;
            updateFirmwareCmdSend[1] = 0x00;
            updateFirmwareCmdSend[2] = 0x20;
            updateFirmwareCmdSend[3] = 0x2b;
            updateFirmwareCmdSend[4] = 0x69;
            updateFirmwareCmdSend[5] = 0x32;
            updateFirmwareCmdSend[40] = 0xf7;
            if(updateFirmwareReadPointer<(sizeof(updateFirmwareData))){
                checksum = 0;
                for(i = 0; i< 32; i+= 2){//16 Byte firmware data for every 64 Byte packet
                    updateFirmwareCmdSend[6+i] = (updateFirmwareData[updateFirmwareReadPointer]&0xf0)>>4;
                    updateFirmwareCmdSend[7+i] = (updateFirmwareData[updateFirmwareReadPointer++])&0x0f;
                    checksum += updateFirmwareCmdSend[6+i];
                    checksum += updateFirmwareCmdSend[7+i];
                }
                updateFirmwareCmdSend[38] = (checksum & 0xf0)>>4;
                updateFirmwareCmdSend[39] = (checksum & 0x0f);
                [midi sendBytes:updateFirmwareCmdSend size:48];//48 Byte for every 64 Byte packet
//                updateFirmwareWritePointer += 16;//16 effective Byte for every packet
                numberOfBytesUpdated += 16;
//                NSLog([NSString stringWithFormat:@"%02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x", updateFirmwareCmdSend[0],updateFirmwareCmdSend[1],updateFirmwareCmdSend[2],updateFirmwareCmdSend[3],updateFirmwareCmdSend[4],updateFirmwareCmdSend[5],updateFirmwareCmdSend[6],updateFirmwareCmdSend[7],updateFirmwareCmdSend[8],updateFirmwareCmdSend[9],updateFirmwareCmdSend[10],updateFirmwareCmdSend[11],updateFirmwareCmdSend[12],updateFirmwareCmdSend[13],updateFirmwareCmdSend[14],updateFirmwareCmdSend[15]]);
                serialNumberConfig.text  = [NSString stringWithFormat:@"%02x %02x %02x %02x %02x", updateFirmwareCmdSend[0],updateFirmwareCmdSend[1],updateFirmwareCmdSend[2],updateFirmwareCmdSend[3],updateFirmwareCmdSend[4]];
//              while(!updateFirmwareAckReceived);
                updateFirmwareAckReceived = NO;
                updateFirmwarePacketAckNoError = NO;
            }else{
                updateFirmwareInProgress = NO;
                displayUpdateProgress.hidden = YES;
                if(updateFirmwareAckReceived == NO){
                    updateErrorCode[0] = 1;
                }
                if(updateFirmwarePacketAckNoError == NO){
                    updateErrorCode[1] = 1;
                }
                statusProgress = 0;
                numberOfBytesUpdated = 0;
                updateFirmwareReadPointer = 0;
                updateFirmwareWritePointer = 0;
                UIAlertView *updateFirmwareFinishedAlertView = [[UIAlertView alloc]initWithTitle:@"更新完成" message:@"更新成功！"delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
                [updateFirmwareFinishedAlertView show];
                [updateFirmwareFinishedAlertView release];
            }
        }
//        else {
//            [NSThread sleepForTimeInterval:0.001];
//            [midi sendBytes:updateFirmwareCmdSend size:48];
//        }
    }
}

- (IBAction) sendMidiData
{
    nextStepButtonPressed = YES;
    if(statusProgress == 4){
        for(jj = 0; jj < 15; jj++){
            [self performSelectorInBackground:@selector(sendMidiDataInBackground) withObject:nil];
            [NSThread sleepForTimeInterval:voiceInterval];
        }
    }else{
        [self performSelectorInBackground:@selector(sendMidiDataInBackground) withObject:nil];
    }
}

#pragma mark Shenanigans

- (void) attachToAllExistingSources
{
    for (PGMidiSource *source in midi.sources)
    {
        source.delegate = self;
    }
}

- (void) setMidi:(PGMidi*)m
{
    midi.delegate = nil;
    midi = m;
    midi.delegate = self;

    [self attachToAllExistingSources];
    statusProgress = 0;
}

- (void) addString:(NSString*)string
{
//    NSString *newText = [textView.text stringByAppendingFormat:@"\n%@", string];
//    textView.text = newText;

//    if (newText.length)
//        [textView scrollRangeToVisible:(NSRange){newText.length-1, 1}];
    for(UInt8 ii = 0; ii < 9; ii++){
        switch(ii){
            case 0:
            {
                if(noteOnReceived[ii]){
                    if(hihatCloseNoteOnReceived){                        
                        AudioServicesPlaySystemSound (soundFileObject8);
                        _displayDeviceModeConfigSwitch.on = NO;
                    }else{
                        AudioServicesPlaySystemSound (soundFileObject0);
                        _displayDeviceModeConfigSwitch.on = NO;
                    }
                    if(statusProgress==5){
                        if(hihatCloseNoteOnReceived){
                            displayDrumPad0.text = [NSString stringWithFormat:@"Hi-Hat Close:%u",deviceVelocity[ii]];
                            hihatCloseNoteOnReceived = NO;
                        }else{
                            displayDrumPad0.Text = [NSString stringWithFormat:@"Hi-Hat Open:%u",deviceVelocity[ii]];
                        }
                        displayDrumPad0.highlighted = YES;
                    }
                    noteOnReceived[ii] = NO;
                }
                if(noteOffReceived[ii]){
                    if(hihatCloseNoteOffReceived){
                        hihatCloseNoteOffReceived = NO;
                    }
                        displayDrumPad0.highlighted = NO;
//                      noteOffReceived[ii] = NO;
                }
                if (deviceNoteReachedMax[ii] && deviceNoteReachedMiddle[ii]) {
                    if(statusProgress==5){
                        displayDrumPad0.backgroundColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
                    }
                }
                break;
            }
            case 1:
            {
                if(noteOnReceived[ii]){
                    AudioServicesPlaySystemSound (soundFileObject1);
                    _displayDeviceModeConfigSwitch.on = NO;
                    if(statusProgress==5){
                        displayDrumPad1.Text = [NSString stringWithFormat:@"Tom 2:%u",deviceVelocity[ii]];
                        displayDrumPad1.highlighted = YES;
                    }
                    noteOnReceived[ii] = NO;
                }
                if(noteOffReceived[ii]){
                    displayDrumPad1.highlighted = NO;
//                   noteOffReceived[ii] = NO;
                }
                if (deviceNoteReachedMax[ii] && deviceNoteReachedMiddle[ii]) {
                    if(statusProgress==5){
                        displayDrumPad1.backgroundColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
                    }
                }
                break;
            }
            case 2:
            {
                if(noteOnReceived[ii]){
                    AudioServicesPlaySystemSound (soundFileObject2);
                    _displayDeviceModeConfigSwitch.on = NO;
                    if(statusProgress==5){
                        displayDrumPad2.Text = [NSString stringWithFormat:@"Crash 1:%u",deviceVelocity[ii]];
                        displayDrumPad2.highlighted = YES;
                    }
                    noteOnReceived[ii] = NO;                    
                }
                if(noteOffReceived[ii]){
                    displayDrumPad2.highlighted = NO;
//                  noteOffReceived[ii] = NO;
                }
                if (deviceNoteReachedMax[ii] && deviceNoteReachedMiddle[ii]) {
                    if(statusProgress==5){
                        displayDrumPad2.backgroundColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
                    }
                }
                break;
            }
            case 3:
            {
                if(noteOnReceived[ii]){
                    AudioServicesPlaySystemSound (soundFileObject3);
                    _displayDeviceModeConfigSwitch.on = NO;
                    if(statusProgress==5){
                        displayDrumPad3.Text = [NSString stringWithFormat:@"Snare:%u",deviceVelocity[ii]];
                        displayDrumPad3.highlighted = YES;
                    }
                    noteOnReceived[ii] = NO;                    
                }
                if(noteOffReceived[ii]){
                    displayDrumPad3.highlighted = NO;
//                  noteOffReceived[ii] = NO;
                }
                if (deviceNoteReachedMax[ii] && deviceNoteReachedMiddle[ii]) {
                    if(statusProgress==5){
                        displayDrumPad3.backgroundColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
                    }
                }
                break;
            }
            case 4:
            {
                if(noteOnReceived[ii]){
                    AudioServicesPlaySystemSound (soundFileObject4);
                    _displayDeviceModeConfigSwitch.on = NO;
                    if(statusProgress==5){
                        displayDrumPad4.Text = [NSString stringWithFormat:@"Tom 1:%u",deviceVelocity[ii]];
                        displayDrumPad4.highlighted = YES;
                    }
                    noteOnReceived[ii] = NO;                    
                }
                if(noteOffReceived[ii]){
                    displayDrumPad4.highlighted = NO;
//                  noteOffReceived[ii] = NO;
                }
                if (deviceNoteReachedMax[ii] && deviceNoteReachedMiddle[ii]) {
                    if(statusProgress==5){
                        displayDrumPad4.backgroundColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
                    }
                }
                break;
            }
            case 5:
            {
                if(noteOnReceived[ii]){
                    AudioServicesPlaySystemSound (soundFileObject5);
                    _displayDeviceModeConfigSwitch.on = NO;
                    if(statusProgress==5){
                        displayDrumPad5.Text = [NSString stringWithFormat:@"Ride:%u",deviceVelocity[ii]];
                        displayDrumPad5.highlighted = YES;
                    }
                    noteOnReceived[ii] = NO;
                }
                if(noteOffReceived[ii]){
                    displayDrumPad5.highlighted = NO;
//                  noteOffReceived[ii] = NO;
                }
                if (deviceNoteReachedMax[ii] && deviceNoteReachedMiddle[ii]) {
                    if(statusProgress==5){
                        displayDrumPad5.backgroundColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
                    }
                }
                break;
            }
            case 6:{
                if(noteOnReceived[ii]){
                    AudioServicesPlaySystemSound (soundFileObject6);
                    _displayDeviceModeConfigSwitch.on = NO;
                    if(statusProgress==5){
                        displayDrumPad6.Text = [NSString stringWithFormat:@"Hi-Hat Pedal:%u",deviceVelocity[ii]];
                        displayDrumPad6.highlighted = YES;
                    }
                    noteOnReceived[ii] = NO;
                }
                if(noteOffReceived[ii]){
                    displayDrumPad6.highlighted = NO;
//                  noteOffReceived[ii] = NO;
                }
                if (deviceNoteReachedMax[ii]) {//Kick Only send 0x7f,no need to judge deviceNoteReachedMiddle
                    if(statusProgress==5){
                        displayDrumPad6.backgroundColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
                    }
                }
                break;
            }
            case 7:{
                if(noteOnReceived[ii]){////HiHat Only send 0x7f,no need to judge deviceNoteReachedMiddle
                    AudioServicesPlaySystemSound (soundFileObject7);
                    _displayDeviceModeConfigSwitch.on = NO;
                    if(statusProgress==5){
                        displayDrumPad7.Text = [NSString stringWithFormat:@"Kick:%u",deviceVelocity[ii]];
                        displayDrumPad7.highlighted = YES;}
                    noteOnReceived[ii] = NO;
                }
                if(noteOffReceived[ii]){
                    displayDrumPad7.highlighted = NO;
//                  noteOffReceived[ii] = NO;
                }
                if (deviceNoteReachedMax[ii]) {
                    if(statusProgress==5){
                        displayDrumPad7.backgroundColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
                    }
                }
                break;
            }
            case 8:{
                if(noteOnReceived[ii]){
                    AudioServicesPlaySystemSound (soundFileObject8);
//                  displayDrumPad8.Text = [NSString stringWithFormat:@":%u",deviceVelocity[ii]];
                    noteOnReceived[ii] = NO;
                    _displayDeviceModeConfigSwitch.on = NO;
                }
//              if (deviceNoteReachedMax[ii] && deviceNoteReachedMiddle[ii]) {
//                  displayDrumPad8.backgroundColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
//              }
                break;
            }
            default:
                break;
        }
    }
    
    countLabel.text = [NSString stringWithFormat: @"%02d:%02d", statusProgress,processProgress];
    switch(statusProgress){
        case 0:{
            displayDrumPad8.text = @"请敲击观察鼓盘";
            displayFirstStep.textColor = [UIColor blackColor];
            displaySecondStep.textColor = [UIColor blackColor];
            displayThirdStep.textColor = [UIColor blackColor];
            displayFourthStep.textColor = [UIColor blackColor];
            break;
        }
        case 1:
        {
            if(processProgress == 1)
            {
            displayDrumPad8.text = @"请进入第一步";
            displayFirstStep.textColor = [UIColor redColor];
            displaySecondStep.textColor = [UIColor blackColor];
            displayThirdStep.textColor = [UIColor blackColor];
            displayFourthStep.textColor = [UIColor blackColor];
            }
            break;
        }
        case 2:
        {
            if(processProgress == 2)
            {
                displayDrumPad8.text = @"请进入第一步..";
                displayFirstStep.textColor = [UIColor redColor];
                    displaySecondStep.textColor = [UIColor blackColor];
                displayThirdStep.textColor = [UIColor blackColor];
                displayFourthStep.textColor = [UIColor blackColor];
            }
            break;
        }
        case 3:
        {
//            while(processProgress != 3);
            
            {
                displayDeviceName.text = [NSString stringWithFormat:@"%c%c%c%c%c%c%c%c%c%c",deviceNameArray[0],deviceNameArray[1],deviceNameArray[2],deviceNameArray[3],deviceNameArray[4],deviceNameArray[5],deviceNameArray[6],deviceNameArray[7],deviceNameArray[8],deviceNameArray[9]];//deviceNameArray[0]deviceName;
                displayDeviceSerialNumber.text = [NSString stringWithFormat:@"%02x%02x%02x",deviceSerialNumber[0],deviceSerialNumber[1],deviceSerialNumber[2]];
                displayDeviceVersionNumber.text = [NSString stringWithFormat:@"%02d.%02d.%02d",deviceFirmwareVersion[0],deviceFirmwareVersion[1],deviceFirmwareVersion[2]];
                displayDeviceProductionDate.text = [NSString stringWithFormat:@"%02x年%02x月%02x日",deviceProductionDate[0],deviceProductionDate[1],deviceProductionDate[2]];
//                if(errorCode == 4){
//                    displayDrumPad8.text = @"接口错误，请正确插线";
//                }else{
                    displayDrumPad8.text = @"请进入第二步";
//                }
                displayFirstStep.textColor = [UIColor blackColor];
                displaySecondStep.textColor = [UIColor redColor];
                displayThirdStep.textColor = [UIColor blackColor];
                displayFourthStep.textColor = [UIColor blackColor];
            }
            break;
        }
        case 4:
        {
//            while(processProgress != 4);
            {
                displayDeviceName.text = [NSString stringWithFormat:@"%c%c%c%c%c%c%c%c%c%c",deviceNameArray[0],deviceNameArray[1],deviceNameArray[2],deviceNameArray[3],deviceNameArray[4],deviceNameArray[5],deviceNameArray[6],deviceNameArray[7],deviceNameArray[8],deviceNameArray[9]];//deviceNameArray[0]deviceName;
                displayDeviceSerialNumber.text = [NSString stringWithFormat:@"%02x%02x%02x",deviceSerialNumber[0],deviceSerialNumber[1],deviceSerialNumber[2]];
                displayDeviceVersionNumber.text = [NSString stringWithFormat:@"%02d.%02d.%02d",deviceFirmwareVersion[0],deviceFirmwareVersion[1],deviceFirmwareVersion[2]];
                displayDeviceProductionDate.text = [NSString stringWithFormat:@"%02x年%02x月%02x日",deviceProductionDate[0],deviceProductionDate[1],deviceProductionDate[2]];
                if(errorCode == 4){
                    displayDrumPad8.text = @"接口错误，请正确插线";
                }
//                else{
//                    displayDrumPad8.text = @"请进入第二步";
//                }
                displayFirstStep.textColor = [UIColor blackColor];
                displaySecondStep.textColor = [UIColor redColor];
                displayThirdStep.textColor = [UIColor blackColor];
                displayFourthStep.textColor = [UIColor blackColor];
            }
            
            {
            displayHeadphonePlugState.on = (BOOL)deviceHeadphoneState;
            displayKickPlugState.on = (BOOL)deviceKickState;
            displayHiHatPlugState.on = (BOOL)deviceHiHatState;
                if(deviceBatteryState > 10){
                    displayDeviceBatteryLevel.value = 0;
                }
                else{
                    displayDeviceBatteryLevel.value = deviceBatteryState;
                }
            if(!(deviceHeadphoneState && deviceKickState && deviceHiHatState)){
//                statusProgress = 3;
                errorCode = 4;//connector error
                displayDrumPad8.text = @"接口错误，请正确插线";
            }else{
//                errorCode = 0;
            }
            switch(devicePowerSupply)
            {
                case 0x00:
                    displayDevicePowerState.text = @"电池供电中";
                    break;
                case 0x01:
                    displayDevicePowerState.text = @"正常充电中";
                    break;
                case 0x02:
                    displayDevicePowerState.text = @"充电已完成";
                    break;
                case 0x7F:
                    displayDevicePowerState.text = @"未安装电池";
                    break;
                default:
                    errorCode = 5;//power error
                    break;
            }if(deviceBatteryState>10){
                [displayDevicePowerState.text stringByAppendingString:@":电池损坏"];
            }
            displayDrumPad8.text = @"请进入第三步";
            displayFirstStep.textColor = [UIColor blackColor];
            displaySecondStep.textColor = [UIColor blackColor];
            displayThirdStep.textColor = [UIColor redColor];
            displayFourthStep.textColor = [UIColor blackColor];
            break;
            }
        }
        case 5:
        {
            displayDeviceSerialNumber.text = [NSString stringWithFormat:@"%02x%02x%02x",deviceSerialNumber[0],deviceSerialNumber[1],deviceSerialNumber[2]];
            displayDeviceVersionNumber.text = [NSString stringWithFormat:@"%02d.%02d.%02d",deviceFirmwareVersion[0],deviceFirmwareVersion[1],deviceFirmwareVersion[2]];
            displayDeviceProductionDate.text = [NSString stringWithFormat:@"%02x年%02x月%02x日",deviceProductionDate[0],deviceProductionDate[1],deviceProductionDate[2]];
            
            deviceAllNotesReachedMax = YES;
            for(jj = 0; jj < 8; jj++){
                if(deviceNoteReachedMax[jj] == NO){
                    deviceAllNotesReachedMax = NO;
                }
            }
            if((deviceAllNotesReachedMax == YES)&&(statusProgress >= 5)){
                processProgress = 5;//test passed
                displayDrumPad8.backgroundColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
                displayDrumPad8.text = @"通过，请生成程序列号";
            }else{
                displayDrumPad8.text = @"敲击鼓盘至全亮绿色";
            }
            displayFirstStep.textColor = [UIColor blackColor];
            displaySecondStep.textColor = [UIColor blackColor];
            displayThirdStep.textColor = [UIColor blackColor];
            displayFourthStep.textColor = [UIColor redColor];
            break;
        }
        case 100:
//            displayDeviceSerialNumber.text = [NSString stringWithFormat:@"%02x%02x%02x",deviceSerialNumber[0],deviceSerialNumber[1],deviceSerialNumber[2]];
            displayDrumPad8.text = @"状态错误，请重检";
            break;
        default:
            
            break;
    }
    
}

- (void) updateCountLabel
{
    countLabel.text = [NSString stringWithFormat:@"输入：%u 输出：%u", midi.sources.count, midi.destinations.count];
}

- (void) midi:(PGMidi*)midi sourceAdded:(PGMidiSource *)source
{
    source.delegate = self;
    displayDrumPad8.text = [NSString stringWithFormat:@"设备已连接:%@",(source.name)];
    [self updateCountLabel];
    [self addString:[NSString stringWithFormat:@"输入已增加：%@", ToString(source)]];
    testVoiceNumber = RandomNoteNumber();
//    serialNumberConfig.text = [NSString stringWithFormat:@"%06d", serialNumberToWrite];
    [self performSelectorInBackground:@selector(sendMidiDataInBackground) withObject:nil];
}

- (void) midi:(PGMidi*)midi sourceRemoved:(PGMidiSource *)source
{
    [self updateCountLabel];
//    [self addString:[NSString stringWithFormat:@"输入已移除：%@", ToString(source)]];
//    [self addString:@""];
//    if (toneUnit){
//        AudioOutputUnitStop(toneUnit);
//        AudioUnitUninitialize(toneUnit);
//        AudioComponentInstanceDispose(toneUnit);
//    }
//    toneUnit = nil;
//    textView.text = nil;
    displayDeviceName.text = nil;
    displayDeviceProductionDate.text = nil;
    displayDeviceSerialNumber.text = nil;
    displayDeviceVersionNumber.text = nil;
    displayHeadphonePlugState.on = NO;
    displayKickPlugState.on = NO;
    displayHiHatPlugState.on = NO;
    displayDeviceBatteryLevel.value = 0;
    displayVoiceLevel.value = 0;
    deviceAllNotesReachedMax = NO;
    displayDevicePowerState.text = @"电池状态";
    displayDrumPad0.text = [NSString stringWithFormat:@"Hi-Hat Open"];
    displayDrumPad0.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
    displayDrumPad1.text = [NSString stringWithFormat:@"Tom 2"];
    displayDrumPad1.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
    displayDrumPad2.text = @"Crash 1";
    displayDrumPad2.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
    displayDrumPad3.text = @"Snare";
    displayDrumPad3.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
    displayDrumPad4.text = @"Tom 1";
    displayDrumPad4.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
    displayDrumPad5.text = @"Ride";
    displayDrumPad5.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
    displayDrumPad6.text = @"Hi-Hat Pedal";
    displayDrumPad6.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
    displayDrumPad7.text = @"Kick";
    displayDrumPad7.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
    displayDrumPad8.text = @"请连接设备";
    displayDrumPad8.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
    displayFirstStep.textColor = [UIColor blackColor];
    displaySecondStep.textColor = [UIColor blackColor];
    displayThirdStep.textColor = [UIColor blackColor];
    displayFourthStep.textColor = [UIColor blackColor];
    //displayDrumPad0.highlighted = YES;
    memset(deviceNameArray, 0, 10);
    memset(deviceFirmwareVersion,0,3);
    memset(deviceProductionDate,0,3);
    memset(deviceSerialNumber,0,3);
    memset(deviceVelocity,0,9);
    memset(noteOnReceived,0,9);
    memset(noteOffReceived,0,9);
    memset(deviceNoteReachedMax,0,9);
    memset(deviceNoteReachedMiddle,0,9);
    deviceVolume = 0;
    devicePowerMode = 0;
    devicePowerSupply = 0;
    deviceKickState = 0;
    deviceHiHatState = 0;
    deviceBatteryState = 0;
    deviceHeadphoneState = 0;
    
    hihatCloseNoteOnReceived = NO;
    hihatCloseNoteOffReceived = NO;

    ledStatus = NO;
    statusProgress = 0;
    processProgress = 0;
    enterStepFiveForTheFirstTime = YES;
    serialNumberSetForOneProduct = NO;
    deviceAttached = NO;
    selfCheckRequestResponded = NO;
    errorCode = 0;
    ledControlButton.hidden = NO;
    ledControlButton1.hidden = YES;
//    serialNumberButton.enabled = NO;
}

- (void) midi:(PGMidi*)midi destinationAdded:(PGMidiDestination *)destination
{
    [self updateCountLabel];
    [self addString:[NSString stringWithFormat:@"输出已增加：%@", ToString(destination)]];
}

- (void) midi:(PGMidi*)midi destinationRemoved:(PGMidiDestination *)destination
{
    [self updateCountLabel];
    [self addString:[NSString stringWithFormat:@"输出已移除：%@", ToString(destination)]];
}

NSString *StringFromPacket(const MIDIPacket *packet)
{
    // Note - this is not an example of MIDI parsing. I'm just dumping
    // some bytes for diagnostics.
    // See comments in PGMidiSourceDelegate for an example of how to
    // interpret the MIDIPacket structure.
    if((packet->data[0] == 0xF0)&&(packet->data[1] == 0x00)&&(packet->data[2] == 0x20)&&(packet->data[3] == 0x2b)&&(packet->data[4] == 0x69)){
        rcvcmd = packet->data[5];
        switch (rcvcmd) {
            case 0x40://Device Identity Query
            {
                if((packet->data[6] == 0x61)&&((packet->data[7] == 0x33))){
                    deviceAttached = YES;
                    statusProgress = 1;
                    processProgress = 1;
                }
                break;
            }
            case 0x41://Device Statics Query
            {
//              if(deviceAttached == NO) break;
                deviceNameLength = packet->data[9];
                int readIndex = 10;
                for(int i1 = 0; i1 < deviceNameLength; i1++){
                deviceNameArray[i1] = packet->data[readIndex+i1];
//              NSString *tempDeviceName = [NSString stringWithFormat:@"%c",packet->data[10+i1]];//
//              [deviceName stringByAppendingString:tempDeviceName];//= [NSString stringWithFormat:@"%@%@",deviceName,tempDeviceName];
                }
                readIndex += deviceNameLength; 
                for(int i2 = 0; i2 < 3; i2++){
                    deviceFirmwareVersion[i2] = packet->data[readIndex+i2];
                }
                readIndex += 3;
                for(int i3 = 0 ; i3 < 3; i3 ++){
                    deviceProductionDate[i3] = (UInt8)((packet->data[readIndex+i3*2]&0x0F)<<4)|(packet->data[readIndex+i3*2+1]&0x0F);
                }
                readIndex += 6;
                for(int i4 = 0 ; i4 < 3; i4 ++){
                    deviceSerialNumber[i4] = (UInt8)((packet->data[readIndex+i4*2]&0x0F)<<4)|(packet->data[readIndex+i4*2+1]&0x0F);
                }
                readIndex ++;
                devicePowerMode = packet->data[readIndex];
                if(statusProgress<5){
                    processProgress = 2;
                }
                break;
            }
            case 0x42://Device Configuration Query, not done yet
            {
                break;
            }
            case 0x43://Device Activity Query
            {
                devicePowerSupply = packet->data[6];
                deviceBatteryState = packet->data[7];
                deviceHeadphoneState = packet->data[8];
                deviceKickState = packet->data[9];
                deviceHiHatState = packet->data[10];
                if(!(deviceHeadphoneState && deviceKickState && deviceHiHatState)){
//                    statusProgress = 3;
                    errorCode = 4;
                }else{
                    errorCode = 0;
                }
                processProgress = 3;
                break;
            }
            case 0x44://Device LED Mode Config
            {
                break;
            }
            case 0x46://Device Mode Config(ERP Mode)
            {
                //processProgress = tempProcessProgress;
                break;
            }
            case 0x70://Device Serial Number Config
            {
                break;
            }
            case 0x71://Device Firmware Update Request
            {
                updateFirmwareReqResponded = YES;
                updateFirmwareAllowed = packet->data[6];
                break;
            }
            case 0x72://Device Firmware Date Download
            {
                updateFirmwareAckReceived = YES;
                updateFirmwarePacketAckNoError = packet->data[6];
                break;
            }
            case 0x73://Device Firmware Update Finish
            {
                updateFirmwareFinished = YES;
                break;
            }
            case 0x74://self-check request response
            {
                selfCheckRequestResponded = YES;
                break;
            }
            case 0x75://self-check exit request response
            {
                break;
            }
            default:
                break;
        }
    }
    if(packet->data[0]==0x99){
            {
                deviceNote = packet->data[1];
                switch(deviceNote){
                    case 0x2E:
                    {
                        if(packet->data[2] == 0x00){
                            noteOffReceived[0] = YES;
                        }else{
                            noteOnReceived[0] = YES;
                            deviceVelocity[0] = packet->data[2];                        
                            if(deviceVelocity[0]==0x7f){
                                deviceNoteReachedMax[0] = YES;
                            }else{
                                deviceNoteReachedMiddle[0] = YES;
                            }
                        }
                        break;
                    }
                    case 0x2D:
                    {
                        if(packet->data[2] == 0x00){
                            noteOffReceived[1] = YES;
                        }else{
                            noteOnReceived[1] = YES;
                            deviceVelocity[1] = packet->data[2];
                            if(deviceVelocity[1]==0x7f){
                                deviceNoteReachedMax[1] = YES;
                            }else{
                                deviceNoteReachedMiddle[1] = YES;
                            }
                        }
                        break;
                    }
                    case 0x31:
                    {
                        if(packet->data[2] == 0x00){
                            noteOffReceived[2] = YES;
                        }else{
                            noteOnReceived[2] = YES;
                            deviceVelocity[2] = packet->data[2];
                            if(deviceVelocity[2]==0x7f){
                                deviceNoteReachedMax[2] = YES;
                            }else{
                                deviceNoteReachedMiddle[2] = YES;
                            }
                        }
                        break;
                    }
                    case 0x26:
                    {   
                        if(packet->data[2] == 0x00){
                            noteOffReceived[3] = YES;
                        }else{
                            noteOnReceived[3] = YES;
                            deviceVelocity[3] = packet->data[2];
                            if(deviceVelocity[3]==0x7f){
                                deviceNoteReachedMax[3] = YES;
                            }else{
                                deviceNoteReachedMiddle[3] = YES;
                            }
                        }
                        break;
                    }
                    case 0x30:
                    {
                        if(packet->data[2] == 0x00){
                            noteOffReceived[4] = YES;
                        }else{
                            noteOnReceived[4] = YES;
                            deviceVelocity[4] = packet->data[2];
                            if(deviceVelocity[4]==0x7f){
                                deviceNoteReachedMax[4] = YES;
                            }else{
                                deviceNoteReachedMiddle[4] = YES;
                            }
                        }
                        break;
                    }
                    case 0x33:
                    {
                        if(packet->data[2] == 0x00){
                            noteOffReceived[5] = YES;
                        }else{
                            noteOnReceived[5] = YES;
                            deviceVelocity[5] = packet->data[2];
                            if(deviceVelocity[5]==0x7f){
                                deviceNoteReachedMax[5] = YES;
                            }else{
                                deviceNoteReachedMiddle[5] = YES;
                            }
                        }
                        break;
                    }
                    case 0x2C:
                    {
                        if(packet->data[2] == 0x00){
                            noteOffReceived[6] = YES;
                        }else{
                            noteOnReceived[6] = YES;
                            deviceVelocity[6] = packet->data[2];
 //                           if(deviceVelocity[6]==0x7f){
                                deviceNoteReachedMax[6] = YES;
 //                           }else{
                                deviceNoteReachedMiddle[6] = YES;
 //                           }
                        }
                        break;
                    }
                    case 0x24:
                    {
                        if(packet->data[2] == 0x00){
                            noteOffReceived[7] = YES;
                        }else{
                            noteOnReceived[7] = YES;
                            deviceVelocity[7] = packet->data[2];
//                            if(deviceVelocity[7]==0x7f){
                                deviceNoteReachedMax[7] = YES;
//                              }else{
                                    deviceNoteReachedMiddle[7] = YES;
//                            }
                        }
                        break;
                    }
                    case 0x2A:
                    {
                        if(packet->data[2] == 0x00){
                            noteOffReceived[0] = YES;
                            hihatCloseNoteOffReceived = YES;
                        }else{
                            noteOnReceived[0] = YES;
                            hihatCloseNoteOnReceived = YES;
                            deviceVelocity[0] = packet->data[2];
                            if(deviceVelocity[0]==0x7f){
                                deviceNoteReachedMax[0] = YES;
                            }else{
                                deviceNoteReachedMiddle[0] = YES;
                            }
                        }
                        break;
                    }
                    default:
                        break;
                }
            }
    }
    return [NSString stringWithFormat:@""];
    /*return [NSString stringWithFormat:@"%u个字节:[%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x]",
            packet->length,
            (packet->length > 0) ? packet->data[0] : 0,
            (packet->length > 1) ? packet->data[1] : 0,
            (packet->length > 2) ? packet->data[2] : 0,
            (packet->length > 3) ? packet->data[3] : 0,
            (packet->length > 4) ? packet->data[4] : 0,
            (packet->length > 5) ? packet->data[5] : 0,
            (packet->length > 6) ? packet->data[6] : 0,
            (packet->length > 7) ? packet->data[7] : 0,
            (packet->length > 8) ? packet->data[8] : 0,
            (packet->length > 9) ? packet->data[9] : 0,
            (packet->length > 10) ? packet->data[10] : 0,
            (packet->length > 11) ? packet->data[11] : 0,
            (packet->length > 12) ? packet->data[12] : 0,
            (packet->length > 13) ? packet->data[13] : 0,
            (packet->length > 14) ? packet->data[14] : 0,
            (packet->length > 15) ? packet->data[15] : 0
    ];*/
}

- (void) midiSource:(PGMidiSource*)midi midiReceived:(const MIDIPacketList *)packetList
{
    [self performSelectorOnMainThread:@selector(addString:)
                           withObject:nil//@"MIDI接收:"
                        waitUntilDone:NO];
    const MIDIPacket *packet = &packetList->packet[0];
    for (int i = 0; i < packetList->numPackets; ++i)
    {
        [self performSelectorOnMainThread:@selector(addString:)
                               withObject:StringFromPacket(packet)
                            waitUntilDone:NO];
        packet = MIDIPacketNext(packet);
    }
/*    allNotesOffReceived = NO;
    for(UInt8 kk = 0; kk < 9; kk++){
        if(noteOffReceived[kk]){
            noteOffReceived[kk] = NO;
            allNotesOffReceived = YES;
        }
        if(allNotesOffReceived){
            break;
        }
    }*/
            if((statusProgress == 4)&&(processProgress == 3)){
//                for(jj = 0; jj < 16; jj++)
                while(statusProgress == 4)
                {
                    [self performSelectorInBackground:@selector(sendMidiDataInBackground) withObject:nil];
                    [NSThread sleepForTimeInterval:voiceInterval];
                }
                processProgress = 4;
//                [self performSelectorInBackground:@selector(sendMidiDataInBackground) withObject:nil];
                displayDrumPad8.text = @"请进入第四步";
                [self performSelectorOnMainThread:@selector(addString:)
                                       withObject:nil//@"MIDI接收:"
                                    waitUntilDone:NO];
            }else{
                [self performSelectorInBackground:@selector(sendMidiDataInBackground) withObject:nil];
                [NSThread sleepForTimeInterval:0.001];
            }
}

- (void) sendLedControlMidiInBackground
{
    UInt8 LedIndex;
    switch(ledStatus){
        case YES:{
            UInt8 midiOut0[] = {0xf0,0x00,0x20,0x2b,0x69,0x04,0x01,0xf7};
            [midi sendBytes:midiOut0 size:sizeof(midiOut0)];
            [NSThread sleepForTimeInterval:0.03];
            for(LedIndex = 0;LedIndex < 9; LedIndex++){
                UInt8 midiOut00[] = {0xA0,LedIndex,0x6E};
                [midi sendBytes:midiOut00 size:sizeof(midiOut00)];
                [NSThread sleepForTimeInterval:0.02];
            }
            UInt8 midiOut1 []={0xf0,0x00,0x20,0x2b,0x69,0x04,0x00,0xf7};
            [midi sendBytes:midiOut1 size:sizeof(midiOut1)];
            break;
        }
        case NO:{
            UInt8 midiOut0[] = {0xf0,0x00,0x20,0x2b,0x69,0x04,0x01,0xf7};
            [midi sendBytes:midiOut0 size:sizeof(midiOut0)];
            [NSThread sleepForTimeInterval:0.03];
            for(LedIndex = 0; LedIndex < 9; LedIndex++){
                UInt8 midiOut11[] = {0xA0,LedIndex,0x00};
                [midi sendBytes:midiOut11 size:sizeof(midiOut11)];
                [NSThread sleepForTimeInterval:0.02];
            }
            UInt8 midiOut1 []={0xf0,0x00,0x20,0x2b,0x69,0x04,0x00,0xf7};
                [midi sendBytes:midiOut1 size:sizeof(midiOut1)];
        }
            break;
    }
}

- (void) sendMidiDataInBackground
{
//    for (int n = 0; n < 1; ++n)
//    {
//        const UInt8 note      = RandomNoteNumber();
//        const UInt8 noteOn[]  = { 0x90, note, 127 };
//        const UInt8 noteOff[] = { 0x80, note, 0   };

//        [midi sendBytes:noteOn size:sizeof(noteOn)];
//        [NSThread sleepForTimeInterval:0.1];
//        [midi sendBytes:noteOff size:sizeof(noteOff)];
//}
        switch (statusProgress) {
            case 0:
            {
                
                const UInt8 sendcmd0 = 0x00;
                const UInt8 selfcheckreq0[] = {0xf0,0x00,0x20,0x2b,0x69,sendcmd0,0x12,0x79,0xf7};
                [midi sendBytes:selfcheckreq0 size:sizeof(selfcheckreq0)];
//                [self performSelectorOnMainThread:@selector(addString:)
//                                       withObject:nil//[NSString stringWithFormat:@"MIDI发送:[%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x]",selfcheckreq0[0],selfcheckreq0[1],selfcheckreq0[2],selfcheckreq0[3],selfcheckreq0[4],selfcheckreq0[5],selfcheckreq0[6],selfcheckreq0[7],selfcheckreq0[8]]
//                                    waitUntilDone:NO];
                statusProgress = 1;
                break;
            }
            case 1:
            {
                allNotesOffReceived = NO;
                for(UInt8 kk = 0; kk < 8; kk++){
                    if(noteOffReceived[kk]){
                        noteOffReceived[kk] = NO;
                        allNotesOffReceived = YES;
                    }
                }
                if(!allNotesOffReceived){
                    if(nextStepButtonPressed){
                        nextStepButtonPressed = NO;
                    }else{
                        break;
                    }
                }
                const UInt8 sendcmd00 = 0x34;
                const UInt8 selfcheckreq00[] = {0xf0,0x00,0x20,0x2b,0x69,sendcmd00,0xf7};
                [midi sendBytes:selfcheckreq00 size:sizeof(selfcheckreq00)];
//                [self performSelectorOnMainThread:@selector(addString:)
//                                       withObject:nil//[NSString stringWithFormat:@"MIDI发送:[%02x,%02x,%02x,%02x,%02x,%02x,%02x]",selfcheckreq00[0],selfcheckreq00[1],selfcheckreq00[2],selfcheckreq00[3],selfcheckreq00[4],selfcheckreq00[5],selfcheckreq00[6]]
//                                    waitUntilDone:NO];
                if(processProgress < 2){
                    statusProgress = 2;
                }
                break;
            
            }
            case 2:
            {
/*                
                allNotesOffReceived = NO;
                for(UInt8 kk = 0; kk < 8; kk++){
                    if(noteOffReceived[kk]){
                        noteOffReceived[kk] = NO;
                        allNotesOffReceived = YES;
                    }
                }
                if(!allNotesOffReceived){
                    break;
                }
 */
                const UInt8 selfcheckreq1[] = {0xf0,0x00,0x20,0x2b,0x69,0x01,0xf7};
                [midi sendBytes:selfcheckreq1 size:sizeof(selfcheckreq1)];
//                [self performSelectorOnMainThread:@selector(addString:)
//                                       withObject:nil//[NSString stringWithFormat:@"MIDI发送:[%02x,%02x,%02x,%02x,%02x,%02x,%02x]",selfcheckreq1[0],selfcheckreq1[1],selfcheckreq1[2],selfcheckreq1[3],selfcheckreq1[4],selfcheckreq1[5],selfcheckreq1[6]]
//                                    waitUntilDone:NO];
//                [NSThread sleepForTimeInterval:0.2];
                if(processProgress < 3){
                    statusProgress = 3;
                }
                serialNumberButton.enabled = YES;
                break;
            }
            case 3:
            {
                allNotesOffReceived = NO;
                for(UInt8 kk = 0; kk < 8; kk++){
                    if(noteOffReceived[kk]){
                        noteOffReceived[kk] = NO;
                        allNotesOffReceived = YES;
                    }
                }
                if(!allNotesOffReceived){
                    if(nextStepButtonPressed){
                        nextStepButtonPressed = NO;
                    }else{
                        break;
                    }
                }
                const UInt8 selfcheckreq3[] = {0xf0,0x00,0x20,0x2b,0x69,0x03,0xf7};
                [midi sendBytes:selfcheckreq3 size:sizeof(selfcheckreq3)];
//                [self performSelectorOnMainThread:@selector(addString:)
//                                       withObject:nil//[NSString stringWithFormat:@"MIDI发送:[%02x,%02x,%02x,%02x,%02x,%02x,%02x]",selfcheckreq3[0],selfcheckreq3[1],selfcheckreq3[2],selfcheckreq3[3],selfcheckreq3[4],selfcheckreq3[5],selfcheckreq3[6]]
//                                    waitUntilDone:NO];
//                [NSThread sleepForTimeInterval:0.2];
//                if(processProgress >= 3){
                    if(errorCode == 4){//connector error
//                        statusProgress = 3;
                    }else{                        
                        if(processProgress<4){
                            statusProgress = 4;
                        }
                    }
//                }
//                [NSThread sleepForTimeInterval:0.1];
                
                voiceInterval = makeVoiceInterval.value;
                deviceVolume = 0;
                break;
            }
            case 4:
            {
//                if(deviceVolume==0){
//                    [self createToneUnit];
                    
                    // Stop changing parameters on the unit
//                    OSErr err = AudioUnitInitialize(toneUnit);
//                    NSAssert1(err == noErr, @"Error initializing unit: %ld", err);
                    
                    // Start playback
//                    err = AudioOutputUnitStart(toneUnit);
//                    NSAssert1(err == noErr, @"Error starting unit: %ld", err);
                    
//                }
                if(errorCode == 4){//connector error
                    statusProgress = 3;
                    break;
                }
                    if (deviceVolume >= 0x40){
                        displayVoiceLevel.value = 0x40;    
                        statusProgress = 5;
                        
//                        AudioOutputUnitStop(toneUnit);
//                        AudioUnitUninitialize(toneUnit);
//                        AudioComponentInstanceDispose(toneUnit);
//                        toneUnit = nil;
                    }else{                                            
/*                        if(deviceVolume <= 0x20){
                            muteLeftRight = 0x80;
                        }else{
                            muteLeftRight = 0x40;
                            //muteLeftRight = (muteLeftRight != 0x80) ? 0x80:0x40;
                        }
                        muteLeftRight = 0x40;
*/                      
                        displayVoiceLevel.value = deviceVolume;
                        UInt8 selfcheckreq4[] = {0xf0,0x00,0x20,0x2b,0x69,0x05,(UInt8)(deviceVolume|muteLeftRight),0xf7};
                            [midi sendBytes:selfcheckreq4 size:sizeof(selfcheckreq4)];
                        switch(testVoiceNumber){
/*                            
                            case 0:
                                AudioServicesPlaySystemSound (soundFileObject0);
                                break;
                            case 1:
                                AudioServicesPlaySystemSound (soundFileObject1);
                                break;
                            case 2:
                                AudioServicesPlaySystemSound (soundFileObject2);
                                break;
                            case 3:
                                AudioServicesPlaySystemSound (soundFileObject3);
                                break;
                            case 4:
                                AudioServicesPlaySystemSound (soundFileObject4);
                                break;
                            case 5:
                                AudioServicesPlaySystemSound (soundFileObject5);
                                break;
                            case 6:
                                AudioServicesPlaySystemSound (soundFileObject6);
                                break;
                            case 7:
                                AudioServicesPlaySystemSound (soundFileObject7);
                                break;
                            case 8:
                                AudioServicesPlaySystemSound (soundFileObject8);
                                break;
 */
                            default:
                            {
                                if(deviceVolume == 4){
                                    if(voiceInterval<0.23){
                                        AudioServicesPlaySystemSound (soundFileObject9);
                                    }else if(voiceInterval<0.38){
                                        AudioServicesPlaySystemSound(soundFileObject10);
                                    }else{
                                        AudioServicesPlaySystemSound(soundFileObject11);
                                    }
                                }
                                if(deviceVolume == 0x40){
                                    deviceVolume = 0x10;
                                    UInt8 selfcheckreq5[] = {0xf0,0x00,0x20,0x2b,0x69,0x05,(UInt8)deviceVolume,0xf7};
                                    
                                    [midi sendBytes:selfcheckreq5 size:sizeof(selfcheckreq5)];//resume to default volume 0x20
                                }
 
                                break;
                            }
                                
                        }
                        deviceVolume += 4;
                    }
                break;
            }
            case 5:
            {
                allNotesOffReceived = NO;
                for(UInt8 kk = 0; kk < 8; kk++){
                    if(noteOffReceived[kk]){
                        noteOffReceived[kk] = NO;
                        allNotesOffReceived = YES;
                    }
                }
                if(enterStepFiveForTheFirstTime){
                    enterStepFiveForTheFirstTime = NO;
                    deviceVolume = 0x20;
                    [NSThread sleepForTimeInterval:0.1];
                    UInt8 selfcheckreq6[] = {0xf0,0x00,0x20,0x2b,0x69,0x05,(UInt8)deviceVolume,0xf7};
                    
                [midi sendBytes:selfcheckreq6 size:sizeof(selfcheckreq6)];//resume to default volume 0x20
                    displayVoiceLevel.value = 0x20;
                }
                
                break;
            }
            case 100:
            {
                statusProgress = 0;
                break;
            }
            case 99:
            {
                [self sendUpdateData];
                [self refreshUpdateProgress];
                [NSThread sleepForTimeInterval:0.1];
                break;
            }
            case 50:
            {
                processProgress = tempProcessProgress;
                break;
            }
            default:
                break;
        }
}


//@synthesize playButton;

/*- (void)stop
{
	if (toneUnit)
	{
		[self togglePlay:playButton];
	}
}*/

- (void)viewDidLoad {
	[super viewDidLoad];
/*    
    //	[self sliderChanged:frequencySlider];
	sampleRate = 44100;
    
	OSStatus result = AudioSessionInitialize(NULL, NULL, ToneInterruptionListener, self);
	if (result == kAudioSessionNoError)
	{
		UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
		AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
	}
	AudioSessionSetActive(true); 
 */
//    dataArray = [NSArray arrayWithObjects:@"", @"", nil];
	
    yearFormatter = [[[NSDateFormatter alloc] init]autorelease];
    yearFormatter.dateFormat = @"YY";
    yearOfDateTimestamp = [yearFormatter stringFromDate:pickerView.date];
    yearOfDateText.text = [NSString stringWithFormat: @"%@",yearOfDateTimestamp];
    monthFormatter = [[[NSDateFormatter alloc] init]autorelease];
    monthFormatter.dateFormat = @"MM";
    monthOfDateTimestamp = [monthFormatter stringFromDate:pickerView.date];
    monthOfDateText.text = [NSString stringWithFormat: @"%@",monthOfDateTimestamp];
    dayFormatter = [[[NSDateFormatter alloc] init]autorelease];
    dayFormatter.dateFormat = @"dd";
    dayOfDateTimestamp = [dayFormatter stringFromDate:pickerView.date];
    dayOfDateText.text = [NSString stringWithFormat: @"%@",dayOfDateTimestamp];
//    serialNumberConfig.text = @"000001";
    
    // Create the URL for the source audio file. The URLForResource:withExtension: method is
    //    new in iOS 4.0.
    
    NSURL *HiHatOpenSound   = [[NSBundle mainBundle] URLForResource: @"HiHat_Open"
                                                withExtension: @"aif"];    
    // Store the URL as a CFURLRef instance
    self.soundFileURLRef0 = (CFURLRef) [HiHatOpenSound retain];
    
    // Create a system sound object representing the sound file.
    AudioServicesCreateSystemSoundID (
                                      soundFileURLRef0,
                                      &soundFileObject0
                                      );
    NSURL *TomLowSound   = [[NSBundle mainBundle] URLForResource: @"Tom1"
                                                  withExtension: @"aif"];    
    // Store the URL as a CFURLRef instance
    self.soundFileURLRef1 = (CFURLRef) [TomLowSound retain];
    
    // Create a system sound object representing the sound file.
    AudioServicesCreateSystemSoundID (
                                      soundFileURLRef1,
                                      &soundFileObject1
                                      );
    NSURL *CrashSound   = [[NSBundle mainBundle] URLForResource: @"Crash"
                                                  withExtension: @"aif"];
    // Store the URL as a CFURLRef instance
    self.soundFileURLRef2 = (CFURLRef) [CrashSound retain];
    
    // Create a system sound object representing the sound file.
    AudioServicesCreateSystemSoundID (
                                      soundFileURLRef2,
                                      &soundFileObject2
                                      );
    NSURL *SnareSound   = [[NSBundle mainBundle] URLForResource: @"Snare"
                                                  withExtension: @"aif"];
    
    // Store the URL as a CFURLRef instance
    self.soundFileURLRef3 = (CFURLRef) [SnareSound retain];
    
    // Create a system sound object representing the sound file.
    AudioServicesCreateSystemSoundID (                                      
                                      soundFileURLRef3,
                                      &soundFileObject3
                                      );
    NSURL *Tom2Sound   = [[NSBundle mainBundle] URLForResource: @"Tom2"
                                                  withExtension: @"aif"];
    
    // Store the URL as a CFURLRef instance
    self.soundFileURLRef4 = (CFURLRef) [Tom2Sound retain];
    
    // Create a system sound object representing the sound file.
    AudioServicesCreateSystemSoundID (                                      
                                      soundFileURLRef4,
                                      &soundFileObject4
                                      );
    NSURL *RideSound   = [[NSBundle mainBundle] URLForResource: @"Ride"
                                                  withExtension: @"aif"];
    
    // Store the URL as a CFURLRef instance
    self.soundFileURLRef5 = (CFURLRef) [RideSound retain];
    
    // Create a system sound object representing the sound file.
    AudioServicesCreateSystemSoundID (                                      
                                      soundFileURLRef5,
                                      &soundFileObject5
                                      );
    NSURL *KickSound   = [[NSBundle mainBundle] URLForResource: @"HiHat_Pedal"
                                                  withExtension: @"aif"];
    
    // Store the URL as a CFURLRef instance
    self.soundFileURLRef6 = (CFURLRef) [KickSound retain];
    
    // Create a system sound object representing the sound file.
    AudioServicesCreateSystemSoundID (                                      
                                      soundFileURLRef6,
                                      &soundFileObject6
                                      );
    NSURL *HiHat3Sound   = [[NSBundle mainBundle] URLForResource: @"Kick"
                                                  withExtension: @"aif"];
    
    // Store the URL as a CFURLRef instance
    self.soundFileURLRef7 = (CFURLRef) [HiHat3Sound retain];
    
    // Create a system sound object representing the sound file.
    AudioServicesCreateSystemSoundID (                                      
                                      soundFileURLRef7,
                                      &soundFileObject7
                                      );
    NSURL *HiHat4Sound   = [[NSBundle mainBundle] URLForResource: @"HiHat_Close"
                                                  withExtension: @"aif"];
    
    // Store the URL as a CFURLRef instance
    self.soundFileURLRef8 = (CFURLRef) [HiHat4Sound retain];
    
    // Create a system sound object representing the sound file.
    AudioServicesCreateSystemSoundID (                                      
                                      soundFileURLRef8,
                                      &soundFileObject8
                                      );
    NSURL *TestWaveSound1   = [[NSBundle mainBundle] URLForResource: @"testwavshort"
                                                   withExtension: @"aif"];
    
    // Store the URL as a CFURLRef instance
    self.soundFileURLRef9 = (CFURLRef) [TestWaveSound1 retain];
    
    // Create a system sound object representing the sound file.
    AudioServicesCreateSystemSoundID (                                      
                                      soundFileURLRef9,
                                      &soundFileObject9
                                      );
    AudioServicesAddSystemSoundCompletion(soundFileObject9, NULL, NULL, myAudioServicesSystemSoundCompletionProc, self);
    NSURL *TestWaveSound2   = [[NSBundle mainBundle] URLForResource: @"testwavmid"
                                                     withExtension: @"aif"];
    
    // Store the URL as a CFURLRef instance
    self.soundFileURLRef10 = (CFURLRef) [TestWaveSound2 retain];
    
    // Create a system sound object representing the sound file.
    AudioServicesCreateSystemSoundID (
                                      soundFileURLRef10,
                                      &soundFileObject10
                                      );
    AudioServicesAddSystemSoundCompletion(soundFileObject10, NULL, NULL, myAudioServicesSystemSoundCompletionProc, self);
    NSURL *TestWaveSound3   = [[NSBundle mainBundle] URLForResource: @"testwavlong"
                                                     withExtension: @"aif"];
    
    // Store the URL as a CFURLRef instance
    self.soundFileURLRef11 = (CFURLRef) [TestWaveSound3 retain];
    
    // Create a system sound object representing the sound file.
    AudioServicesCreateSystemSoundID (
                                      soundFileURLRef11,
                                      &soundFileObject11
                                      );
    AudioServicesAddSystemSoundCompletion(soundFileObject11, NULL, NULL, myAudioServicesSystemSoundCompletionProc, self);
}

void myAudioServicesSystemSoundCompletionProc(SystemSoundID ssID, void *clientData){
    
//    displayFirstStep.textColor = [UIColor blackColor];
//    self.displaySecondStep.textColor = [UIColor blackColor];
//    self.displayThirdStep.textColor = [UIColor blackColor];
//    self.displayFourthStep.textColor = [UIColor redColor];
//    deviceVolume = 0x10;
//    UInt8 selfcheckreq5[] = {0xf0,0x00,0x20,0x2b,0x69,0x05,(UInt8)deviceVolume,0xf7};
    
//    [midi sendBytes:selfcheckreq5 size:sizeof(selfcheckreq5)];//resume to default volume 0x20
//    noteOnReceived[0] = YES;
}

- (void) updateSerialNumberString{
    if(serialNumberConfig.text.length > 6){
        serialNumberConfig.text = [serialNumberConfig.text substringFromIndex:(serialNumberConfig.text.length-6)];
    }
    self.serialNumberString = serialNumberConfig.text;
//    NSLog(serialNumberString);
}
- (void) updateYearOfDateString{//only show the last 2 digits if user enter more than 2
    if(yearOfDateText.text.length > 2){
        yearOfDateText.text = [yearOfDateText.text substringFromIndex:(yearOfDateText.text.length-2)];
    }
//    [yearOfDateText.text characterAtIndex:yearOfDateText.text.length-1];
    yearOfDateString = (UInt8)[[yearOfDateText text] intValue];
}
- (void) updateMonthOfDateString{
    if(monthOfDateText.text.length > 2){
        monthOfDateText.text = [monthOfDateText.text substringFromIndex:(monthOfDateText.text.length-2)];
    }
    monthOfDateString = (UInt8)[[monthOfDateText text] intValue];
    if((monthOfDateString > 12)||(monthOfDateString == 0)){
        UIAlertView *dateAlertView = [[UIAlertView alloc]initWithTitle:@"出错啦" message:@"日期输入错误，请输入有效月份" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [dateAlertView show];
        [dateAlertView release];
        monthOfDateText.text = @"12";
        monthOfDateString = 12;
    }
}
- (void) updateDayOfDateString{
    if(dayOfDateText.text.length>2){
        dayOfDateText.text = [dayOfDateText.text substringFromIndex:(dayOfDateText.text.length-2)];
    }
    dayOfDateString = (UInt8)[[dayOfDateText text] intValue];
    if((dayOfDateString>31)||(dayOfDateString==0)){
        UIAlertView *dateAlertView = [[UIAlertView alloc]initWithTitle:@"出错啦" message:@"日期输入错误，请输入有效日期" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"取消", nil];
        [dateAlertView show];
        [dateAlertView release];
        dayOfDateString = 31;
        dayOfDateText.text = @"31";
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    NSCharacterSet *cs;
    cs = [[NSCharacterSet characterSetWithCharactersInString:NUMBERS] invertedSet];
    NSString *filtered = [[string componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
	BOOL basicTest = [string isEqualToString:filtered];
    return basicTest;
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField
{
    if(theTextField == serialNumberConfig){
        [serialNumberConfig resignFirstResponder];
        [self updateSerialNumberString];
    }else if(theTextField == yearOfDateText){
        [yearOfDateText resignFirstResponder];
        [self updateYearOfDateString];
    }else if(theTextField == monthOfDateText){
        [monthOfDateText resignFirstResponder];
        [self updateMonthOfDateString];
    }else if(theTextField == dayOfDateText){
        [dayOfDateText resignFirstResponder];
        [self updateDayOfDateString];
    }
    return YES;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    //    serialNumberConfig.text = [NSString stringWithFormat: @"%06d",serialNumberToWrite];//self.serialNumberString;
    
    [serialNumberConfig resignFirstResponder];
    [self updateSerialNumberString];
    [yearOfDateText resignFirstResponder];
    [self updateYearOfDateString];
    [monthOfDateText resignFirstResponder];
    [self updateMonthOfDateString];
    [dayOfDateText resignFirstResponder];
    [self updateDayOfDateString];
    
    serialNumberToWrite = (UInt32)[[serialNumberConfig text] intValue];
    yearOfDateString = (UInt8)[[yearOfDateText text] intValue];
    monthOfDateString = (UInt8)[[monthOfDateText text] intValue];
    dayOfDateString = (UInt8)[[dayOfDateText text] intValue];
//    yearOfDateText.text = [NSString stringWithFormat: @"%02d",yearOfDateString];    
//    monthOfDateText.text = [NSString stringWithFormat: @"%02d",monthOfDateString];    
//    dayOfDateText.text = [NSString stringWithFormat: @"%02d",dayOfDateString];
    
    [super touchesBegan:touches withEvent:event];
}

- (void)viewDidUnload {
    statusProgress = 0;
    processProgress = 0;
    [self setDisplayDeviceName:nil];
    [self setDisplayDeviceSerialNumber:nil];
    [self setDisplayDeviceVersionNumber:nil];
    [self setDisplayDeviceProductionDate:nil];
    [self setDisplayHeadphonePlugState:nil];
    [self setDisplayKickPlugState:nil];
    [self setDisplayHiHatPlugState:nil];
    [self setDisplayDevicePowerState:nil];
    [self setDisplayDeviceBatteryLevel:nil];
    [self setDisplayVoiceLevel:nil];
    [self setDisplayDrumPad0:nil];
    [self setDisplayDrumPad1:nil];
    [self setDisplayDrumPad2:nil];
    [self setDisplayDrumPad3:nil];
    [self setDisplayDrumPad4:nil];
    [self setDisplayDrumPad5:nil];
    [self setDisplayDrumPad6:nil];
    [self setDisplayDrumPad7:nil];
    [self setDisplayDrumPad8:nil];
    
    //	self.frequencyLabel = nil;
	//  self.playButton = nil;
    //	self.frequencySlider = nil;
    
//	AudioSessionSetActive(false);
    
    [self setDisplayFirstStep:nil];
    [self setDisplaySecondStep:nil];
    [self setDisplayThirdStep:nil];
    [self setDisplayFourthStep:nil];
    [self setDisplayCurrentDate:nil];
    [self setMakeVoiceInterval:nil];
    [self setSerialNumberConfig:nil];
    [self setPickerView:nil];
    [self setYearOfDateText:nil];
    [self setMonthOfDateText:nil];
    [self setDayOfDateText:nil];
	self->dateFormatter = nil;
    [self setDateButton0:nil];
    [self setDateButton1:nil];
    [self setSerialNumberButton:nil];
    [self setLedControlSwitch1:nil];
    [self setLedControlButton:nil];
    [self setLedControlButton1:nil];
    [self setDisplayUpdateProgress:nil];
    [self setDisplayDeviceModeConfigSwitch:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void) dealloc {
    
    AudioServicesDisposeSystemSoundID (soundFileObject0);
    CFRelease (soundFileURLRef0);
    AudioServicesDisposeSystemSoundID (soundFileObject1);
    CFRelease (soundFileURLRef1);
    AudioServicesDisposeSystemSoundID (soundFileObject2);
    CFRelease (soundFileURLRef2);
    AudioServicesDisposeSystemSoundID (soundFileObject3);
    CFRelease (soundFileURLRef3);
    AudioServicesDisposeSystemSoundID (soundFileObject4);
    CFRelease (soundFileURLRef4);
    AudioServicesDisposeSystemSoundID (soundFileObject5);
    CFRelease (soundFileURLRef5);
    AudioServicesDisposeSystemSoundID (soundFileObject6);
    CFRelease (soundFileURLRef6);
    AudioServicesDisposeSystemSoundID (soundFileObject7);
    CFRelease (soundFileURLRef7);
    AudioServicesDisposeSystemSoundID (soundFileObject8);
    CFRelease (soundFileURLRef8);
    AudioServicesDisposeSystemSoundID (soundFileObject9);
    CFRelease (soundFileURLRef9);
    AudioServicesDisposeSystemSoundID (soundFileObject10);
    CFRelease (soundFileURLRef10);
    AudioServicesDisposeSystemSoundID (soundFileObject11);
    CFRelease (soundFileURLRef11);

    [displayFirstStep release];
    [displaySecondStep release];
    [displayThirdStep release];
    [displayFourthStep release];
    [displayCurrentDate release];
    [makeVoiceInterval release];
    [serialNumberConfig release];
    [yearOfDateText release];
    [monthOfDateText release];
    [dayOfDateText release];
    [dateButton0 release];
	[pickerView release];
	[dateFormatter release];
    [dateButton1 release];
    [serialNumberButton release];
    [ledControlSwitch1 release];
    [ledControlButton release];
    [ledControlButton1 release];
    [displayUpdateProgress release];
    [_displayDeviceModeConfigSwitch release];
    [super dealloc];
}

@end
