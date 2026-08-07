import Foundation

/// Pure bindery progress formulas.
public enum BindMath: Sendable {
    /// `doneStages / totalStages`, or `0` when there are no stages.
    public static func stageProgress(doneStages: Int, totalStages: Int) -> Double {
        guard totalStages > 0 else { return 0 }
        return Double(doneStages) / Double(totalStages)
    }

    /// `sewnSections / totalSections`, or `0` when there are no sections.
    public static func sectionProgress(sewnSections: Int, totalSections: Int) -> Double {
        guard totalSections > 0 else { return 0 }
        return Double(sewnSections) / Double(totalSections)
    }

    /// Weighted project progress: `0.6 * stage + 0.4 * section`.
    /// When there are no sections, stage progress alone is used.
    public static func projectProgress(
        stageProgress: Double,
        sectionProgress: Double,
        hasSections: Bool
    ) -> Double {
        if hasSections {
            return 0.6 * stageProgress + 0.4 * sectionProgress
        }
        return stageProgress
    }

    /// `after.score − before.score` when both exist.
    public static func conditionDelta(before: Int?, after: Int?) -> Int? {
        guard let before, let after else { return nil }
        return after - before
    }

    /// Sum of material costs in currency units.
    public static func materialSpend(costCents: [Int]) -> Double {
        Double(costCents.reduce(0, +)) / 100.0
    }
}
