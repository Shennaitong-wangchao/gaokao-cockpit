import SwiftUI

struct MistakeFilterBar: View {
    @Binding var selectedSubjectFilter: LearningSubject?
    @Binding var selectedReviewFilter: ReviewStatus?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("筛选")
                .font(.headline)

            HStack(spacing: 10) {
                Menu {
                    Button {
                        selectedSubjectFilter = nil
                    } label: {
                        Label("全部", systemImage: selectedSubjectFilter == nil ? "checkmark" : "book.closed")
                    }

                    ForEach(LearningSubject.allCases) { subject in
                        Button {
                            selectedSubjectFilter = subject
                        } label: {
                            Label(subject.displayName, systemImage: selectedSubjectFilter == subject ? "checkmark" : "book.closed")
                        }
                    }
                } label: {
                    Label("科目：\(selectedSubjectFilter?.displayName ?? "全部")", systemImage: "book.closed")
                        .frame(maxWidth: .infinity)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .buttonStyle(.bordered)

                Menu {
                    Button {
                        selectedReviewFilter = nil
                    } label: {
                        Label("全部", systemImage: selectedReviewFilter == nil ? "checkmark" : "arrow.triangle.2.circlepath")
                    }

                    ForEach(ReviewStatus.allCases) { status in
                        Button {
                            selectedReviewFilter = status
                        } label: {
                            Label(status.displayName, systemImage: selectedReviewFilter == status ? "checkmark" : "arrow.triangle.2.circlepath")
                        }
                    }
                } label: {
                    Label("状态：\(selectedReviewFilter?.displayName ?? "全部")", systemImage: "arrow.triangle.2.circlepath")
                        .frame(maxWidth: .infinity)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .buttonStyle(.bordered)
            }
        }
    }
}
