//
//  AccessibilityManager.swift
//  fridge
//
//  Created by Claude on 7/2/25.
//

import Foundation
import Speech
import AVFoundation
import Combine
import SwiftUI

// MARK: - Voice Command Enums

enum VoiceCommand: String, CaseIterable {
    case addItem = "add item"
    case scanBarcode = "scan barcode"
    case takePicture = "take picture"
    case readRecipe = "read recipe"
    case listItems = "list items"
    case expiringSoon = "show expiring soon"
    case goHome = "go home"
    case goToFridge = "go to fridge"
    case goToRecipes = "go to recipes"
    case goToShoppingList = "go to shopping list"
    case highContrast = "high contrast mode"
    case normalContrast = "normal contrast mode"
    
    static var allCommands: String {
        VoiceCommand.allCases.map { "• \($0.rawValue.capitalized)" }.joined(separator: "\n")
    }
}

// MARK: - Accessibility Manager

class AccessibilityManager: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    // Singleton
    static let shared = AccessibilityManager()
    
    // Publishers
    @Published var isVoiceListening = false
    @Published var voiceListeningText = ""
    @Published var voiceCommandDetected: VoiceCommand?
    @Published var isHighContrastEnabled = false
    @Published var isVoiceEnabled = false
    
    // Text-to-speech
    private let synthesizer = AVSpeechSynthesizer()
    
    // Speech recognition
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private override init() {
        super.init()
        speechRecognizer?.delegate = self
        
        // Load saved preferences
        isHighContrastEnabled = UserDefaults.standard.bool(forKey: "isHighContrastEnabled")
        isVoiceEnabled = UserDefaults.standard.bool(forKey: "isVoiceEnabled")
    }
    
    // MARK: - High Contrast Mode
    
    func toggleHighContrastMode() {
        isHighContrastEnabled.toggle()
        UserDefaults.standard.set(isHighContrastEnabled, forKey: "isHighContrastEnabled")
    }
    
    // MARK: - Voice Commands
    
    func toggleVoiceCommands() {
        isVoiceEnabled.toggle()
        UserDefaults.standard.set(isVoiceEnabled, forKey: "isVoiceEnabled")
        
        if isVoiceEnabled {
            requestSpeechAuthorization()
        } else if isVoiceListening {
            stopListening()
        }
    }
    
    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    // User allowed speech recognition
                    self.isVoiceEnabled = true
                default:
                    // User denied permission
                    self.isVoiceEnabled = false
                }
            }
        }
    }
    
    func startListening() {
        // Check if already listening or if voice is disabled
        if isVoiceListening || !isVoiceEnabled {
            return
        }
        
        // Reset previous task
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // Setup audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session setup failed: \(error)")
            return
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        // Get the audio input node - no need for optional binding as this is not optional
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            print("Unable to create a SFSpeechAudioBufferRecognitionRequest object")
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Start recognition
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                // Update text display
                self.voiceListeningText = result.bestTranscription.formattedString
                isFinal = result.isFinal
                
                // Check for voice commands
                self.checkForVoiceCommands(in: self.voiceListeningText)
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.isVoiceListening = false
            }
        }
        
        // Setup audio input
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        // Start recording
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isVoiceListening = true
        } catch {
            print("Audio engine failed to start: \(error)")
        }
    }
    
    func stopListening() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        isVoiceListening = false
    }
    
    private func checkForVoiceCommands(in text: String) {
        let lowercasedText = text.lowercased()
        
        for command in VoiceCommand.allCases {
            if lowercasedText.contains(command.rawValue) {
                self.voiceCommandDetected = command
                
                // Give feedback
                speakText("Command recognized: \(command.rawValue)")
                
                // Stop listening
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.stopListening()
                }
                
                break
            }
        }
    }
    
    // MARK: - Text-to-Speech
    
    func speakText(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        synthesizer.speak(utterance)
    }
    
    func speakRecipe(_ recipe: Recipe) {
        var recipeText = "Recipe for \(recipe.name). "
        recipeText += "Ingredients: "
        
        // Combine used and missing ingredients
        let allIngredients = recipe.usedIngredientsDisplay + recipe.missedIngredientsDisplay
        recipeText += allIngredients.joined(separator: ", ")
        
        recipeText += ". Instructions: "
        recipeText += recipe.instructions.enumerated()
            .map { "Step \($0 + 1): \($1)" }
            .joined(separator: ". ")
        
        speakText(recipeText)
    }
    
    func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
    
    // MARK: - SFSpeechRecognizerDelegate
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if !available {
            isVoiceListening = false
        }
    }
}

// MARK: - SwiftUI Modifiers

// High contrast modifier
struct HighContrastModifier: ViewModifier {
    @ObservedObject private var accessibilityManager = AccessibilityManager.shared
    
    func body(content: Content) -> some View {
        if accessibilityManager.isHighContrastEnabled {
            return AnyView(
                content
                    .foregroundColor(.white)
                    .background(Color.black)
                    .environment(\.colorScheme, .dark)
            )
        } else {
            return AnyView(content)
        }
    }
}

// Voice commands indicator
struct VoiceCommandsIndicator: View {
    @ObservedObject private var accessibilityManager = AccessibilityManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                if accessibilityManager.isVoiceListening {
                    accessibilityManager.stopListening()
                } else {
                    accessibilityManager.startListening()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(accessibilityManager.isVoiceListening ? Color.red.opacity(0.2) : Color.blue.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: accessibilityManager.isVoiceListening ? "waveform.circle.fill" : "mic.circle")
                        .font(.system(size: 22))
                        .foregroundColor(accessibilityManager.isVoiceListening ? .red : .blue)
                }
            }
            
            if accessibilityManager.isVoiceListening {
                Text(accessibilityManager.voiceListeningText.isEmpty ? "Listening..." : accessibilityManager.voiceListeningText)
                    .font(.caption)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.7)))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
                    .animation(.easeInOut, value: accessibilityManager.isVoiceListening)
            }
        }
        .padding(.horizontal)
        .background(
            accessibilityManager.isVoiceListening ? 
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(.systemBackground).opacity(0.8))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2) :
                nil
        )
        .padding(.horizontal)
        .accessibilityLabel("Voice command button")
    }
}

// Extension to apply high contrast mode
extension View {
    func highContrastMode() -> some View {
        self.modifier(HighContrastModifier())
    }
}

// Accessibility help button
struct AccessibilityHelpButton: View {
    @State private var showingHelp = false
    
    var body: some View {
        Button(action: {
            showingHelp = true
        }) {
            Image(systemName: "accessibility")
                .font(.headline)
                .padding(8)
                .background(Circle().fill(Color.blue.opacity(0.2)))
        }
        .sheet(isPresented: $showingHelp) {
            AccessibilityHelpView()
        }
        .accessibilityLabel("Accessibility help")
    }
}

// Accessibility help view
struct AccessibilityHelpView: View {
    @ObservedObject private var accessibilityManager = AccessibilityManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Voice Commands")) {
                    Text("Speak any of these commands while Voice Commands are enabled:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                    
                    ForEach(VoiceCommand.allCases, id: \.self) { command in
                        HStack {
                            Text(command.rawValue.capitalized)
                                .font(.body)
                            
                            Spacer()
                            
                            Image(systemName: iconForCommand(command))
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section(header: Text("How to Use")) {
                    HStack {
                        Image(systemName: "1.circle.fill")
                            .foregroundColor(.blue)
                        Text("Enable Voice Commands in Profile → Preferences → Accessibility")
                            .font(.subheadline)
                    }
                    .padding(.vertical, 2)
                    
                    HStack {
                        Image(systemName: "2.circle.fill")
                            .foregroundColor(.blue)
                        Text("Tap the microphone button when it appears")
                            .font(.subheadline)
                    }
                    .padding(.vertical, 2)
                    
                    HStack {
                        Image(systemName: "3.circle.fill")
                            .foregroundColor(.blue)
                        Text("Speak one of the commands clearly")
                            .font(.subheadline)
                    }
                    .padding(.vertical, 2)
                    
                    HStack {
                        Image(systemName: "4.circle.fill")
                            .foregroundColor(.blue)
                        Text("The app will respond to your command")
                            .font(.subheadline)
                    }
                    .padding(.vertical, 2)
                }
                
                Section {
                    Button("Test Voice Commands") {
                        accessibilityManager.speakText("Voice command system is working correctly.")
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Voice Commands Help")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .highContrastMode()
    }
    
    private func iconForCommand(_ command: VoiceCommand) -> String {
        switch command {
        case .addItem: return "plus.circle"
        case .scanBarcode: return "barcode.viewfinder"
        case .takePicture: return "camera"
        case .readRecipe: return "text.book.closed"
        case .listItems: return "list.bullet"
        case .expiringSoon: return "exclamationmark.triangle"
        case .goHome: return "house"
        case .goToFridge: return "refrigerator"
        case .goToRecipes: return "fork.knife"
        case .goToShoppingList: return "cart"
        case .highContrast: return "circle.lefthalf.filled"
        case .normalContrast: return "circle"
        }
    }
} 