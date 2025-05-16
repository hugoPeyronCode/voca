//
//  SquareButton.swift
//  voca
//
//  Created by Hugo Peyron on 16/05/2025.
//

import SwiftUI

struct SquareButton: View {

  let content: String?
  let image: String?
  let subtitle: String?
  let isSelected: Bool = true
  let action: () -> Void

  var body : some View {
    Button {
      action()
    } label: {
      VStack(spacing: 4) {
        HStack{
          if let image {
            Image(systemName: image)
          }

          if let content {
            Text("\(content)")
          }
        }
        .font(.system(size: 18, weight: .semibold))

        .foregroundStyle(
          isSelected ? Color(.systemBackground) : Color.primary
        )

        if let subtitle {
          Text("\(subtitle)")
            .font(.caption)
            .foregroundStyle(
              isSelected ? Color(.systemBackground).opacity(0.7) : Color.secondary
            )
        }
      }
      .frame(width: 90, height: 60)
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(isSelected ? Color.primary : Color.secondary.opacity(0.1))
          .shadow(
            color: isSelected ? Color.primary.opacity(0.3) : Color.clear,
            radius: isSelected ? 8 : 0
          )
      )
      .overlay(
        RoundedRectangle(cornerRadius: 16)
          .stroke(
            isSelected ? Color.clear : Color.secondary.opacity(0.2),
            lineWidth: 1
          )
      )
      .scaleEffect(isSelected ? 1.05 : 1.0)
      .animation(.spring(duration: 0.3), value: isSelected)
    }
  }
}
