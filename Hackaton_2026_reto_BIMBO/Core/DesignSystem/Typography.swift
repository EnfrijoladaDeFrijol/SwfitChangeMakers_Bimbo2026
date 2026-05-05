import SwiftUI

// MARK: - Font scale (SF Pro — Design System Bimbo)
extension Font {
    static let heroNumber   = Font.system(size: 72, weight: .black,  design: .rounded)
    static let stockCount   = Font.system(size: 52, weight: .heavy,  design: .rounded)
    static let productName  = Font.system(size: 22, weight: .bold,   design: .default)
    static let sectionTitle = Font.system(size: 18, weight: .semibold)
    static let badgeLabel   = Font.system(size: 13, weight: .medium)
}
// View helpers viven en Color+Theme.swift para mantener cohesión del Design System.
