// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import ArgumentParser
import ColorizeSwift


let version = "v2.0.0"
let appInfo = "SmartDaemons " + version

var allowedDaemons: [String]?
var daemonLocations: [String]?


@available(macOS 13.0, *)
@main
struct smartdaemons: ParsableCommand {
    @Flag(help: "SmartDaemon will ask for each invalid daemon if it should be removed. Without this flag, only warnings are shown.")
    var clean = false
    
    func run() throws {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = " - HH:mm dd.MM.YYYY"
        
        print(appInfo.bold() + dateFormatter.string(from: date).darkGray() + "\n")
        
        do {
            try readConfigFiles()
        } catch {
            fatalError("No config found")
        }
        
        for location in daemonLocations! {
            checkingDaemons(location: location, clean: clean)
        }
    }
}


@available(macOS 13.0, *)
func readConfigFiles() throws {
    let applicationSupportFolderURL = try! FileManager.default.url(for: .userDirectory,
                                                                    in: .localDomainMask,
                                                        appropriateFor: nil,
                                                                create: false)

    let locationsConfigURL = applicationSupportFolderURL.appendingPathComponent(NSUserName() + "/.smartDaemons/locations.config")
    
    let daemonsConfigURL = applicationSupportFolderURL.appendingPathComponent(NSUserName() + "/.smartDaemons/daemons.config")
    
    
    let data1 = try String(contentsOfFile: daemonsConfigURL.path(), encoding: String.Encoding.utf8)
    allowedDaemons = data1.components(separatedBy: "\n")
    
    let data2 = try String(contentsOfFile: locationsConfigURL.path(), encoding: String.Encoding.utf8)
    daemonLocations = data2.components(separatedBy: "\n")
    
    allowedDaemons = allowedDaemons!.filter({ $0 != ""})
    daemonLocations = daemonLocations!.filter({ $0 != ""})
}


func checkingDaemons(location: String, clean: Bool) {
    print("Scanning Location: ".bold() + location.cyan())
    
    do {
        let listOfDaemons = try FileManager.default.contentsOfDirectory(atPath: location)
        
        for daemonFile in listOfDaemons {
            if daemonIsOK(daemon: daemonFile) {
                print(daemonFile.lightGray())
            } else {
                if clean {
                    print(daemonFile.lightRed() + " : delete this daemon? (y/n) ", terminator: "")
                    let del = readLine()
                    if del == "y" {
                        do {
                            try FileManager.default.removeItem(atPath: location + "/" + daemonFile)
                            print("  --> daemon has been deleted!".foregroundColor(.chartreuse2).bold())
                        } catch {
                            print("      Error deleting daemon!!".red().bold())
                        }
                    } else {
                        print("  --> daemon has NOT been deleted!".yellow().bold())
                    }
                } else {
                    print(daemonFile.lightRed() + " <-- unexpected daemon".yellow().bold())
                }
            }
        }
    } catch {
        print("Invalid directory".darkGray())
    }
    
    print()
}

func daemonIsOK(daemon: String) -> Bool {
    for allowedDaemon in allowedDaemons! {
        if daemon.starts(with: allowedDaemon) {
            return true
        }
    }
    
    return false
}
