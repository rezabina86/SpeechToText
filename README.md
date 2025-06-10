# Audio Transcription App

A real-time audio transcription iOS application that records speech and converts it to text using Apple's Speech Recognition framework.

## 🎯 Features

- **Real-time Recording**: Record audio with a simple tap
- **Live Transcription**: See your speech converted to text in real-time
- **Playback Controls**: Play, pause, and reset recorded audio
- **Clean Interface**: Minimalist design focused on functionality

### 📱 Screenshots
<p align="center">
  <img src="https://github.com/user-attachments/assets/83cfcfe3-a2a4-4bb2-86c9-799227656022" width=200>
  <img src="https://github.com/user-attachments/assets/b0a183f9-f8f1-42ad-923c-6098b92084ea" width=200>
  <img src="https://github.com/user-attachments/assets/95bf9ceb-f294-4df3-8bff-4c4fee969da8" width=200>
  <img src="https://github.com/user-attachments/assets/65fc0896-ffef-4b93-8a21-4496170f23fe" width=200>
</p>

## 🏗️ Architecture

The app follows a clean architecture pattern with three distinct layers:

![Architecture](https://github.com/user-attachments/assets/e7f50110-fde8-4cf6-9175-1cf8e019599b)


### Data Layer
- **AVFoundation**: Handles audio recording and playback functionality
- **Speech**: Integrates Apple's Speech Recognition framework for transcription

### Domain Layer (Business Logic)
- **AudioPlayerManager**: Manages audio playback operations
- **AudioRecorderManager**: Handles audio recording functionality  
- **SpeechRecognitionManager**: Coordinates speech-to-text conversion
- **SpeechRecognitionUseCase**: Encapsulates speech recognition business logic

### Presentation Layer
- **AppViewModel**: Manages app state and coordinates between layers
- **View**: SwiftUI-based user interface

4. Build and run on device (speech recognition requires a physical device)

## 🚀 Usage

1. **Record**: Tap the "Record" button to start recording
2. **Transcribe**: Watch as your speech appears as text in real-time
3. **Stop**: Tap "Stop Recording" when finished
4. **Playback**: Use "Play" to hear your recording
5. **Reset**: Clear the current session with "Reset"

## 🛠️ Technologies Used

- **SwiftUI** - Modern declarative UI framework
- **AVFoundation** - Audio recording and playback
- **Speech** - Apple's speech recognition framework
- **Combine** - Reactive programming framework
