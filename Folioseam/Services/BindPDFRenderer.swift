import Foundation
import UIKit

enum BindPDFRenderer {
    static func render(bundle: ProjectBundle, progress: ProjectProgress) -> Data {
        let page = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: page)
        return renderer.pdfData { context in
            context.beginPage()
            let title = bundle.project.title as NSString
            title.draw(at: CGPoint(x: 48, y: 48), withAttributes: [
                .font: UIFont.systemFont(ofSize: 22, weight: .semibold),
                .foregroundColor: UIColor.label
            ])
            let body = """
            Client: \(bundle.project.clientOrOwner)
            Style: \(bundle.project.bindingStyle)
            Status: \(bundle.project.status.title)
            Progress: \(Int(progress.projectProgress * 100))%
            Material spend: $\(String(format: "%.2f", progress.materialSpend))
            Stages done: \(bundle.stages.filter(\.done).count)/\(bundle.stages.count)
            Sections sewn: \(bundle.sections.filter(\.sewn).count)/\(bundle.sections.count)
            Notes: \(bundle.project.notes)
            """ as NSString
            body.draw(in: CGRect(x: 48, y: 96, width: 516, height: 600), withAttributes: [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.label
            ])
        }
    }
}
