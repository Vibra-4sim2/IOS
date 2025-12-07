//
//  StarRatingView.swift
//  VIBRA
//

import SwiftUI

struct StarRatingView: View {
    let rating: Double
    let maxRating: Int = 5
    let size: CGFloat
    let color: Color
    
    init(rating: Double, size: CGFloat = 16, color: Color = .yellow) {
        self.rating = rating
        self.size = size
        self.color = color
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<maxRating, id: \.self) { index in
                starImage(for: index)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .foregroundColor(color)
            }
        }
    }
    
    private func starImage(for index: Int) -> Image {
        let fillAmount = rating - Double(index)
        
        if fillAmount >= 1.0 {
            return Image(systemName: "star.fill")
        } else if fillAmount > 0.0 {
            return Image(systemName: "star.leadinghalf.filled")
        } else {
            return Image(systemName: "star")
        }
    }
}

// MARK: - Preview
struct StarRatingView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            StarRatingView(rating: 0.0)
            StarRatingView(rating: 2.5)
            StarRatingView(rating: 4.2)
            StarRatingView(rating: 5.0)
            
            StarRatingView(rating: 4.2, size: 24, color: AppColors.GreenAccent)
        }
        .padding()
        .background(AppColors.BackgroundDark)
    }
}
