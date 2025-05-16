//
//  VocabularyStatsView.swift
//  Voca
//
//  Created by User on 16/05/2025.
//

import SwiftUI
import Charts

// Create a proper struct for vocabulary data points
struct VocabularyDataPoint: Identifiable, Equatable {
  var id = UUID()
  var date: Date
  var words: Int

  static func == (lhs: VocabularyDataPoint, rhs: VocabularyDataPoint) -> Bool {
    lhs.date == rhs.date && lhs.words == rhs.words
  }
}

struct VocaStatsView: View {
  var vocabularyManager: VocaManager
  @Environment(\.dismiss) private var dismiss
  @State private var selectedRange: TimeRange = .week
  @State private var animateChart = false

  enum TimeRange: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"
    case year = "Year"

    var id: String { self.rawValue }
  }

  var displayData: [VocabularyDataPoint] {
    switch selectedRange {
    case .week:
      return vocabularyManager.weeklyData.map { VocabularyDataPoint(date: $0.date, words: $0.words) }
    case .month:
      return vocabularyManager.monthlyData.map { VocabularyDataPoint(date: $0.date, words: $0.words) }
    case .year:
      return vocabularyManager.yearlyData.map { VocabularyDataPoint(date: $0.date, words: $0.words) }
    }
  }

  var averageWords: Int {
    switch selectedRange {
    case .week: return vocabularyManager.weeklyAverage
    case .month: return vocabularyManager.monthlyAverage
    case .year: return vocabularyManager.yearlyDailyAverage
    }
  }

  // Determine if user is making progress
  var isProgressing: Bool {
    guard !displayData.isEmpty, displayData.count > 1 else { return false }

    // For weekly/monthly, compare most recent to previous
    if selectedRange != .year {
      let recentDays = displayData.prefix(displayData.count/2)
      let olderDays = displayData.suffix(displayData.count/2)
      let recentTotal = recentDays.reduce(0) { $0 + $1.words }
      let olderTotal = olderDays.reduce(0) { $0 + $1.words }
      return recentTotal >= olderTotal
    } else {
      // For yearly, compare this month to last month
      if displayData.count >= 2 {
        return displayData[0].words >= displayData[1].words
      }
      return false
    }
  }

  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 30) {

        Picker("Time Range", selection: $selectedRange) {
          ForEach(TimeRange.allCases) { range in
            Text(range.rawValue).tag(range)
          }
        }
        .pickerStyle(.segmented)
        .padding(.bottom, 10)
        .sensoryFeedback(.selection, trigger: selectedRange)
        .onChange(of: selectedRange) { _, _ in
          // Reset and trigger animation
          withAnimation(.spring(duration: 0.3)) {
            animateChart = false
          }
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(duration: 0.8)) {
              animateChart = true
            }
          }
        }

        if selectedRange == .year && vocabularyManager.availableYears.count > 1 {
          Menu {
            ForEach(vocabularyManager.availableYears, id: \.self) { year in
              Button(action: {
                // Reset animation first
                withAnimation(.spring(duration: 0.3)) {
                  animateChart = false
                }

                // Fetch data for new year
                vocabularyManager.fetchYearData(year: year)

                // Animate chart after data updates
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                  withAnimation(.spring(duration: 0.8)) {
                    animateChart = true
                  }
                }
              }) {
                Text("\(year)")
                  .tag(year)
              }
            }
          } label: {
            HStack {
              Text("\(String(vocabularyManager.selectedYear))")
                .foregroundColor(.primary)
              Image(systemName: "chevron.down")
                .font(.caption)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
              RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
          }
          .padding(.bottom, 10)
        }

        // Average
        VStack(alignment: .leading, spacing: 4) {
          Text("AVERAGE WORDS")
            .font(.caption)
            .foregroundStyle(.secondary)

          Text("\(averageWords)")
            .font(.system(size: 34, weight: .light))
            .monospacedDigit()
            .contentTransition(.numericText())
            .animation(.spring(duration: 0.5), value: averageWords)
        }

        // Progress Graph
        VStack(alignment: .leading, spacing: 4) {
          Text("LEARNING PROGRESS")
            .font(.caption)
            .foregroundStyle(.secondary)

          // Simple minimalist chart
          if !displayData.isEmpty {
            VocabularyChartView(
              data: displayData.sorted(by: { $0.date < $1.date }),
              isProgressing: isProgressing,
              range: selectedRange,
              animate: animateChart
            )
            .frame(height: 120)
            .onAppear {
              // Trigger chart animation when view appears
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(duration: 0.8)) {
                  animateChart = true
                }
              }
            }
          } else {
            Text("No data available")
              .foregroundStyle(.secondary)
              .frame(height: 120)
          }
        }

        // History
        VStack(alignment: .leading, spacing: 4) {
          Text("HISTORY")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.bottom, 8)

          ScrollView {
            LazyVStack(spacing: 0) {
              ForEach(displayData.sorted(by: { $0.date > $1.date })) { item in
                HStack {
                  Text(formatDate(item.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 80, alignment: .leading)

                  Text(formatWords(item.words))
                    .font(.system(.body, design: .monospaced))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                }
                .padding(.vertical, 4)
                .transition(.opacity)
                .id(item.id)
              }
            }
            .animation(.easeInOut, value: selectedRange)
          }
        }

        Spacer()
      }
      .padding(30)
      .frame(maxWidth: .infinity, alignment: .leading)
      .navigationTitle("Statistics")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") {
            dismiss()
          }
          .sensoryFeedback(.selection, trigger: UUID())
        }
      }
    }
  }

  // Format date based on selected range
  func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    switch selectedRange {
    case .week:
      formatter.dateFormat = "E, MMM d" // "Mon, May 9"
    case .month:
      formatter.dateFormat = "MMM d" // "May 9"
    case .year:
      formatter.dateFormat = "MMM yyyy" // "May 2025"
    }
    return formatter.string(from: date)
  }

  // Format words with proper labeling
  func formatWords(_ words: Int) -> String {
    if words == 1 {
      return "1 word"
    } else {
      return "\(words) words"
    }
  }
}

// Improved chart with better animations for vocabulary
struct VocabularyChartView: View {
  var data: [VocabularyDataPoint]
  var isProgressing: Bool
  var range: VocaStatsView.TimeRange
  var animate: Bool

  @State private var animationProgress: CGFloat = 0

  private var chartColor: Color {
    isProgressing ? Color.green : Color.red
  }

  private var maxWords: Int {
    return max((data.map { $0.words }.max() ?? 0) + 10, 50)
  }

  var body: some View {
    Chart {
      ForEach(data) { item in
        AreaMark(
          x: .value("Date", item.date),
          y: .value("Words", animate ? item.words : 0)
        )
        .foregroundStyle(
          LinearGradient(
            colors: [chartColor.opacity(0.3), .clear],
            startPoint: .top,
            endPoint: .bottom
          )
        )
        .interpolationMethod(.catmullRom)

        LineMark(
          x: .value("Date", item.date),
          y: .value("Words", animate ? item.words : 0)
        )
        .foregroundStyle(chartColor.opacity(0.8))
        .lineStyle(StrokeStyle(lineWidth: 2))
        .interpolationMethod(.catmullRom)

        if animate {
          PointMark(
            x: .value("Date", item.date),
            y: .value("Words", item.words)
          )
          .foregroundStyle(chartColor)
          .symbolSize(30)
        }
      }
    }
    .chartYScale(domain: 0...maxWords)
    .chartXAxis {
      AxisMarks { _ in
        AxisValueLabel()
      }
    }
    .chartXAxis {
      AxisMarks(preset: .aligned) { value in
        if let date = value.as(Date.self) {
          AxisValueLabel {
            Text(formatDateForChart(date))
          }
        }
      }
    }
    .animation(.spring(duration: 1.0), value: animate)
    .animation(.spring(duration: 0.5), value: data)
    .onChange(of: animate) { _, newValue in
      if newValue {
        // Reset animation progress if animate is true
        animationProgress = 1.0
      } else {
        // Reset animation progress if animate is false
        animationProgress = 0.0
      }
    }
  }

  // Format date specifically for chart display
  func formatDateForChart(_ date: Date) -> String {
    let formatter = DateFormatter()
    switch range {
    case .week:
      formatter.dateFormat = "E" // "Mon"
    case .month:
      formatter.dateFormat = "d" // "9"
    case .year:
      formatter.dateFormat = "MMM" // "May"
    }
    return formatter.string(from: date)
  }
}

#Preview {
  VocaStatsView(vocabularyManager: VocaManager())
}
