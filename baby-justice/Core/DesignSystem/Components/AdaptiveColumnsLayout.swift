import SwiftUI

struct AdaptiveColumnsLayout: Layout {
    var minimumColumnWidth: CGFloat
    var maximumColumns: Int
    var spacing: CGFloat = BJSpacing.m

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        let width = resolvedWidth(proposal.width, subviews: subviews)
        let rows = rows(for: subviews, width: width)
        let height = rows.reduce(CGFloat.zero) { $0 + $1.height }
            + CGFloat(max(0, rows.count - 1)) * spacing
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = rows(for: subviews, width: bounds.width)
        let width = columnWidth(for: subviews, width: bounds.width)
        var y = bounds.minY
        for row in rows {
            for (column, index) in row.indices.enumerated() {
                subviews[index].place(
                    at: CGPoint(x: bounds.minX + CGFloat(column) * (width + spacing), y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(width: width, height: row.height)
                )
            }
            y += row.height + spacing
        }
    }

    private func columnCount(for subviews: Subviews, width: CGFloat) -> Int {
        let limit = max(1, min(maximumColumns, subviews.count))
        let fittingColumns = (max(0, width) + spacing) / (minimumColumnWidth + spacing)
        return max(1, Int(min(CGFloat(limit), fittingColumns)))
    }

    private func resolvedWidth(_ proposedWidth: CGFloat?, subviews: Subviews) -> CGFloat {
        if let proposedWidth, proposedWidth.isFinite {
            return max(0, proposedWidth)
        }
        let count = max(1, min(maximumColumns, subviews.count))
        let idealColumnWidth = subviews.map { $0.sizeThatFits(.unspecified).width }.max() ?? 0
        return max(minimumColumnWidth, idealColumnWidth) * CGFloat(count)
            + CGFloat(count - 1) * spacing
    }

    private func columnWidth(for subviews: Subviews, width: CGFloat) -> CGFloat {
        let count = columnCount(for: subviews, width: width)
        return max(0, (width - CGFloat(count - 1) * spacing) / CGFloat(count))
    }

    private func rows(for subviews: Subviews, width: CGFloat) -> [Row] {
        let count = columnCount(for: subviews, width: width)
        let proposal = ProposedViewSize(width: columnWidth(for: subviews, width: width), height: nil)
        return stride(from: 0, to: subviews.count, by: count).map { start in
            let indices = start..<min(start + count, subviews.count)
            let height = indices.map { subviews[$0].sizeThatFits(proposal).height }.max() ?? 0
            return Row(indices: indices, height: height)
        }
    }

    private struct Row {
        let indices: Range<Int>
        let height: CGFloat
    }
}
