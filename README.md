# Simple-Radio-COM
 Simple-Radio-COM or SMCOM Controls a Radio connected via COM such as with a Digirig Mobile, allowing direct PTT control, transmitting and scheduling pre-recorded audio, and sending TTS in the program or via scripts!


![Preview](https://i.imgur.com/gpzGNt8.png)

# Features

1. Control PTT by itself.
2. Play DTMF tones.
3. Transmit Audio Files Quickly and easily.
4. Schedule transmission of files by timer or date and time.
5. Loop transmissions, repeat schedules.
6. Simple Distress mode to send out looped distress signal
7. Set output device independant of system default

# Notes

- Made for use with a [Digirig](https://digirig.net/), a cheap device that allows interfacing with radios that do not have serial or digital connection.
- Should work with any COM based PTT trigger and soundcard setup
- Does not support busy-channel lockout at this time. If anyone has a command-line usable tool that can listen to a specific input device to see if any audio is playing, I'd be able to impliment that.
- **Update:** I am currently working on a feature that works with Voicemeeter which, if the radio is receiving audio, will wait until there is a break of x seconds.
- Designed and tested with [Voicemeeter](https://voicemeeter.com/) setup in mind.

## Example [Voicemeeter](https://voicemeeter.com/) setup:
![VBSetup](https://i.imgur.com/QpXijEu.png)

# Languages / Open Source

All of the program is written open source or using open source tools except for one small file, KBD.exe. KBD.exe is a file I found a long time ago that allows listening for any key type that is pressed with a console window open. This allows me to listen for the space bar and DTMF keys. It is only used in that mode. I believe it is made by microsoft but cannot find a source for it.

3rd party open-source tools used:
- [SoundPlayer](https://github.com/MichielP1807/AHKSoundToDevicePlayer) (To play sound to specific output).
- [ffmpeg](https://www.ffmpeg.org/) to convert audio files to WAV.

# Installation

To Install, head over to the [releases](https://github.com/ITCMD/Simple-Radio-COM/releases) page and download the latest release. Unzip it where you want, and run Simple-Radio-COM.bat. No admin access or special install required!

# Links
## https://w1btr.com
## https://programs.lucas-elliott.com
