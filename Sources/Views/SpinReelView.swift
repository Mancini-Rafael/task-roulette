import SwiftUI

/// A horizontal slot-machine reel: cells scroll past a fixed center marker, blurred and
/// edge-faded while moving, decelerating to land the winning task under the marker.
///
/// The strip is prebuilt by the caller as `titles`, with the winner placed at
/// `winnerIndex`. We animate the strip's x-offset so that cell lands dead center.
struct SpinReelView: View {
    let titles: [String]
    let winnerIndex: Int
    /// Bumped by the caller on every spin; drives a fresh animation run.
    let spinID: Int
    /// True once the reel has stopped on the winner (caller flips this).
    let settled: Bool
    let onSettled: () -> Void

    private let cellWidth: CGFloat = 190
    private let rowHeight: CGFloat = 86
    private let duration: Double = 2.6

    @State private var offset: CGFloat = 0
    @State private var blur: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let viewport = geo.size.width

            ZStack {
                // Scrolling strip.
                ZStack(alignment: .leading) {
                    HStack(spacing: 0) {
                        ForEach(Array(titles.enumerated()), id: \.offset) { index, title in
                            ReelCell(
                                title: title,
                                isWinner: settled && index == winnerIndex,
                                width: cellWidth,
                                height: rowHeight
                            )
                        }
                    }
                    .offset(x: offset)
                    .blur(radius: blur)
                }
                .frame(width: viewport, height: rowHeight, alignment: .leading)
                .clipped()
                .mask(edgeFade)

                // Fixed center selection window + marker.
                selectionOverlay
            }
            .frame(width: viewport, height: rowHeight)
            .onAppear { runSpin(viewport: viewport) }
            .onChange(of: spinID) { _, _ in runSpin(viewport: viewport) }
        }
        .frame(height: rowHeight)
    }

    // MARK: - Pieces

    private var selectionOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.accentColor.opacity(settled ? 0.9 : 0.35),
                              lineWidth: settled ? 2.5 : 1.5)
                .frame(width: cellWidth, height: rowHeight - 4)

            VStack {
                Triangle()
                    .fill(Color.accentColor)
                    .frame(width: 14, height: 8)
                    .rotationEffect(.degrees(180))
                Spacer()
                Triangle()
                    .fill(Color.accentColor)
                    .frame(width: 14, height: 8)
            }
            .frame(height: rowHeight)
        }
    }

    private var edgeFade: some View {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0.0),
                .init(color: .black, location: 0.24),
                .init(color: .black, location: 0.76),
                .init(color: .clear, location: 1.0),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // MARK: - Animation

    private func runSpin(viewport: CGFloat) {
        guard viewport > 0, !titles.isEmpty else { return }

        // Offset that centers a given cell index under the viewport midpoint.
        func centerOffset(for index: Int) -> CGFloat {
            viewport / 2 - (CGFloat(index) * cellWidth + cellWidth / 2)
        }

        let start = centerOffset(for: 0)
        let final = centerOffset(for: winnerIndex)

        // Snap to the start without animating, then animate to the winner.
        var snap = Transaction()
        snap.disablesAnimations = true
        withTransaction(snap) {
            offset = start
            blur = 6
        }

        DispatchQueue.main.async {
            withAnimation(.timingCurve(0.12, 0.9, 0.2, 1.0, duration: duration)) {
                offset = final
            } completion: {
                onSettled()
            }
            // Motion blur bleeds off as the reel slows.
            withAnimation(.easeOut(duration: duration)) {
                blur = 0
            }
        }
    }
}

private struct ReelCell: View {
    let title: String
    let isWinner: Bool
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        Text(title)
            .font(.headline)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 10)
            .frame(width: width, height: height)
            .foregroundStyle(isWinner ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(.quaternary)
                    .frame(width: 1)
                    .padding(.vertical, 16)
            }
    }
}

/// Upward-pointing triangle used for the center markers.
private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
