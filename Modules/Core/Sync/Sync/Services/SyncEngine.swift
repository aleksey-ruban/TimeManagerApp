import Foundation

actor SyncEngine: SyncEngineProtocol {
    private let reachabilityMonitor: ReachabilityMonitorProtocol

    private var isRunning = false

    init(reachabilityMonitor: ReachabilityMonitorProtocol) {
        self.reachabilityMonitor = reachabilityMonitor
    }

    func run(
        trigger: SyncTrigger,
        pipeline: SyncPipeline
    ) async throws -> SyncRunResult {
        guard !isRunning else {
            throw SyncEngineError.alreadyRunning
        }

        guard reachabilityMonitor.isReachable else {
            throw SyncEngineError.networkUnavailable
        }

        isRunning = true
        defer { isRunning = false }

        let startedAt = Date()
        let executionContext = SyncExecutionContext(
            trigger: trigger,
            startedAt: startedAt
        )

        var stageResults: [SyncStageResult] = []
        var pullCursor: String?

        if let pull = pipeline.pull {
            let pullResults = try await executePull(
                pull,
                context: executionContext
            )
            stageResults.append(contentsOf: pullResults.results)
            pullCursor = pullResults.cursor
        }

        for stage in pipeline.pushStages {
            let stageStartedAt = Date()
            let processedItemsCount = try await stage.execute(context: executionContext)
            let result = SyncStageResult(
                stageID: stage.id,
                direction: .push,
                startedAt: stageStartedAt,
                finishedAt: Date(),
                processedItemsCount: processedItemsCount
            )

            stageResults.append(result)
        }

        let runResult = SyncRunResult(
            trigger: trigger,
            startedAt: startedAt,
            finishedAt: Date(),
            stageResults: stageResults,
            pullCursor: pullCursor
        )

        return runResult
    }

    private func executePull(
        _ configuration: SyncPullConfiguration,
        context: SyncExecutionContext
    ) async throws -> (results: [SyncStageResult], cursor: String?) {
        var bufferedChanges: [SyncStageID: [SyncPullChange]] = [:]
        var cursor = configuration.initialCursor

        while let batch = try await configuration.source.fetchBatch(after: cursor) {
            for change in batch.changes {
                bufferedChanges[change.stageID, default: []].append(change)
            }
            cursor = batch.nextCursor

            if batch.hasMore == false {
                break
            }
        }

        var results: [SyncStageResult] = []

        for stage in configuration.stages {
            let stageStartedAt = Date()
            let processedItemsCount = try await stage.apply(
                changes: bufferedChanges[stage.id] ?? [],
                context: context
            )
            let result = SyncStageResult(
                stageID: stage.id,
                direction: .pull,
                startedAt: stageStartedAt,
                finishedAt: Date(),
                processedItemsCount: processedItemsCount,
                nextCursor: cursor
            )

            results.append(result)
        }

        return (results, cursor)
    }
}
