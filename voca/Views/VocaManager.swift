//
//  VocabularyManager.swift
//  Voca
//
//  Created by User on 16/05/2025.
//
import SwiftUI
import Foundation

@Observable
class VocaManager {
    // MARK: - Properties
    var todayWordsLearned: Int = 0
    var dailyGoal: Int = 30
    var currentStreak: Int = 0
    var totalWordsLearned: Int = 0
    var correctAnswers: Int = 0
    var totalAnswers: Int = 0
    var isRefreshing: Bool = false
    var lastRefreshTime: Date = Date()
    var goalJustReached: Bool = false

    // Computed properties
    var goalProgress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(1.0, Double(todayWordsLearned) / Double(dailyGoal))
    }

    var accuracy: Double {
        guard totalAnswers > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalAnswers)
    }

    // MARK: - Initialization
    init() {
        loadData()
    }

    // MARK: - Setup
    func setupData() {
        loadData()
        refreshDataInBackground()
    }

    // MARK: - Data Management
    private func loadData() {
        // Load persisted data from UserDefaults
        dailyGoal = UserDefaults.standard.integer(forKey: "vocabulary_daily_goal")
        if dailyGoal == 0 { dailyGoal = 30 } // Default goal

        todayWordsLearned = loadTodayWordsLearned()
        currentStreak = UserDefaults.standard.integer(forKey: "vocabulary_current_streak")
        totalWordsLearned = UserDefaults.standard.integer(forKey: "vocabulary_total_words")
        correctAnswers = UserDefaults.standard.integer(forKey: "vocabulary_correct_answers")
        totalAnswers = UserDefaults.standard.integer(forKey: "vocabulary_total_answers")

        if let lastRefreshData = UserDefaults.standard.object(forKey: "vocabulary_last_refresh") as? Data {
          lastRefreshTime = try! JSONDecoder().decode(Date.self, from: lastRefreshData)
        }
    }

    private func loadTodayWordsLearned() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        let lastStudyDateData = UserDefaults.standard.object(forKey: "vocabulary_last_study_date") as? Data

        if let lastStudyDateData = lastStudyDateData,
           let lastStudyDate = try? JSONDecoder().decode(Date.self, from: lastStudyDateData) {
            let lastStudyDay = Calendar.current.startOfDay(for: lastStudyDate)

            if Calendar.current.isDate(today, equalTo: lastStudyDay, toGranularity: .day) {
                return UserDefaults.standard.integer(forKey: "vocabulary_today_words")
            }
        }

        // If it's a new day, reset today's count
        saveTodayWordsLearned(0)
        return 0
    }

    private func saveData() {
        UserDefaults.standard.set(dailyGoal, forKey: "vocabulary_daily_goal")
        UserDefaults.standard.set(currentStreak, forKey: "vocabulary_current_streak")
        UserDefaults.standard.set(totalWordsLearned, forKey: "vocabulary_total_words")
        UserDefaults.standard.set(correctAnswers, forKey: "vocabulary_correct_answers")
        UserDefaults.standard.set(totalAnswers, forKey: "vocabulary_total_answers")

        saveTodayWordsLearned(todayWordsLearned)

        if let encoded = try? JSONEncoder().encode(lastRefreshTime) {
            UserDefaults.standard.set(encoded, forKey: "vocabulary_last_refresh")
        }
    }

    private func saveTodayWordsLearned(_ count: Int) {
        UserDefaults.standard.set(count, forKey: "vocabulary_today_words")

        // Save today's date
        let today = Date()
        if let encoded = try? JSONEncoder().encode(today) {
            UserDefaults.standard.set(encoded, forKey: "vocabulary_last_study_date")
        }
    }

    // MARK: - Public Methods
    func addWordLearned() {
        let wasGoalReached = todayWordsLearned >= dailyGoal
        todayWordsLearned += 1
        totalWordsLearned += 1

        if !wasGoalReached && todayWordsLearned >= dailyGoal {
            goalJustReached = true
            // Reset the flag after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.goalJustReached = false
            }
        }

        saveData()
    }

    func addCorrectAnswer() {
        correctAnswers += 1
        totalAnswers += 1
        saveData()
    }

    func addIncorrectAnswer() {
        totalAnswers += 1
        saveData()
    }

    func updateDailyGoal(_ newGoal: Int) {
        dailyGoal = max(1, newGoal)
        saveData()
    }

    func updateStreak(_ streak: Int) {
        currentStreak = max(0, streak)
        saveData()
    }

    @MainActor
    func refreshAllData() async {
        isRefreshing = true

        // Simulate network request delay
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds

        // In a real app, this would sync with your backend
        // For now, we'll just update the last refresh time
        lastRefreshTime = Date()

        // Simulate small variations in data
        if Int.random(in: 1...10) == 1 {
            // 10% chance of finding new data
            todayWordsLearned += Int.random(in: 1...3)
        }

        saveData()
        isRefreshing = false
    }

    // MARK: - Background Refresh
    private func refreshDataInBackground() {
        Task {
            // Check if we need to refresh (if last refresh was more than 5 minutes ago)
            let timeInterval = Date().timeIntervalSince(lastRefreshTime)
            if timeInterval > 300 { // 5 minutes
                await refreshAllData()
            }
        }
    }

    // MARK: - Statistics
    struct VocabularyRecord {
        let date: Date
        let words: Int
    }

    var weeklyData: [VocabularyRecord] {
        // Generate mock data for the past 7 days
        var data: [VocabularyRecord] = []
        let calendar = Calendar.current

        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -6 + i, to: Date()) {
                let words = i == 6 ? todayWordsLearned : Int.random(in: 0...dailyGoal)
                data.append(VocabularyRecord(date: date, words: words))
            }
        }
        return data
    }

    var monthlyData: [VocabularyRecord] {
        // Generate mock data for the past 30 days
        var data: [VocabularyRecord] = []
        let calendar = Calendar.current

        for i in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: -29 + i, to: Date()) {
                let words = i == 29 ? todayWordsLearned : Int.random(in: 0...dailyGoal)
                data.append(VocabularyRecord(date: date, words: words))
            }
        }
        return data
    }

    var yearlyData: [VocabularyRecord] {
        // Generate mock data for the past 12 months
        var data: [VocabularyRecord] = []
        let calendar = Calendar.current

        for i in 0..<12 {
            if let date = calendar.date(byAdding: .month, value: -11 + i, to: Date()) {
                let monthlyWords = Int.random(in: dailyGoal * 20...dailyGoal * 31)
                data.append(VocabularyRecord(date: date, words: monthlyWords))
            }
        }
        return data
    }

    var weeklyAverage: Int {
        let total = weeklyData.reduce(0) { $0 + $1.words }
        return weeklyData.isEmpty ? 0 : total / weeklyData.count
    }

    var monthlyAverage: Int {
        let total = monthlyData.reduce(0) { $0 + $1.words }
        return monthlyData.isEmpty ? 0 : total / monthlyData.count
    }

    var yearlyDailyAverage: Int {
        let total = yearlyData.reduce(0) { $0 + $1.words }
        let days = yearlyData.count * 30 // Approximate days per month
        return days == 0 ? 0 : total / days
    }

    var availableYears: [Int] {
        return [2023, 2024, 2025] // Mock available years
    }

    var selectedYear: Int = 2025

    func fetchYearData(year: Int) {
        selectedYear = year
        // In a real app, this would fetch data for the specific year
    }
}
