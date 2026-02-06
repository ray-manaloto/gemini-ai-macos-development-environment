import Foundation
import os

enum ToolsDiskCache {
    private static let logger = Logger(subsystem: "dev.devenvmanager", category: "ToolsDiskCache")
    private static let currentVersion = 1
    
    private static var cacheURL: URL {
        guard let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            fatalError("System caches directory unavailable")
        }
        return caches.appending(path: "DevEnvManager/tools-cache.json")
    }
    
    struct CachedData: Codable {
        let tools: [MiseTool]
        let tasks: [MiseTask]?
        let lastRefresh: Date
        let version: Int
        
        init(tools: [MiseTool], tasks: [MiseTask]?, lastRefresh: Date) {
            self.tools = tools
            self.tasks = tasks
            self.lastRefresh = lastRefresh
            self.version = ToolsDiskCache.currentVersion
        }
    }
    
    static func load() -> CachedData? {
        guard FileManager.default.fileExists(atPath: cacheURL.path()) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: cacheURL)
            let cached = try JSONDecoder().decode(CachedData.self, from: data)
            
            guard cached.version == currentVersion else {
                logger.info("Cache version mismatch (\(cached.version) != \(currentVersion)), ignoring")
                return nil
            }
            
            let maxAge: TimeInterval = 24 * 60 * 60
            if Date().timeIntervalSince(cached.lastRefresh) > maxAge {
                logger.info("Cache expired")
                return nil
            }
            
            return cached
        } catch {
            logger.warning("Failed to load cache: \(error.localizedDescription)")
            return nil
        }
    }
    
    static func save(tools: [MiseTool], tasks: [MiseTask]? = nil, lastRefresh: Date = Date()) async throws {
        let cached = CachedData(tools: tools, tasks: tasks, lastRefresh: lastRefresh)
        let data = try JSONEncoder().encode(cached)
        let url = cacheURL
        let toolCount = tools.count
        
        try await Task.detached(priority: .utility) {
            let directory = url.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: url, options: [.atomic])
        }.value
        
        logger.debug("Cached \(toolCount) tools")
    }
    
    static func clear() {
        try? FileManager.default.removeItem(at: cacheURL)
        logger.info("Cache cleared")
    }
}
