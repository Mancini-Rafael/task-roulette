#!/usr/bin/env swift
//
// Renders the Task Roulette app icon (1024×1024 master PNG) with CoreGraphics.
// A colorful roulette wheel with a glowing gold ring on a deep-navy squircle,
// echoing the project cover art.
//
// Usage:  swift scripts/make-icon.swift <output.png>
//
import CoreGraphics
import ImageIO
import Foundation

let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon-1024.png"
let size = 1024

func color(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(
        red: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: a
    )
}

let cs = CGColorSpace(name: CGColorSpace.sRGB)!
guard let ctx = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
    space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { fatalError("context") }

let dim = CGFloat(size)
let center = CGPoint(x: dim / 2, y: dim / 2)

// --- Squircle background ----------------------------------------------------
let inset: CGFloat = 92
let bgRect = CGRect(x: inset, y: inset, width: dim - 2 * inset, height: dim - 2 * inset)
let corner: CGFloat = (dim - 2 * inset) * 0.2237   // Apple-ish continuous corner
let bgPath = CGPath(roundedRect: bgRect, cornerWidth: corner, cornerHeight: corner, transform: nil)

ctx.saveGState()
ctx.addPath(bgPath)
ctx.clip()
let grad = CGGradient(
    colorsSpace: cs,
    colors: [color(0x2C2060), color(0x140C2C)] as CFArray,
    locations: [0, 1]
)!
ctx.drawLinearGradient(grad,
    start: CGPoint(x: 0, y: dim), end: CGPoint(x: 0, y: 0), options: [])
ctx.restoreGState()

// --- Wheel segments ---------------------------------------------------------
let R: CGFloat = 300
let segColors: [UInt32] = [
    0xF0613A, 0xF5A623, 0x6FCF42, 0x18B6C9,
    0x2D7CF0, 0x8B3FF0, 0xE84393, 0xE23B4E,
]
let segCount = segColors.count
let sweep = (2 * CGFloat.pi) / CGFloat(segCount)
let startBase = CGFloat.pi / 2   // first edge at top

for i in 0..<segCount {
    let a0 = startBase + CGFloat(i) * sweep
    let a1 = a0 + sweep
    ctx.beginPath()
    ctx.move(to: center)
    ctx.addArc(center: center, radius: R, startAngle: a0, endAngle: a1, clockwise: false)
    ctx.closePath()
    ctx.setFillColor(color(segColors[i]))
    ctx.fillPath()
}

// Thin dark separators between segments.
ctx.setStrokeColor(color(0x140C2C, 0.55))
ctx.setLineWidth(6)
for i in 0..<segCount {
    let a = startBase + CGFloat(i) * sweep
    ctx.beginPath()
    ctx.move(to: center)
    ctx.addLine(to: CGPoint(x: center.x + cos(a) * R, y: center.y + sin(a) * R))
    ctx.strokePath()
}

// --- Glowing gold ring ------------------------------------------------------
ctx.saveGState()
ctx.setShadow(offset: .zero, blur: 34, color: color(0xFFC23C, 0.9))
ctx.setStrokeColor(color(0xFFC23C))
ctx.setLineWidth(18)
ctx.addArc(center: center, radius: R + 12, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
ctx.strokePath()
ctx.restoreGState()

// --- Center hub -------------------------------------------------------------
let hubR: CGFloat = 96
ctx.setFillColor(color(0x140C2C))
ctx.addArc(center: center, radius: hubR, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
ctx.fillPath()

ctx.setStrokeColor(color(0xFFFFFF, 0.92))
ctx.setLineWidth(10)
ctx.addArc(center: center, radius: hubR, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
ctx.strokePath()

ctx.setFillColor(color(0xFFC23C))
ctx.addArc(center: center, radius: 22, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
ctx.fillPath()

// --- Top pointer ------------------------------------------------------------
let tipY = center.y + R + 30
let baseY = center.y + R + 96
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -6), blur: 18, color: color(0x000000, 0.5))
ctx.setFillColor(color(0xF5F5F8))
ctx.beginPath()
ctx.move(to: CGPoint(x: center.x, y: tipY))
ctx.addLine(to: CGPoint(x: center.x - 44, y: baseY))
ctx.addLine(to: CGPoint(x: center.x + 44, y: baseY))
ctx.closePath()
ctx.fillPath()
ctx.restoreGState()
// Little cap circle on the pointer.
ctx.setFillColor(color(0xF5F5F8))
ctx.addArc(center: CGPoint(x: center.x, y: baseY), radius: 30, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
ctx.fillPath()
ctx.setFillColor(color(0xE23B4E))
ctx.addArc(center: CGPoint(x: center.x, y: baseY), radius: 13, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
ctx.fillPath()

// --- Write PNG --------------------------------------------------------------
guard let image = ctx.makeImage() else { fatalError("image") }
let url = URL(fileURLWithPath: outPath)
guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
    fatalError("destination")
}
CGImageDestinationAddImage(dest, image, nil)
guard CGImageDestinationFinalize(dest) else { fatalError("finalize") }
print("wrote \(outPath)")
