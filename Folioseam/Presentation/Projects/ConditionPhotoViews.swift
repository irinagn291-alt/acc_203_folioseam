import SwiftUI
import UIKit

/// Decoded photos are cached per path so scrolling the condition log does not
/// re-read and re-decode JPEGs from disk on every layout pass.
actor ConditionPhotoCache {
    static let shared = ConditionPhotoCache()
    private var images: [String: UIImage] = [:]

    func image(at path: String, maxPixel: CGFloat) -> UIImage? {
        let key = "\(path)#\(Int(maxPixel))"
        if let cached = images[key] { return cached }
        guard let downsampled = Self.downsample(path: path, maxPixel: maxPixel) else { return nil }
        images[key] = downsampled
        return downsampled
    }

    private static func downsample(path: String, maxPixel: CGFloat) -> UIImage? {
        let url = URL(fileURLWithPath: path) as CFURL
        guard let source = CGImageSourceCreateWithURL(url, [kCGImageSourceShouldCache: false] as CFDictionary) else {
            return nil
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel * UIScreen.main.scale
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}

struct ConditionPhotoThumbnail: View {
    let path: String
    var height: CGFloat = 120

    @State private var image: UIImage?
    @State private var isMissing = false

    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(SeamPalette.board.opacity(0.35), lineWidth: 1)
            )
            .task(id: path) {
                image = await ConditionPhotoCache.shared.image(at: path, maxPixel: 600)
                isMissing = image == nil
            }
    }

    @ViewBuilder
    private var content: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else if isMissing {
            ZStack {
                SeamPalette.cloth.opacity(0.18)
                Label("Photo unavailable", systemImage: "photo.badge.exclamationmark")
                    .font(.caption)
                    .foregroundStyle(SeamPalette.ink.opacity(0.6))
            }
        } else {
            ZStack {
                SeamPalette.cloth.opacity(0.12)
                ProgressView().tint(SeamPalette.moss)
            }
        }
    }
}

struct ConditionPhotoViewer: View {
    let path: String
    let caption: String

    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage?
    @State private var zoom: CGFloat = 1

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(zoom)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { zoom = max(1, min(4, $0)) }
                                .onEnded { _ in
                                    if zoom < 1.05 { withAnimation(.easeOut) { zoom = 1 } }
                                }
                        )
                        .accessibilityLabel(caption)
                } else {
                    ProgressView().tint(.white)
                }
            }
            .navigationTitle(caption)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task(id: path) {
            image = await ConditionPhotoCache.shared.image(at: path, maxPixel: 2048)
        }
    }
}

/// The point of a restoration log is the before/after pair, so surface it as a
/// dedicated comparison rather than leaving it buried in the chronological list.
struct BeforeAfterStrip: View {
    let records: [ConditionRecord]
    var onOpen: (ConditionRecord) -> Void

    private var before: ConditionRecord? {
        records.filter { $0.phase == .before && $0.photoPath != nil }
            .min { $0.recordedAt < $1.recordedAt }
    }

    private var after: ConditionRecord? {
        records.filter { $0.phase == .after && $0.photoPath != nil }
            .max { $0.recordedAt < $1.recordedAt }
    }

    var body: some View {
        if before != nil || after != nil {
            VStack(alignment: .leading, spacing: 8) {
                Text("Before / after").font(.title3.weight(.semibold))
                HStack(spacing: 10) {
                    pane(before, fallback: "No before photo")
                    pane(after, fallback: "No after photo")
                }
                if let before, let after {
                    Text("Condition \(before.score) → \(after.score)")
                        .font(.caption.monospaced())
                        .foregroundStyle(SeamPalette.moss)
                }
            }
        }
    }

    @ViewBuilder
    private func pane(_ record: ConditionRecord?, fallback: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let record, let path = record.photoPath {
                Button { onOpen(record) } label: {
                    ConditionPhotoThumbnail(path: path, height: 140)
                }
                .buttonStyle(.plain)
                Text(record.phase.title)
                    .font(.caption2.monospaced())
                    .foregroundStyle(SeamPalette.ink.opacity(0.6))
            } else {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(SeamPalette.cloth.opacity(0.14))
                    .frame(height: 140)
                    .overlay(
                        Text(fallback)
                            .font(.caption)
                            .foregroundStyle(SeamPalette.ink.opacity(0.5))
                    )
            }
        }
        .frame(maxWidth: .infinity)
    }
}
