import Foundation
import os

actor PortDetector {
    private let logger = Logger(subsystem: "dev.devenvmanager", category: "PortDetector")
    private let timeout: Duration = .seconds(5)
    
    func detectListeningPorts() async -> [ServicePort] {
        do {
            let result = try await CommandExecutor.run(
                path: "/usr/sbin/lsof",
                arguments: ["-iTCP", "-sTCP:LISTEN", "-n", "-P"],
                timeout: timeout
            )
            
            guard result.isSuccess else {
                logger.warning("lsof failed: \(result.stderr)")
                return []
            }
            
            return parseLsofOutput(result.stdout)
            
        } catch {
            logger.warning("Port detection failed: \(error.localizedDescription)")
            return []
        }
    }
    
    func detectPortsForPid(_ pid: Int) async -> [ServicePort] {
        do {
            let result = try await CommandExecutor.run(
                path: "/usr/sbin/lsof",
                arguments: ["-iTCP", "-sTCP:LISTEN", "-n", "-P", "-p", String(pid)],
                timeout: timeout
            )
            
            guard result.isSuccess else {
                return []
            }
            
            return parseLsofOutput(result.stdout)
            
        } catch {
            return []
        }
    }
    
    private func parseLsofOutput(_ output: String) -> [ServicePort] {
        var ports: [ServicePort] = []
        let lines = output.components(separatedBy: "\n")
        
        for line in lines.dropFirst() {
            let columns = line.split(separator: " ", omittingEmptySubsequences: true)
            guard columns.count >= 9 else { continue }
            
            let process = String(columns[0])
            guard let pid = Int(columns[1]) else { continue }
            
            let addressColumn = String(columns[8])
            guard let colonIndex = addressColumn.lastIndex(of: ":") else { continue }
            
            let address = String(addressColumn[..<colonIndex])
            let portString = String(addressColumn[addressColumn.index(after: colonIndex)...])
            guard let port = Int(portString) else { continue }
            
            let servicePort = ServicePort(
                port: port,
                pid: pid,
                process: process,
                address: address
            )
            
            if !ports.contains(where: { $0.port == port && $0.pid == pid }) {
                ports.append(servicePort)
            }
        }
        
        logger.debug("Detected \(ports.count) listening ports")
        return ports
    }
}
