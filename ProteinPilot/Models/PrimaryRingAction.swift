import Foundation
import SwiftUI

enum PrimaryRingAction: CaseIterable {
    case voice
    case camera
    case manual
    case barcode
    
    var icon: String {
        switch self {
        case .voice: return "mic.fill"
        case .camera: return "camera.fill"
        case .manual: return "pencil"
        case .barcode: return "barcode.viewfinder"
        }
    }
    
    var title: String {
        switch self {
        case .voice: return "Voice"
        case .camera: return "Scan"
        case .manual: return "Manual"
        case .barcode: return "Barcode"
        }
    }
    
    var tabIndex: Int {
        switch self {
        case .voice: return 3
        case .camera: return 1
        case .manual: return 0
        case .barcode: return 2
        }
    }
    
    var angle: Double {
        switch self {
        case .voice: return 0      // Top
        case .camera: return 90    // Right
        case .manual: return 180   // Bottom
        case .barcode: return 270  // Left
        }
    }
    
    static var smartDefault: PrimaryRingAction {
        let hour = Calendar.current.component(.hour, from: Date())
        return (7...11).contains(hour) ? .camera : .voice
    }
}