//
//  ContentView.swift
//  Voca
//
//  Created by User on 16/05/2025.
//
import SwiftUI
import Combine

struct ContentView: View {
  var vocaManager = VocaManager()
  @State private var showingStats = false
  @State private var showingGoalSetting = false
  @State private var showingLearning = false
  @State private var animatedWordCount = 0
  @State private var targetWordCount = 0
  @State private var isFirstLoad = true
  @State private var animationTimer: AnyCancellable?
  @State private var lastHapticTens = 0
  @State private var refreshCompleted = false
  @State private var wordsBeforeRefresh = 0
  @State private var consecutiveRefreshCount = 0
  @State private var showNoStudyMessage = false

  @State private var currentHour = Calendar.current.component(.hour, from: Date())
  @State private var currentMinutes = Calendar.current.component(.minute, from: Date())

  var body: some View {
    NavigationStack {
      VStack(spacing: 8) {

        Spacer()

        ZStack {
          Clock()
          wordsLearned
            .offset(y: 30)
        }

        VStack(spacing: 8) {
          progressBar
          HStack {
            Text(generateContextualMessage())
              .font(.caption)
              .foregroundStyle(.secondary)
              .padding(.bottom, 10)
              .multilineTextAlignment(.center)
              .animation(.easeInOut(duration: 0.3), value: animatedWordCount)
              .animation(.easeInOut(duration: 0.3), value: vocaManager.isRefreshing)
              .animation(.easeInOut(duration: 0.3), value: refreshCompleted)
              .animation(.easeInOut(duration: 0.3), value: showNoStudyMessage)
          }
        }
        .padding(.horizontal,8)
        .padding(.bottom, 30)

        Spacer()

        buttons

      }
      .padding()
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color(.systemBackground))
      .navigationTitle("")
      .sheet(isPresented: $showingStats) {
        VocaStatsView(vocabularyManager: vocaManager)
      }
      .sheet(isPresented: $showingGoalSetting) {
        VocaGoalSettingView(vocabularyManager: vocaManager)
      }
      .sheet(isPresented: $showingLearning) {
        VocaLearningView(vocabularyManager: vocaManager)
      }
      .onChange(of: vocaManager.todayWordsLearned) { oldValue, newValue in
        // Start the counting animation
        startCountingAnimation(to: newValue)
      }
      .onChange(of: animatedWordCount) { oldValue, newValue in
        // Check for crossing tens boundaries
        checkAndTriggerHaptics(oldValue: oldValue, newValue: newValue)
      }
      .onChange(of: vocaManager.isRefreshing) { _, isRefreshing in
        if !isRefreshing && refreshCompleted {
          // Trigger haptic feedback when refresh completes
          let generator = UINotificationFeedbackGenerator()
          generator.notificationOccurred(.success)

          // Check if words didn't change
          if wordsBeforeRefresh == vocaManager.todayWordsLearned {
            consecutiveRefreshCount += 1
            if consecutiveRefreshCount >= 2 {
              showNoStudyMessage = true
              // Hide the message after 3 seconds
              DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                showNoStudyMessage = false
              }
            }
          } else {
            consecutiveRefreshCount = 0
            showNoStudyMessage = false
          }

          // Reset the completion flag after a delay
          DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            refreshCompleted = false
          }
        }
      }
      .sensoryFeedback(.success, trigger: vocaManager.goalJustReached)
      .onAppear {
        vocaManager.setupData()
        // Update time every minute
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
          currentHour = Calendar.current.component(.hour, from: Date())
          currentMinutes = Calendar.current.component(.minute, from: Date())
        }
      }
    }
  }

  private func generateContextualMessage() -> String {
      // Check for refresh states first
      if vocaManager.isRefreshing {
          return "Syncing vocabulary data..."
      }

      if refreshCompleted {
          return "Updated!"
      }

      if showNoStudyMessage {
          return "No new words yet. Time to study!"
      }

      // Regular contextual messages based on time and activity
      let timeString = String(format: "%02d:%02d", currentHour, currentMinutes)
      let goalProgress = vocaManager.goalProgress
      let words = animatedWordCount
      let streak = vocaManager.currentStreak

      // Early morning (5-8h)
      if currentHour >= 5 && currentHour < 8 {
          if words < 5 {
              return "Good morning! Ready to learn?"
          } else if words < 15 {
              return "\(words) words before 8am"
          } else {
              return "Great early start – \(words) words!"
          }
      }

      // Morning (8-12h)
      else if currentHour >= 8 && currentHour < 12 {
          if words < 5 {
              return "Time to expand your vocabulary"
          } else if goalProgress < 0.25 {
              return "\(words) words so far"
          } else {
              return "Strong morning – \(words) words"
          }
      }

      // Midday (12-14h)
      else if currentHour >= 12 && currentHour < 14 {
          if goalProgress >= 1.0 {
              return "Goal achieved! \(words) words"
          } else if goalProgress >= 0.5 {
              return "Halfway there – \(words) words"
          } else if words < 5 {
              return "Lunch break vocabulary?"
          } else {
              return "\(words) words at \(timeString)"
          }
      }

      // Afternoon (14-18h)
      else if currentHour >= 14 && currentHour < 18 {
          if goalProgress >= 1.0 {
              return "Daily goal complete! \(words) words"
          } else if goalProgress >= 0.75 {
              return "Almost there – \(vocaManager.dailyGoal - words) to go"
          } else if words < 5 {
              return "Afternoon study session?"
          } else {
              return "\(words) words at \(timeString)"
          }
      }

      // Evening (18-21h)
      else if currentHour >= 18 && currentHour < 21 {
          if goalProgress >= 1.0 {
              if streak > 1 {
                  return "Day \(streak) streak! \(words) words"
              } else {
                  return "Daily goal achieved!"
              }
          } else if goalProgress >= 0.8 {
              return "So close – \(vocaManager.dailyGoal - words) left"
          } else if words < 5 {
              return "Evening study time?"
          } else {
              return "\(words) words today"
          }
      }

      // Night (21-24h)
      else if currentHour >= 21 {
          if goalProgress >= 1.0 {
              return "Day complete – \(words) words"
          } else if goalProgress >= 0.9 {
              return "Just \(vocaManager.dailyGoal - words) words away"
          } else if words < 5 {
              return "Quiet evening at home"
          } else {
              return "\(words) words today"
          }
      }

      // Late night/Early morning (0-5h)
      else {
          if goalProgress >= 1.0 {
              return "Night owl – \(words) words"
          } else if words < 5 {
              return "Sleep well"
          } else {
              return "\(words) words"
          }
      }
  }

  @ViewBuilder
  private var wordsLearned: some View {
    VStack {
      Text("\(animatedWordCount)")
        .font(.system(size: 80, weight: .thin))
        .monospacedDigit()
        .contentTransition(.numericText())
        .animation(.spring(duration: 0.2), value: animatedWordCount)
    }
  }

  // Updated progress bar with fixed size
  private var progressBar: some View {
    VStack(spacing: 8) {
      ZStack(alignment: .leading) {
        // Background bar
        Capsule()
          .fill(Color.secondary.opacity(0.2))
          .frame(width: 200, height: 4)

        // Progress bar
        Capsule()
          .fill(
            vocaManager.goalProgress >= 1.0 ? Color.green : Color.primary
          )
          .frame(
            width: 200 * min(CGFloat(vocaManager.goalProgress), 1.0),
            height: 4
          )
          .animation(.spring(duration: 1.0), value: vocaManager.goalProgress)
      }
    }
    .frame(height: 4)
  }

  private var vocabularyGoal: some View {
    HStack {
      Text("Goal: \(String(vocaManager.dailyGoal))")
        .font(.caption)
        .foregroundStyle(.secondary)

      Spacer()

      // Simple last updated text
      Text("Last updated \(formatLastUpdate(vocaManager.lastRefreshTime))")
        .font(.caption2)
        .foregroundStyle(.tertiary)
    }
  }

  private var buttons: some View {
    VStack {
      Button {
        showingLearning = true
      } label: {
          Image(systemName: "graduationcap")
        .frame(width: 24, height: 24)
        .padding()
        .overlay {
          Capsule()
            .stroke(Color.primary, lineWidth: 0.5)
            .shadow(color: Color.primary.opacity(0.3), radius: 6, y: 3)
        }
      }
      .padding(.horizontal, 20)
      .scaleEffect(showingLearning ? 0.98 : 1.0)
      .animation(.bouncy, value: showingLearning)
      .sensoryFeedback(.impact(weight: .medium), trigger: showingLearning)

      HStack(spacing: 20) {
        Spacer()

        // Stats button
        Button {
          showingStats = true
        } label: {
          Image(systemName: "chart.line.uptrend.xyaxis")
            .frame(width: 24, height: 24)
            .padding()
            .background(.background)
            .clipShape(.capsule)
            .overlay {
              Capsule()
                .stroke(lineWidth: 0.5)
                .shadow(color: Color.primary.opacity(0.3), radius: 6, y: 3)
            }
        }
        .sensoryFeedback(.selection, trigger: showingStats)

        // Goal button
        Button {
          showingGoalSetting = true
        } label: {
          Image(systemName: "target")
            .frame(width: 24, height: 24)
            .padding()
            .background(.background)
            .clipShape(.capsule)
            .overlay {
              Capsule()
                .stroke(lineWidth: 0.5)
                .shadow(color: Color.primary.opacity(0.3), radius: 6, y: 3)
            }
        }
        .sensoryFeedback(.selection, trigger: showingGoalSetting)

        Spacer()
      }
      .padding(.bottom, 10)
    }
    .foregroundStyle(.foreground)
  }

  private func checkAndTriggerHaptics(oldValue: Int, newValue: Int) {
    let oldTens = oldValue / 10
    let newTens = newValue / 10

    if newTens > oldTens {
      // Cross-tens haptic
      let generator = UIImpactFeedbackGenerator(style: .light)
      generator.impactOccurred()

      // For milestone tens, use stronger feedback
      if newValue % 50 == 0 {
        let notificationGenerator = UINotificationFeedbackGenerator()
        notificationGenerator.notificationOccurred(.success)
      }
    }
  }

  private func startCountingAnimation(to targetValue: Int) {
    // Cancel any existing animation
    animationTimer?.cancel()

    // Set the target value
    targetWordCount = targetValue

    // If it's the first load, start from 0
    let startValue = isFirstLoad ? 0 : animatedWordCount

    // Calculate the step size
    let totalDifference = targetValue - startValue

    // Don't animate if there's no change or very small change
    if totalDifference == 0 {
      return
    }

    // Choose animation duration and steps based on difference magnitude
    let duration: Double
    let numberOfSteps: Int

    if abs(totalDifference) > 50 {
      // For large differences, use more steps over longer duration
      duration = isFirstLoad ? 2.0 : 1.2
      numberOfSteps = 60
    } else {
      // For smaller differences, use fewer steps
      duration = isFirstLoad ? 1.5 : 0.8
      numberOfSteps = min(40, max(15, abs(totalDifference)))
    }

    // Ensure we have at least one step
    let actualSteps = min(numberOfSteps, abs(totalDifference))

    // Calculate interval between updates
    let interval = duration / Double(actualSteps)

    // Create exponential ease-out increments for smoother animation
    let incrementsArray = createEaseOutIncrements(start: startValue, end: targetValue, steps: actualSteps)
    var currentIndex = 0

    // Create timer with fixed small interval for smooth transitions
    animationTimer = Timer.publish(every: interval, on: .main, in: .common)
      .autoconnect()
      .sink { _ in
        if currentIndex < incrementsArray.count {
          // Update with the pre-calculated increment
          animatedWordCount = incrementsArray[currentIndex]
          currentIndex += 1
        } else {
          // Ensure we end exactly on the target
          animatedWordCount = targetWordCount
          animationTimer?.cancel()
          isFirstLoad = false
        }
      }
  }

  // Creates an array of values with exponential ease-out for smoother animation
  private func createEaseOutIncrements(start: Int, end: Int, steps: Int) -> [Int] {
    var result: [Int] = []
    let difference = Double(end - start)

    for i in 0..<steps {
      let progress = Double(i) / Double(steps - 1)
      // Ease out function: 1 - pow(1 - t, 3)
      let easeOut = 1.0 - pow(1.0 - progress, 3.0)
      let value = start + Int(difference * easeOut)
      result.append(value)
    }

    // Ensure the last value is exactly the end value
    if let last = result.last, last != end {
      result[result.count - 1] = end
    }

    return result
  }

  // Format the last update time
  private func formatLastUpdate(_ date: Date) -> String {
    let now = Date()
    let timeInterval = now.timeIntervalSince(date)

    if timeInterval < 60 {
      return "just now"
    } else if timeInterval < 3600 {
      let minutes = Int(timeInterval / 60)
      return "\(minutes)m ago"
    } else {
      let hours = Int(timeInterval / 3600)
      return "\(hours)h ago"
    }
  }
}

#Preview {
  ContentView()
}
