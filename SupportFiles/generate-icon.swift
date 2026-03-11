#!/usr/bin/env swift
import Cocoa

// B2 — Side by Side Monochrome
// White up-triangle (left), muted white down-triangle (right)
// On dark gradient background

let sizes: [(Int, String)] = [
    (16, "icon_16x16"),
    (32, "icon_16x16@2x"),
    (32, "icon_32x32"),
    (64, "icon_32x32@2x"),
    (128, "icon_128x128"),
    (256, "icon_128x128@2x"),
    (256, "icon_256x256"),
    (512, "icon_256x256@2x"),
    (512, "icon_512x512"),
    (1024, "icon_512x512@2x"),
]

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let ctx = NSGraphicsContext.current!.cgContext
    let s = size

    // Background — dark gradient matching app icon bg
    let bgPath = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: s, height: s), xRadius: s * 0.225, yRadius: s * 0.225)
    let gradient = NSGradient(
        colors: [
            NSColor(red: 0x1C/255, green: 0x1C/255, blue: 0x2E/255, alpha: 1),
            NSColor(red: 0x0E/255, green: 0x0E/255, blue: 0x18/255, alpha: 1),
        ],
        atLocations: [0, 1],
        colorSpace: .deviceRGB
    )!
    gradient.draw(in: bgPath, angle: -55)

    // Scale factors relative to 72-unit viewBox mapped to icon size
    let scale = s / 72.0

    // Up triangle (left) — full white
    let upPath = NSBezierPath()
    upPath.move(to: NSPoint(x: 22 * scale, y: s - 14 * scale))
    upPath.line(to: NSPoint(x: 40 * scale, y: s - 42 * scale))
    upPath.line(to: NSPoint(x: 4 * scale, y: s - 42 * scale))
    upPath.close()
    NSColor(red: 0xF5/255, green: 0xF5/255, blue: 0xF7/255, alpha: 1).setFill()
    upPath.fill()

    // Down triangle (right) — muted white
    let downPath = NSBezierPath()
    downPath.move(to: NSPoint(x: 50 * scale, y: s - 58 * scale))
    downPath.line(to: NSPoint(x: 32 * scale, y: s - 30 * scale))
    downPath.line(to: NSPoint(x: 68 * scale, y: s - 30 * scale))
    downPath.close()
    NSColor(red: 0xF5/255, green: 0xF5/255, blue: 0xF7/255, alpha: 0.25).setFill()
    downPath.fill()

    image.unlockFocus()
    return image
}

// Create iconset directory
let iconsetPath = "SupportFiles/AppIcon.iconset"
let fm = FileManager.default
try? fm.removeItem(atPath: iconsetPath)
try! fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

for (size, name) in sizes {
    let image = drawIcon(size: CGFloat(size))
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to generate \(name)")
        continue
    }
    let path = "\(iconsetPath)/\(name).png"
    try! png.write(to: URL(fileURLWithPath: path))
    print("Generated: \(path)")
}

print("\nNow run: iconutil -c icns \(iconsetPath) -o SupportFiles/AppIcon.icns")
