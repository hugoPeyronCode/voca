//
//  CircularClockView.swift
//  SmartBreak
//
//  Created by Hugo Peyron on 14/05/2025.
//
import SwiftUI

// Vue avec un demi-cercle et 24 barres individuelles représentant chaque heure
struct Clock: View {
  @State private var currentHour = Calendar.current.component(.hour, from: Date())
  @State private var currentMinutes = Calendar.current.component(.minute, from: Date())
  @State private var timer: Timer?
  @State private var showHours = false

  let radius: CGFloat = 130
  let barHeight: CGFloat = 15
  let barWidth: CGFloat = 1
  let numberOfHours = 24

  var body: some View {
    VStack(spacing: 20) {
      ZStack {
        ForEach(0..<numberOfHours, id: \.self) { hour in
          hourBar(for: hour)
            .position(positionForHour(hour))
        }

      }
      .onTapGesture {
        showHours.toggle()
      }
      .frame(width: (radius + barHeight) * 2, height: radius + 60)
      .sensoryFeedback(.selection, trigger: showHours)
    }
    .onAppear {
      startTimer()
    }
    .onDisappear {
      timer?.invalidate()
    }
    .padding(.horizontal)
  }

  @ViewBuilder
  private func hourBar(for hour: Int) -> some View {
    let isPassed = hour < currentHour
    let rotationAngle = rotationAngleForHour(hour)

    Capsule()
      .foregroundStyle(isPassed ? .primary : .tertiary)
      .frame(width: isPassed ? barWidth * 2 : barWidth, height: isPassed ? barHeight : barHeight * 0.75)
      .clipShape(RoundedRectangle(cornerRadius: barWidth / 2))
      .rotationEffect(.radians(-rotationAngle))
      .animation(.spring(duration: 0.5, bounce: 0.1), value: isPassed)
  }

  @ViewBuilder
  private func hourLabel(for hour: Int) -> some View {
    let isPassed = hour < currentHour
    Text("\(hour)")
      .font(.system(size: 10, weight: .medium))
      .foregroundStyle(isPassed ? .primary : .tertiary)
      .monospacedDigit()
      .animation(.easeInOut(duration: 0.3), value: showHours)
  }

  private func rotationAngleForHour(_ hour: Int) -> CGFloat {
      // Angle de base pour chaque heure (demi-cercle de π radians)
      let baseAngle = CGFloat(Double.pi) - (CGFloat(hour) / CGFloat(numberOfHours - 1)) * CGFloat(Double.pi)
      return baseAngle - CGFloat(Double.pi / 2)
  }

  private func positionForHour(_ hour: Int) -> CGPoint {
      // Angle pour chaque heure (demi-cercle de π radians)
      let angle = CGFloat(Double.pi) - (CGFloat(hour) / CGFloat(numberOfHours - 1)) * CGFloat(Double.pi)

      // Position sur le cercle
      let centerX = (radius + barHeight)
      let centerY = radius + 30

    let x = centerX + (radius + barHeight * 1.3) * cos(angle)
    let y = centerY - (radius + barHeight * 1.3) * sin(angle)

      return CGPoint(x: x, y: y)
  }

  private func hourLabelPosition(for hour: Int) -> CGPoint {
      // Same angle calculation as bars
      let angle = CGFloat(Double.pi) - (CGFloat(hour) / CGFloat(numberOfHours - 1)) * CGFloat(Double.pi)

      // Position labels slightly outside the bars
      let centerX = (radius + barHeight)
      let centerY = radius + 30
      let labelRadius = radius + barHeight * 2.2

      let x = centerX + labelRadius * cos(angle)
      let y = centerY - labelRadius * sin(angle)

      return CGPoint(x: x, y: y)
  }

  private func startTimer() {
    timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
      currentHour = Calendar.current.component(.hour, from: Date())
    }
  }
}

#Preview {
  Clock()
    .padding()
}
