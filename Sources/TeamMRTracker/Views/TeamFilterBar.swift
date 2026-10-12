import SwiftUI

public struct TeamFilterBar: View {
    @ObservedObject var viewModel: MRTrackerViewModel

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                // "All" chip
                let totalCount = viewModel.mergeRequests.count
                Button(action: {
                    viewModel.selectedMemberUsername = nil
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 10))
                        Text("All")
                            .font(.system(size: 11, weight: .medium))
                        Text("\(totalCount)")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(viewModel.selectedMemberUsername == nil ? Color.accentColor.opacity(0.3) : Color.secondary.opacity(0.15))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(viewModel.selectedMemberUsername == nil ? Color.accentColor.opacity(0.2) : Color(NSColor.controlBackgroundColor))
                    .foregroundColor(viewModel.selectedMemberUsername == nil ? .accentColor : .primary)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(viewModel.selectedMemberUsername == nil ? Color.accentColor : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                // Individual Team Members
                ForEach(viewModel.config.teamMembers) { member in
                    let count = viewModel.count(for: member.username)
                    let hasBlocked = viewModel.hasBlocked(for: member.username)
                    let isSelected = viewModel.selectedMemberUsername == member.username

                    Button(action: {
                        if isSelected {
                            viewModel.selectedMemberUsername = nil
                        } else {
                            viewModel.selectedMemberUsername = member.username
                        }
                    }) {
                        HStack(spacing: 5) {
                            if hasBlocked {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 6, height: 6)
                            }

                            Text(member.displayName.components(separatedBy: " ").first ?? member.displayName)
                                .font(.system(size: 11, weight: .medium))

                            if count > 0 {
                                Text("\(count)")
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(hasBlocked ? Color.red.opacity(0.2) : (isSelected ? Color.accentColor.opacity(0.3) : Color.secondary.opacity(0.15)))
                                    .foregroundColor(hasBlocked ? .red : (isSelected ? .accentColor : .secondary))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(isSelected ? Color.accentColor.opacity(0.2) : Color(NSColor.controlBackgroundColor))
                        .foregroundColor(isSelected ? .accentColor : .primary)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .help("\(member.displayName) (@\(member.username)) - \(count) active MRs")
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 4)
        }
    }
}
