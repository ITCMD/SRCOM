# Simple-Radio-COM
Simple-Radio-COM or SRCOM Controls a Radio connected via COM such as with a Digirig Mobile, allowing direct PTT control, transmitting and scheduling pre-recorded audio, and sending TTS in the program or via scripts!

### [Version 7 Beta Out Now!](https://github.com/ITCMD/Simple-Radio-COM/releases)
Powered by new media engine - https://github.com/stsaz/fmedia

![Preview](https://user-images.githubusercontent.com/32961763/180625139-2b8303ab-2a9e-4c75-9edf-10d42ad75cc3.png)

# Features

 1. Use your computer to control your radio's PTT.
 2. Use your computer's microphone as your radio's microphone.
 3. Record and play quick messages, such as a CQ call on the fly.
 4. Transmit Audio Files Quickly and easily.
 5. Schedule transmission of audio files by timer or date and time.
 6. Loop transmissions, repeat schedules.
 7. Live Text-To-Speech mode for mute or voice-restricted operators.
 8. QuickRecorder allows recording both sides of the conversation independently (mixes them on the fly for playback).
 9. Simple Distress mode to send out looped distress signal
10. Set input and output device independant of system default
11. Automatically checks for changes in audio devices or COM ports.

## Quick Recorder

The QuickRecorder allows you to recordg both sides of the conversation independently (mixes them on the fly for playback). Quickly toggle the recording of your voice, the radio's output, or both!

![QuickRecorder](https://user-images.githubusercontent.com/32961763/180624768-0960dad5-4745-46e5-ad25-196f180b921f.png)]

## Live TTS Mode

Live Text-To-Speech mode allows mute or voice impared operators to communicate with others over SSB! Use a male or female voice to talk on your radio by sending chunks of text at a time with special variables built-in!

![TTS Screenshot](https://i.imgur.com/bXuNxY5.png)
![TTS Help Menu](https://i.imgur.com/PnV6W1S.png)

## Recording and Playback

Take the strain off your voice by recording and playing back common messages on the fly! Bring a feature normally restricted to newer, high-end radios to your radio for free! Easy and quick access from the basic transmit area!

![Playback Menu](https://i.imgur.com/LaFb4Px.png)

## Distress Mode

Rest easy knowing that you have a simple and reliable option for sending out a distress call. Let SRCOM handle the message in an emergency to keep your hands free when every second counts.

![Distress Mode](https://user-images.githubusercontent.com/32961763/180625043-51d35725-6280-49e6-9ac0-40cb0ac44def.png)

## Intuitive Settings

Change settings and options easily with the settings menu!

![Settings](https://i.imgur.com/VGqNOvf.png)

## Plugins

1. SRCOM supports third party plugins with a plugin menu. These can be added to Bin\Plugins.
2. SRCOM plugins can place .cmd files in BeforeTX, OnStartTX, and AfterTX, and they will be run accordingly.
3. SRCOM comes with a roger beep plugin, a callsign ID plugin, and a **busy channel lockout plugin.** (note: Busy channel lockout plugin requires voicemeeter macros).

# Notes

- Made for use with a [Digirig](https://digirig.net/), a cheap device that allows interfacing with radios that do not have serial or digital connection.
- Also works with Signalink USBs with minimal setup
- Should work with any RTS COM based PTT trigger and soundcard setup
- Busy Channel Lockout Plugin Requires [Voicemeeter](https://voicemeeter.com/).

## Languages / Open Source

All of the program is written open source or using open source tools except for one small file, KBD.exe. KBD.exe is a file I found a long time ago that allows listening for any key type that is pressed while the console window is selected. No other software I know of supports all keys, including the arrow, enter, and f keys. This allows me to listen for the space bar and DTMF keys. It is only used in that mode. I believe it is made by Microsoft but cannot find a source for it. I had some fnacy-pants folk check it over and have analyzed how it interracts with one's computer, and it is harmless.

3rd party open-source tools used:
- [fmedia](https://github.com/stsaz/fmedia) - fmedia is used as the SRCOM's audio engine.

# Installation

If you are using a digirig and havnt set it up yet (and you dont see it in the COM ports section of device manager), make sure you download the drivers at https://www.silabs.com/developers/usb-to-uart-bridge-vcp-drivers
Once downloaded, extract them and install the drivers by selecting the whole folder as the source of the drivers in device manager.
If you are using a signalink, no other program setup is required, just follow the prompts in SRCOM.

To Install, head over to the [releases](https://github.com/ITCMD/Simple-Radio-COM/releases) page and download the latest release. Unzip it where you want, and run Simple-Radio-COM.bat. No admin access or special install required! Follow the prompts, and you're off to the races!

![setup screenshot](https://i.imgur.com/ybpeQt8.png)

# Links
## https://w1btr.com
## https://programs.lucas-elliott.com
## https://github.com/stsaz/fmedia

        #                              
      #######      ##############(        Powered by fmedia
     ########    ###################      https://github.com/stsaz/fmedia
    #######/    ,#######     ########   
   ########     #######       ########    Made for Digirig
   #######      #######        #######    https://digirig.net/
   #######      #######        #######  
   #######      #######       #######.    Special Thanks to
    ########    #######     ########/     PART of Westford Club
     ##############################       https://wb1gof.org
       #########################.         ffmpeg (old audio engine)
            ###############.              https://ffmpeg.org/
                #######                   TheNextGuy100 - TTS Ideas
                #######                   https://www.twitch.tv/thenextguy100
                #######                    
                #######                   W3AVP, KB1OIQ, KB1GMX
