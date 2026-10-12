import SwiftUI

public struct StatusCategoryBar: View {
    @ObservedObject var viewModel: MRTrackerViewModel

    public var body: some View {
        HStack(spacing: 4) {
            categoryButton(.all, count: viewModel.mergeRequests.count, color: .primary)
            categoryButton(.blocked, count: viewModel.blockedCount, color: .red)
            categoryButton(.needsReview, count: viewModel.needsReviewCount, color: .orange)
            categoryButton(.mergeReady, count: viewModel.mergeReadyCount, color: .green)
            categoryButton(.drafts, count: viewModel.draftsCount, color: .secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func categoryButton(_ cat: StatusCategory, count: Int, color: Color) -> some View {
        let isSelected = viewModel.selectedCategory == cat

        Button(action: {
            viewModel.selectedCategory = cat
        }) {
            HStack(spacing: 3) {
                Image(systemName: cat.iconName)
                    .font(.system(size: 9))
                Text(cat.rawValue)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 9, weight: .bold))
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(isSelected ? color.opacity(0.18) : Color.clear)
            .foregroundColor(isSelected ? color : .secondary)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}
