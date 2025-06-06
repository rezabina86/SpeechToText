import SwiftUI

struct TranscriptionTextViewState: Equatable {
    let placeholder: String
    let highlightedWordIndex: Int
    let words: [Word]
    
    struct Word: Equatable, Identifiable {
        let index: Int
        let text: String
        
        var id: Int {
            index
        }
    }
}

struct TranscriptionTextView: View {
    let viewState: TranscriptionTextViewState
    
    var body: some View {
        ScrollView {
            Group {
                if viewState.words.isEmpty {
                    placeholderText
                } else {
                    wordFlow
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    // MARK: - Placeholder
    private var placeholderText: some View {
        Text(viewState.placeholder)
            .font(.body)
            .foregroundColor(.secondary)
    }
    
    private var wordFlow: some View {
        WordFlowLayout {
            ForEach(viewState.words) { word in
                zeroShiftWordView(for: word)
            }
        }
    }
    
    private func zeroShiftWordView(for word: TranscriptionTextViewState.Word) -> some View {
        let isHighlighted = (word.index == viewState.highlightedWordIndex)
        
        return ZStack {
            // Layout reference - invisible but reserves space
            Text(word.text)
                .font(.body)
                .fontWeight(.regular)
                .foregroundColor(.clear)
                .padding(2)
            
            // Visual word - positioned absolute, doesn't affect layout
            Text(word.text)
                .font(.body)
                .fontWeight(.regular) // Never changes weight
                .foregroundColor(isHighlighted ? .white : .primary)
                .padding(2)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isHighlighted ? Color.blue : Color.clear)
                )
                .foregroundColor(isHighlighted ? .black : .primary)
                .animation(.easeInOut(duration: 0.1), value: isHighlighted)
        }
    }
}

private struct WordFlowLayout: Layout {
    let spacing: CGFloat
    let lineSpacing: CGFloat
    
    init(spacing: CGFloat = 2, lineSpacing: CGFloat = 4) {
        self.spacing = spacing
        self.lineSpacing = lineSpacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = calculateLayout(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = calculateLayout(in: bounds.width, subviews: subviews)
        
        for (index, subview) in subviews.enumerated() {
            guard index < result.frames.count else { continue }
            let frame = result.frames[index]
            subview.place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }
    
    private func calculateLayout(in maxWidth: CGFloat, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        var frames: [CGRect] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            // Check if we need to wrap to next line
            if currentX + size.width > maxWidth && !frames.isEmpty {
                currentY += currentRowHeight + lineSpacing
                currentX = 0
                currentRowHeight = 0
            }
            
            frames.append(CGRect(
                x: currentX,
                y: currentY,
                width: size.width,
                height: size.height
            ))
            
            currentX += size.width + spacing
            currentRowHeight = max(currentRowHeight, size.height)
        }
        
        let totalSize = CGSize(
            width: maxWidth,
            height: currentY + currentRowHeight
        )
        
        return (totalSize, frames)
    }
}

