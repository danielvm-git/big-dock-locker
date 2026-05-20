// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

@main
struct DockLock {
    static func main() {
        let arguments = CommandLine.arguments
        
        if arguments.contains("--list-displays") {
            listDisplays()
            return
        }
        
        print("DockLock is running. Use --list-displays to see connected monitors.")
    }
    
    static func listDisplays() {
        let manager = DisplayManager()
        do {
            let displays = try manager.getAllDisplays()
            print("Found \(displays.count) display(s):")
            for display in displays {
                print("- [\(display.id)] \(display.name) \(display.isMain ? "(Main)" : "")")
            }
        } catch {
            print("Error fetching displays: \(error)")
        }
    }
}
