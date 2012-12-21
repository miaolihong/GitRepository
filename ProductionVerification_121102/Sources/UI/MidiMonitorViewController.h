//
//  MidiMonitorViewController.h
//  MidiMonitor
//
//  Created by Pete Goodliffe on 10/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>

@class PGMidi;

@interface MidiMonitorViewController : UIViewController
{
    UILabel    *countLabel;
//    UITextView *textView;
    UILabel    *displayDeviceVersionNumber;
    
    IBOutlet UITextField *serialNumberConfig;
    IBOutlet UITextField *yearOfDateText;
    IBOutlet UITextField *monthOfDateText;
    IBOutlet UITextField *dayOfDateText;
    
    UIDatePicker *pickerView;
	UIButton *dateButton;
//	NSArray *dataArray;
	NSDateFormatter *dateFormatter;
    
//    NSString *textDateTimeStamp;
    NSString *serialNumberString;
    UInt8 yearOfDateString;
    UInt8 monthOfDateString;
    UInt8 dayOfDateString;
    PGMidi *midi;
    
    //	UILabel *frequencyLabel;
//	UIButton *playButton;
    //	UISlider *frequencySlider;
//	AudioComponentInstance toneUnit;
    @public
    //	double frequency;
//	double sampleRate;
//	double theta;
    
    CFURLRef		soundFileURLRef0;
	SystemSoundID	soundFileObject0;
    CFURLRef		soundFileURLRef1;
	SystemSoundID	soundFileObject1;
    CFURLRef		soundFileURLRef2;
	SystemSoundID	soundFileObject2;
    CFURLRef		soundFileURLRef3;
	SystemSoundID	soundFileObject3;
    CFURLRef		soundFileURLRef4;
	SystemSoundID	soundFileObject4;
    CFURLRef		soundFileURLRef5;
	SystemSoundID	soundFileObject5;
    CFURLRef		soundFileURLRef6;
	SystemSoundID	soundFileObject6;
    CFURLRef		soundFileURLRef7;
	SystemSoundID	soundFileObject7;
    CFURLRef		soundFileURLRef8;
	SystemSoundID	soundFileObject8;
    CFURLRef		soundFileURLRef9;
	SystemSoundID	soundFileObject9;
    CFURLRef		soundFileURLRef10;
	SystemSoundID	soundFileObject10;
    CFURLRef		soundFileURLRef11;
	SystemSoundID	soundFileObject11;
}

//@property (nonatomic, retain) IBOutlet UISlider *frequencySlider;
//@property (nonatomic, retain) IBOutlet UIButton *playButton;
//@property (nonatomic, retain) IBOutlet UILabel *frequencyLabel;

//- (IBAction)sliderChanged:(UISlider *)frequencySlider;
//- (IBAction)togglePlay:(UIButton *)selectedButton;
//- (void)stop;

@property (retain, nonatomic) IBOutlet UISwitch *displayDeviceModeConfigSwitch;

@property (retain, nonatomic) IBOutlet UISlider *displayUpdateProgress;

@property (retain, nonatomic) IBOutlet UIButton *dateButton0;

@property (retain, nonatomic) IBOutlet UIButton *dateButton1;
@property (retain, nonatomic) IBOutlet UIButton *ledControlButton;

@property (retain, nonatomic) IBOutlet UIButton *ledControlButton1;

@property (retain, nonatomic) IBOutlet UITextField *serialNumberConfig;
@property (retain, nonatomic) IBOutlet UITextField *yearOfDateText;
@property (retain, nonatomic) IBOutlet UITextField *monthOfDateText;
@property (retain, nonatomic) IBOutlet UITextField *dayOfDateText;

@property (retain, nonatomic) IBOutlet UIDatePicker *pickerView;
//@property (retain, nonatomic) IBOutlet UIButton *dateButton;

@property (retain, nonatomic) IBOutlet UILabel *displayCurrentDate;

@property (retain, nonatomic) IBOutlet UILabel *displayFirstStep;
@property (retain, nonatomic) IBOutlet UILabel *displaySecondStep;
@property (retain, nonatomic) IBOutlet UILabel *displayThirdStep;
@property (retain, nonatomic) IBOutlet UILabel *displayFourthStep;

@property (strong, nonatomic) IBOutlet UILabel *displayDeviceName;

@property (strong, nonatomic) IBOutlet UILabel *displayDeviceSerialNumber;

@property (strong, nonatomic) IBOutlet UILabel *displayDeviceVersionNumber;

@property (strong, nonatomic) IBOutlet UILabel *displayDeviceProductionDate;

@property (strong, nonatomic) IBOutlet UISwitch *displayHeadphonePlugState;

@property (strong, nonatomic) IBOutlet UISwitch *displayKickPlugState;

@property (strong, nonatomic) IBOutlet UISwitch *displayHiHatPlugState;

@property (strong, nonatomic) IBOutlet UISlider *displayDeviceBatteryLevel;

@property (strong, nonatomic) IBOutlet UILabel *displayDevicePowerState;

@property (strong, nonatomic) IBOutlet UISlider *displayVoiceLevel;

@property (strong, nonatomic) IBOutlet UILabel *displayDrumPad0;

@property (strong, nonatomic) IBOutlet UILabel *displayDrumPad1;

@property (strong, nonatomic) IBOutlet UILabel *displayDrumPad2;

@property (strong, nonatomic) IBOutlet UILabel *displayDrumPad3;

@property (strong, nonatomic) IBOutlet UILabel *displayDrumPad4;

@property (strong, nonatomic) IBOutlet UILabel *displayDrumPad5;

@property (strong, nonatomic) IBOutlet UILabel *displayDrumPad6;

@property (strong, nonatomic) IBOutlet UILabel *displayDrumPad7;

@property (strong, nonatomic) IBOutlet UILabel *displayDrumPad8;

@property (retain, nonatomic) IBOutlet UISwitch *ledControlSwitch1;

@property (retain, nonatomic) IBOutlet UISlider *makeVoiceInterval;

@property (retain, nonatomic) IBOutlet UIButton *serialNumberButton;

@property (readwrite, atomic)	CFURLRef		soundFileURLRef0;
@property (readonly, atomic)	SystemSoundID	soundFileObject0;
@property (readwrite, atomic)	CFURLRef		soundFileURLRef1;
@property (readonly, atomic)	SystemSoundID	soundFileObject1;
@property (readwrite, atomic)	CFURLRef		soundFileURLRef2;
@property (readonly, atomic)	SystemSoundID	soundFileObject2;
@property (readwrite, atomic)	CFURLRef		soundFileURLRef3;
@property (readonly, atomic)	SystemSoundID	soundFileObject3;
@property (readwrite, atomic)	CFURLRef		soundFileURLRef4;
@property (readonly, atomic)	SystemSoundID	soundFileObject4;
@property (readwrite, atomic)	CFURLRef		soundFileURLRef5;
@property (readonly, atomic)	SystemSoundID	soundFileObject5;
@property (readwrite, atomic)	CFURLRef		soundFileURLRef6;
@property (readonly, atomic)	SystemSoundID	soundFileObject6;
@property (readwrite, atomic)	CFURLRef		soundFileURLRef7;
@property (readonly, atomic)	SystemSoundID	soundFileObject7;
@property (readwrite, atomic)	CFURLRef		soundFileURLRef8;
@property (readonly, atomic)	SystemSoundID	soundFileObject8;
@property (readwrite, atomic)	CFURLRef		soundFileURLRef9;
@property (readonly, atomic)	SystemSoundID	soundFileObject9;
@property (readwrite, atomic)	CFURLRef		soundFileURLRef10;
@property (readonly, atomic)	SystemSoundID	soundFileObject10;
@property (readwrite, atomic)	CFURLRef		soundFileURLRef11;
@property (readonly, atomic)	SystemSoundID	soundFileObject11;
#if ! __has_feature(objc_arc)

@property (nonatomic,retain) IBOutlet UILabel    *countLabel;
//@property (nonatomic,retain) IBOutlet UITextView *textView;

@property (nonatomic,assign) PGMidi *midi;
@property (nonatomic, copy) NSString *serialNumberString;

#else

@property (nonatomic,strong) IBOutlet UILabel    *countLabel;
//@property (nonatomic,strong) IBOutlet UITextView *textView;



@property (nonatomic,strong) PGMidi *midi;

#endif

- (IBAction)updateFirmware:(UIButton *)sender;

- (IBAction)dateButtonPressed;

- (IBAction)dateButton1Pressed;

- (IBAction) dateAction;

- (IBAction) ledControlButtonPressed;

- (IBAction) ledControl1ButtonPressed;
- (IBAction)resetSerialNumberButtonPressed:(UIButton *)sender;

- (IBAction) clearTextView;
- (IBAction) listAllInterfaces;
- (IBAction)stepBackward;
- (IBAction)operationInstruction;

- (IBAction) sendMidiData;
- (IBAction) serialNumberSet;

void myAudioServicesSystemSoundCompletionProc(SystemSoundID ssID, void *clientData);

//- (void) updateSerialNumberString;
@end

