//
//  VocabularyGoalSettingView.swift
//  Voca
//
//  Created by User on 16/05/2025.
//
import SwiftUI

struct VocaGoalSettingView: View {
  let vocabularyManager: VocaManager
  @Environment(\.dismiss) private var dismiss
  @State private var selectedGoal: Int
  @State private var animateSelection = false

  let goalOptions = [1, 2, 3, 4, 5, 10, 20, 30, 50]

  init(vocabularyManager: VocaManager) {
    self.vocabularyManager = vocabularyManager
    self._selectedGoal = State(initialValue: vocabularyManager.dailyGoal)
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {

        // Top section with current goal
        VStack(spacing: 20) {

          VStack(spacing: 8) {
            Text("Daily Goal")
              .font(.headline)
              .fontWeight(.medium)
              .foregroundStyle(.secondary)

            Text("\(selectedGoal)")
              .font(.system(size: 80, weight: .ultraLight))
              .monospacedDigit()
              .contentTransition(.numericText())
              .animation(.spring(duration: 0.4), value: selectedGoal)
              .scaleEffect(animateSelection ? 1.1 : 1.0)
              .animation(.spring(duration: 0.3), value: animateSelection)

            Text("words per day")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }

          // Progress indicator showing what percentage of common goals this represents
          VStack(spacing: 8) {
            Text(getGoalDescription(selectedGoal))
              .font(.caption)
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)
              .animation(.easeInOut(duration: 0.3), value: selectedGoal)

            // Visual progress bar
            ZStack(alignment: .leading) {
              Capsule()
                .fill(Color.secondary.opacity(0.2))
                .frame(height: 4)

              Capsule()
                .fill(Color.primary)
                .frame(height: 4)
                .containerRelativeFrame([.horizontal]) { length, _ in
                  let progress = Double(selectedGoal) / 100.0
                  return length * min(progress, 1.0)
                }
                .animation(.spring(duration: 0.5), value: selectedGoal)
            }
            .frame(maxWidth: 200)
          }
        }
        .containerRelativeFrame([.vertical]) { height, _ in
          height * 0.4
        }

        // Goal selection grid
        VStack(spacing: 20) {
          Text("Choose your daily vocabulary goal")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

          LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
            spacing: 16
          ) {
            ForEach(goalOptions, id: \.self) { goal in
              Button {
                withAnimation(.spring(duration: 0.3)) {
                  selectedGoal = goal
                  animateSelection = true
                }

                // Reset animation after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                  withAnimation(.spring(duration: 0.2)) {
                    animateSelection = false
                  }
                }
              } label: {
                VStack(spacing: 4) {
                  Text("\(goal)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(
                      selectedGoal == goal ? Color(.systemBackground) : Color.primary
                    )

                  Text("words")
                    .font(.caption2)
                    .foregroundStyle(
                      selectedGoal == goal ? Color(.systemBackground).opacity(0.7) : Color.secondary
                    )
                }
                .frame(width: 90, height: 60)
                .background(
                  RoundedRectangle(cornerRadius: 16)
                    .fill(selectedGoal == goal ? Color.primary : Color.secondary.opacity(0.1))
                    .shadow(
                      color: selectedGoal == goal ? Color.primary.opacity(0.3) : Color.clear,
                      radius: selectedGoal == goal ? 8 : 0
                    )
                )
                .overlay(
                  RoundedRectangle(cornerRadius: 16)
                    .stroke(
                      selectedGoal == goal ? Color.clear : Color.secondary.opacity(0.2),
                      lineWidth: 1
                    )
                )
                .scaleEffect(selectedGoal == goal ? 1.05 : 1.0)
                .animation(.spring(duration: 0.3), value: selectedGoal)
              }
              .sensoryFeedback(.selection, trigger: selectedGoal)
            }
          }
          .padding(.horizontal, 20)
        }
        .containerRelativeFrame([.vertical]) { height, _ in
          height * 0.5
        }

        // Bottom section with save button
        VStack(spacing: 16) {
          Text("You can always change this later in settings")
            .font(.caption)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)

          Button {
            withAnimation(.spring(duration: 0.3)) {
              vocabularyManager.updateDailyGoal(selectedGoal)
              dismiss()
            }
          } label: {
            HStack(spacing: 8) {
              Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
              Text("Save Goal")
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
          .scaleEffect(animateSelection ? 0.98 : 1.0)
          .animation(.spring(duration: 0.2), value: animateSelection)
          .sensoryFeedback(.success, trigger: false)
        }
        .containerRelativeFrame([.vertical]) { height, _ in
          height * 0.1
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color(.systemBackground))
      .navigationTitle("Set Daily Goal")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Cancel") {
            dismiss()
          }
          .foregroundStyle(.secondary)
        }
      }
    }
    .onAppear {
      withAnimation(.spring(duration: 0.6)) {
        animateSelection = true
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
        withAnimation(.spring(duration: 0.3)) {
          animateSelection = false
        }
      }
    }
  }

  private func getGoalDescription(_ goal: Int) -> String {
    switch goal {
    case 1...10:
      return "Perfect for beginners\nBuild a sustainable habit"
    case 11...20:
      return "Steady progress\nIdeal for busy schedules"
    case 21...35:
      return "Committed learner\nBalanced growth"
    case 36...50:
      return "Ambitious pace\nFast vocabulary expansion"
    case 51...75:
      return "Intensive learning\nRapid fluency building"
    default:
      return "Expert level\nMaximum vocabulary growth"
    }
  }
}

#Preview {
  VocaGoalSettingView(vocabularyManager: VocaManager())
}
