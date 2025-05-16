//
//  VocaLearningView.swift
//  Voca
//
//  Created by User on 16/05/2025.
//
import SwiftUI

struct VocaLearningView: View {
  let vocabularyManager: VocaManager
  @Environment(\.dismiss) private var dismiss
  @State private var currentWordIndex = 0
  @State private var showingDefinition = false
  @State private var studiedWords = 0
  @State private var sessionProgress: Double = 0
  @State private var showingCompletion = false
  @State private var dragOffset: CGFloat = 0
  @State private var cardRotation: Double = 0
  @State private var showNextCard = false

  // Sample vocabulary data - in a real app this would come from your vocabulary database
  private let vocabularySet = [
    VocabularyWord(word: "Serendipity", definition: "The pleasant surprise of finding something good or useful by accident", example: "Finding this book was pure serendipity."),
    VocabularyWord(word: "Ephemeral", definition: "Lasting for a very short time", example: "The beauty of cherry blossoms is ephemeral."),
    VocabularyWord(word: "Ubiquitous", definition: "Present, appearing, or found everywhere", example: "Smartphones have become ubiquitous in modern society."),
    VocabularyWord(word: "Mellifluous", definition: "Having a smooth, flowing sound that is pleasing to hear", example: "Her mellifluous voice captivated the audience."),
    VocabularyWord(word: "Perspicacious", definition: "Having keen insight and good judgment", example: "His perspicacious analysis solved the problem quickly."),
    VocabularyWord(word: "Sanguine", definition: "Optimistic or positive, especially in a difficult situation", example: "Despite setbacks, she remained sanguine about the project."),
    VocabularyWord(word: "Quintessential", definition: "Representing the most perfect example of a quality", example: "Paris is the quintessential romantic city."),
    VocabularyWord(word: "Equanimity", definition: "Mental calmness and composure, especially in difficult situations", example: "She faced the crisis with remarkable equanimity.")
  ]

  private var currentWord: VocabularyWord {
    vocabularySet[min(currentWordIndex, vocabularySet.count - 1)]
  }

  private var progressPercentage: Int {
    guard !vocabularySet.isEmpty else { return 0 }
    return Int((Double(studiedWords) / Double(vocabularySet.count)) * 100)
  }

  var body: some View {
    NavigationStack {
      GeometryReader { geometry in
        VStack(spacing: 0) {

          // Header with progress
          VStack(spacing: 16) {
            HStack {
              Text("Learning Session")
                .font(.headline)
                .fontWeight(.medium)

              Spacer()

              Text("\(studiedWords)/\(vocabularySet.count)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            }

            // Progress bar
            ZStack(alignment: .leading) {
              Capsule()
                .fill(Color.secondary.opacity(0.2))
                .frame(height: 8)

              Capsule()
                .fill(Color.primary)
                .frame(height: 8)
                .containerRelativeFrame([.horizontal]) { length, _ in
                  length * sessionProgress
                }
                .animation(.spring(duration: 0.8), value: sessionProgress)
            }

            Text("\(progressPercentage)% Complete")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .padding(.horizontal, 24)
          .padding(.top, 8)

          Spacer()

          // Vocabulary Card
          VStack {
            ZStack {
              // Background cards for stack effect
              if currentWordIndex + 1 < vocabularySet.count {
                Rectangle()
                  .fill(Color.secondary.opacity(0.1))
                  .frame(height: 300)
                  .clipShape(RoundedRectangle(cornerRadius: 24))
                  .scaleEffect(0.95)
                  .offset(y: 8)
              }

              if currentWordIndex + 2 < vocabularySet.count {
                Rectangle()
                  .fill(Color.secondary.opacity(0.05))
                  .frame(height: 300)
                  .clipShape(RoundedRectangle(cornerRadius: 24))
                  .scaleEffect(0.9)
                  .offset(y: 16)
              }

              // Main vocabulary card
              VocabularyCardView(
                word: currentWord,
                showingDefinition: showingDefinition,
                dragOffset: dragOffset,
                cardRotation: cardRotation
              )
              .frame(height: 300)
              .opacity(showNextCard ? 0 : 1)
              .scaleEffect(showNextCard ? 0.9 : 1.0)
              .animation(.spring(duration: 0.3), value: showNextCard)
            }
            .padding(.horizontal, 24)
          }

          Spacer()

          // Action buttons
          VStack(spacing: 20) {
            if !showingDefinition {
              Button {
                withAnimation(.spring(duration: 0.4)) {
                  showingDefinition = true
                }
              } label: {
                HStack(spacing: 12) {
                  Image(systemName: "eye.fill")
                  Text("Show Definition")
                    .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                  RoundedRectangle(cornerRadius: 16)
                    .fill(Color.primary)
                    .shadow(color: Color.primary.opacity(0.3), radius: 6, y: 3)
                )
              }
              .sensoryFeedback(.impact(weight: .light), trigger: showingDefinition)
            } else {
              HStack(spacing: 16) {
                // Mark as difficult
                Button {
                  nextWord(correct: false)
                } label: {
                  VStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                      .font(.system(size: 24))
                      .foregroundStyle(.red)
                    Text("Difficult")
                      .font(.caption)
                      .fontWeight(.medium)
                  }
                  .frame(maxWidth: .infinity)
                  .frame(height: 70)
                  .background(
                    RoundedRectangle(cornerRadius: 16)
                      .fill(Color.red.opacity(0.1))
                      .overlay(
                        RoundedRectangle(cornerRadius: 16)
                          .stroke(Color.red.opacity(0.3), lineWidth: 1)
                      )
                  )
                }
                .sensoryFeedback(.impact(weight: .light), trigger: false)

                // Mark as learned
                Button {
                  nextWord(correct: true)
                } label: {
                  VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                      .font(.system(size: 24))
                      .foregroundStyle(.green)
                    Text("Got It!")
                      .font(.caption)
                      .fontWeight(.medium)
                  }
                  .frame(maxWidth: .infinity)
                  .frame(height: 70)
                  .background(
                    RoundedRectangle(cornerRadius: 16)
                      .fill(Color.green.opacity(0.1))
                      .overlay(
                        RoundedRectangle(cornerRadius: 16)
                          .stroke(Color.green.opacity(0.3), lineWidth: 1)
                      )
                  )
                }
                .sensoryFeedback(.success, trigger: false)
              }
            }
          }
          .padding(.horizontal, 24)
          .padding(.bottom, 20)
        }
      }
      .background(Color(.systemBackground))
      .navigationTitle("")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Done") {
            dismiss()
          }
          .foregroundStyle(.secondary)
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button("Skip") {
            nextWord(correct: nil)
          }
          .foregroundStyle(.secondary)
        }
      }
      .sheet(isPresented: $showingCompletion) {
        VocaSessionCompletionView(
          studiedWords: studiedWords,
          totalWords: vocabularySet.count,
          vocabularyManager: vocabularyManager
        )
      }
    }
  }

  private func nextWord(correct: Bool?) {
    // Update statistics
    studiedWords += 1
    vocabularyManager.addWordLearned()

    if let correct = correct {
      if correct {
        vocabularyManager.addCorrectAnswer()
      } else {
        vocabularyManager.addIncorrectAnswer()
      }
    }

    // Update progress
    sessionProgress = Double(studiedWords) / Double(vocabularySet.count)

    // Check if session is complete
    if studiedWords >= vocabularySet.count {
      showingCompletion = true
      return
    }

    // Animate to next card
    withAnimation(.spring(duration: 0.3)) {
      showNextCard = true
      showingDefinition = false
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      currentWordIndex += 1
      withAnimation(.spring(duration: 0.3)) {
        showNextCard = false
      }
    }
  }
}

struct VocabularyWord {
  let word: String
  let definition: String
  let example: String
}

struct VocabularyCardView: View {
  let word: VocabularyWord
  let showingDefinition: Bool
  let dragOffset: CGFloat
  let cardRotation: Double

  var body: some View {
    VStack(spacing: 24) {

      // Word
      Text(word.word)
        .font(.system(size: 36, weight: .light))
        .multilineTextAlignment(.center)
        .lineLimit(nil)
        .minimumScaleFactor(0.5)

      if showingDefinition {
        VStack(spacing: 16) {
          // Definition
          Text(word.definition)
            .font(.body)
            .multilineTextAlignment(.center)
            .lineLimit(nil)
            .foregroundStyle(.secondary)
            .transition(.opacity.combined(with: .move(edge: .bottom)))

          // Example
          if !word.example.isEmpty {
            VStack(spacing: 8) {
              Text("Example")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.tertiary)

              Text("\(word.example)")
                .font(.caption)
                .italic()
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
          }
        }
        .animation(.spring(duration: 0.4).delay(0.1), value: showingDefinition)
      }

      Spacer()
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 32)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
      RoundedRectangle(cornerRadius: 24)
        .fill(.background)
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    )
    .offset(x: dragOffset)
    .rotationEffect(.degrees(cardRotation))
  }
}

struct VocaSessionCompletionView: View {
  let studiedWords: Int
  let totalWords: Int
  let vocabularyManager: VocaManager
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(spacing: 32) {

      Spacer()

      // Celebration content
      VStack(spacing: 24) {
        Image(systemName: "medal.star.fill")
          .font(.system(size: 64))
          .foregroundStyle(.yellow)
          .scaleEffect(1.0)
          .onAppear {
            withAnimation(.spring(duration: 0.8).repeatCount(3, autoreverses: true)) {
              // Animate the medal
            }
          }

        Text("Session Complete!")
          .font(.largeTitle)
          .fontWeight(.bold)

        Text("Great job studying \(studiedWords) words!")
          .font(.headline)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)

        // Stats
        VStack(spacing: 16) {
          HStack {
            Text("Words Studied")
            Spacer()
            Text("\(studiedWords)/\(totalWords)")
              .fontWeight(.semibold)
          }

          HStack {
            Text("Today's Total")
            Spacer()
            Text("\(vocabularyManager.todayWordsLearned)")
              .fontWeight(.semibold)
          }

          HStack {
            Text("Current Streak")
            Spacer()
            Text("\(vocabularyManager.currentStreak) days")
              .fontWeight(.semibold)
          }
        }
        .padding()
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(Color.secondary.opacity(0.1))
        )
      }

      Spacer()

      // Action button
      Button {
        dismiss()
      } label: {
        HStack(spacing: 12) {
          Image(systemName: "checkmark.circle.fill")
          Text("Continue")
            .fontWeight(.semibold)
        }
        .foregroundStyle(.background)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(Color.primary)
            .shadow(color: Color.primary.opacity(0.3), radius: 6, y: 3)
        )
      }
      .padding(.bottom, 20)
      .sensoryFeedback(.success, trigger: false)
    }
    .padding(.horizontal, 24)
    .background(Color(.systemBackground))
    .interactiveDismissDisabled()
  }
}

#Preview {
  VocaLearningView(vocabularyManager: VocaManager())
}
