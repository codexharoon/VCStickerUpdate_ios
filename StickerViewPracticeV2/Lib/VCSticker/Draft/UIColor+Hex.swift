//
//  UIColor+Hex.swift
//  StickerViewPracticeV2
//
//  Created by haroon on 05/01/2026.
//

import UIKit

extension UIColor {
    
    /// Convert UIColor to hex string (RRGGBBAA format)
    func toHex() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let ri = Int(r * 255)
        let gi = Int(g * 255)
        let bi = Int(b * 255)
        let ai = Int(a * 255)
        
        return String(format: "#%02X%02X%02X%02X", ri, gi, bi, ai)
    }
    
    /// Create UIColor from hex string (supports #RGB, #RRGGBB, #RRGGBBAA)
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 1.0
        
        switch hexSanitized.count {
        case 3: // RGB (12-bit)
            r = CGFloat((rgb & 0xF00) >> 8) / 15.0
            g = CGFloat((rgb & 0x0F0) >> 4) / 15.0
            b = CGFloat(rgb & 0x00F) / 15.0
            
        case 6: // RRGGBB (24-bit)
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
            
        case 8: // RRGGBBAA (32-bit)
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
            
        default:
            break
        }
        
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}
