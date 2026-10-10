#!/usr/bin/env swift

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let canvasSize = 1024
let canvasLength = CGFloat(canvasSize)

let scriptDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let pathArguments = CommandLine.arguments.dropFirst().filter { !$0.hasPrefix("--") }
let outputDirectory = pathArguments.first.map { URL(fileURLWithPath: $0, isDirectory: true) } ?? scriptDirectory
let iconAssetsDirectory = scriptDirectory
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .appendingPathComponent("Workers/AppIcon.icon/Assets", isDirectory: true)

struct RGB {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat

    init(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    func cgColor(alpha: CGFloat = 1) -> CGColor {
        CGColor(srgbRed: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
    }
}

struct GradientStop {
    let position: CGFloat
    let color: RGB

    init(_ position: CGFloat, _ color: RGB) {
        self.position = position
        self.color = color
    }
}

enum GradientAxis {
    case vertical
    case horizontal
}

enum Layout {
    static let hammerAngleDegrees: CGFloat = 24
    static let hammerRotationOrigin = CGPoint(x: 512, y: 600)
    static let hammerMaximumDimension: CGFloat = 770
    static let hammerTopRightAnchor = CGPoint(x: 895, y: 90)
    static let cloudMaximumDimension: CGFloat = 780
    static let cloudCenter = CGPoint(x: 512, y: 535)
    static let groupCenter = CGPoint(x: 512.5, y: 474.5)
    static let groupScale: CGFloat = 0.88
    static let gridSpacing: CGFloat = 96
    static let gridMinorAlpha: CGFloat = 42 / 255
    static let gridMajorAlpha: CGFloat = 85 / 255
    static let gridMinorWidth: CGFloat = 1.5
    static let gridMajorWidth: CGFloat = 2
    static let backgroundTop = RGB(250, 174, 64)
    static let backgroundBottom = RGB(243, 112, 24)
}

func makeContext() -> CGContext {
    let context = CGContext(
        data: nil,
        width: canvasSize,
        height: canvasSize,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    context.translateBy(x: 0, y: canvasLength)
    context.scaleBy(x: 1, y: -1)
    context.setShouldAntialias(true)
    context.interpolationQuality = .high
    return context
}

func save(_ image: CGImage, named name: String, to directory: URL) {
    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let url = directory.appendingPathComponent("\(name).png")
    let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, image, nil)
    CGImageDestinationFinalize(destination)
}

func arcPoints(center: CGPoint, radius: CGFloat, startDegrees: CGFloat, endDegrees: CGFloat, steps: Int = 24) -> [CGPoint] {
    (0...steps).map { step in
        let degrees = startDegrees + (endDegrees - startDegrees) * CGFloat(step) / CGFloat(steps)
        let radians = degrees * .pi / 180
        return CGPoint(x: center.x + radius * cos(radians), y: center.y + radius * sin(radians))
    }
}

func polygon(_ points: [CGPoint]) -> CGPath {
    let path = CGMutablePath()
    path.addLines(between: points)
    path.closeSubpath()
    return path
}

func roundedRectangle(_ minX: CGFloat, _ minY: CGFloat, _ maxX: CGFloat, _ maxY: CGFloat, radius: CGFloat) -> CGPath {
    polygon(
        arcPoints(center: CGPoint(x: maxX - radius, y: minY + radius), radius: radius, startDegrees: -90, endDegrees: 0)
            + arcPoints(center: CGPoint(x: maxX - radius, y: maxY - radius), radius: radius, startDegrees: 0, endDegrees: 90)
            + arcPoints(center: CGPoint(x: minX + radius, y: maxY - radius), radius: radius, startDegrees: 90, endDegrees: 180)
            + arcPoints(center: CGPoint(x: minX + radius, y: minY + radius), radius: radius, startDegrees: 180, endDegrees: 270)
    )
}

func quadraticShape(
    from start: CGPoint, control firstControl: CGPoint, to firstEnd: CGPoint,
    lineTo secondStart: CGPoint, control secondControl: CGPoint, to secondEnd: CGPoint
) -> CGPath {
    let path = CGMutablePath()
    path.move(to: start)
    path.addQuadCurve(to: firstEnd, control: firstControl)
    path.addLine(to: secondStart)
    path.addQuadCurve(to: secondEnd, control: secondControl)
    path.closeSubpath()
    return path
}

func circle(_ centerX: CGFloat, _ centerY: CGFloat, _ radius: CGFloat) -> CGPath {
    CGPath(ellipseIn: CGRect(x: centerX - radius, y: centerY - radius, width: radius * 2, height: radius * 2), transform: nil)
}

func union(_ paths: [CGPath]) -> CGPath {
    paths.dropFirst().reduce(paths[0]) { $0.union($1) }
}

func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
    CGPoint(x: x, y: y)
}

func fillGradient(
    in context: CGContext,
    clippedTo clips: [CGPath],
    stops: [GradientStop],
    axis: GradientAxis,
    opacity: CGFloat = 1
) {
    context.saveGState()
    for clip in clips {
        context.addPath(clip)
        context.clip()
    }
    context.setAlpha(opacity)
    let first = stops.first!.position
    let last = stops.last!.position
    let locations = stops.map { (last > first) ? ($0.position - first) / (last - first) : 0 }
    let gradient = CGGradient(
        colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
        colors: stops.map { $0.color.cgColor() } as CFArray,
        locations: locations
    )!
    let start = axis == .vertical ? point(0, first) : point(first, 0)
    let end = axis == .vertical ? point(0, last) : point(last, 0)
    context.drawLinearGradient(gradient, start: start, end: end, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    context.restoreGState()
}

func solid(_ color: RGB, at position: CGFloat) -> [GradientStop] {
    [GradientStop(position, color), GradientStop(position + 1, color)]
}

func rotation(degrees: CGFloat, around origin: CGPoint) -> CGAffineTransform {
    CGAffineTransform(translationX: -origin.x, y: -origin.y)
        .concatenating(CGAffineTransform(rotationAngle: degrees * .pi / 180))
        .concatenating(CGAffineTransform(translationX: origin.x, y: origin.y))
}

let groupTransform = CGAffineTransform(translationX: -Layout.groupCenter.x, y: -Layout.groupCenter.y)
    .concatenating(CGAffineTransform(scaleX: Layout.groupScale, y: Layout.groupScale))
    .concatenating(CGAffineTransform(translationX: 512, y: 512))

enum Hammer {
    static let body = roundedRectangle(466, 286, 570, 414, radius: 16)
    static let neck = quadraticShape(
        from: point(560, 300), control: point(624, 332), to: point(694, 316),
        lineTo: point(694, 384), control: point(624, 368), to: point(560, 400)
    )
    static let face = roundedRectangle(680, 292, 724, 408, radius: 14)
    static let claw = quadraticShape(
        from: point(490, 287), control: point(360, 270), to: point(300, 388),
        lineTo: point(304, 398), control: point(390, 340), to: point(490, 410)
    )
    static let clawInner = quadraticShape(
        from: point(304, 398), control: point(390, 340), to: point(490, 410),
        lineTo: point(490, 396), control: point(392, 330), to: point(318, 384)
    )
    static let head = union([body, neck, face, claw])
    static let strikingFace = roundedRectangle(712, 296, 724, 404, radius: 6)
    static let eyeShadow = roundedRectangle(486, 398, 548, 414, radius: 4)
    static let shaft = polygon([point(487, 396), point(537, 396), point(545, 668), point(479, 668)])
    static let shaftShadow = polygon([point(479, 410), point(545, 410), point(545, 436), point(479, 436)])
    static let grip = polygon(
        [point(474, 650), point(550, 650), point(558, 872)]
            + arcPoints(center: point(516, 872), radius: 42, startDegrees: 0, endDegrees: 180)
            + [point(474, 872)]
    )
    static let collar = roundedRectangle(472, 648, 552, 670, radius: 6)

    static var transform: CGAffineTransform {
        let rotated = rotation(degrees: Layout.hammerAngleDegrees, around: Layout.hammerRotationOrigin)
        var bounds = CGRect.null
        for path in [head, shaft, grip, collar] {
            bounds = bounds.union(path.copy(using: [rotated])!.boundingBoxOfPath)
        }
        let scale = Layout.hammerMaximumDimension / max(bounds.width, bounds.height)
        let placement = CGAffineTransform(translationX: -bounds.minX, y: -bounds.minY)
            .concatenating(CGAffineTransform(scaleX: scale, y: scale))
            .concatenating(CGAffineTransform(
                translationX: Layout.hammerTopRightAnchor.x - bounds.width * scale,
                y: Layout.hammerTopRightAnchor.y
            ))
        return rotated.concatenating(placement).concatenating(groupTransform)
    }

    static func drawHead(in context: CGContext) {
        fillGradient(in: context, clippedTo: [head], stops: [
            GradientStop(286, RGB(108, 113, 120)),
            GradientStop(340, RGB(88, 93, 100)),
            GradientStop(414, RGB(62, 66, 72))
        ], axis: .vertical)
        fillGradient(in: context, clippedTo: [claw, clawInner], stops: solid(RGB(40, 43, 48), at: 330), axis: .vertical, opacity: 0.25)
        fillGradient(in: context, clippedTo: [face], stops: [
            GradientStop(680, RGB(112, 117, 124)),
            GradientStop(724, RGB(84, 89, 96))
        ], axis: .horizontal, opacity: 0.5)
        fillGradient(in: context, clippedTo: [face, strikingFace], stops: [
            GradientStop(296, RGB(128, 133, 140)),
            GradientStop(404, RGB(98, 103, 110))
        ], axis: .vertical, opacity: 0.8)
        fillGradient(in: context, clippedTo: [head, eyeShadow], stops: solid(RGB(30, 32, 36), at: 398), axis: .vertical, opacity: 0.35)
        context.saveGState()
        context.addPath(head)
        context.clip()
        context.addPath(head)
        context.setLineWidth(2)
        context.setStrokeColor(RGB(40, 43, 48).cgColor(alpha: 0.5))
        context.strokePath()
        context.restoreGState()
    }

    static func drawShaft(in context: CGContext) {
        fillGradient(in: context, clippedTo: [shaft], stops: [
            GradientStop(479, RGB(150, 156, 164)),
            GradientStop(500, RGB(196, 201, 207)),
            GradientStop(520, RGB(182, 188, 195)),
            GradientStop(546, RGB(128, 134, 142))
        ], axis: .horizontal)
        fillGradient(in: context, clippedTo: [shaft, shaftShadow], stops: [
            GradientStop(410, RGB(70, 74, 80)),
            GradientStop(436, RGB(150, 156, 164))
        ], axis: .vertical, opacity: 0.45)
    }

    static func drawGrip(in context: CGContext) {
        fillGradient(in: context, clippedTo: [grip], stops: [
            GradientStop(474, RGB(22, 23, 25)),
            GradientStop(500, RGB(44, 45, 48)),
            GradientStop(530, RGB(36, 37, 40)),
            GradientStop(558, RGB(18, 19, 21))
        ], axis: .horizontal)
        fillGradient(in: context, clippedTo: [collar], stops: [
            GradientStop(648, RGB(40, 41, 44)),
            GradientStop(670, RGB(28, 29, 31))
        ], axis: .vertical)
    }
}

enum Cloud {
    static let shape = union([
        roundedRectangle(150, 560, 870, 700, radius: 70),
        circle(330, 560, 125),
        circle(590, 455, 235),
        circle(800, 600, 100)
    ])

    static var transform: CGAffineTransform {
        let bounds = shape.boundingBoxOfPath
        let scale = Layout.cloudMaximumDimension / max(bounds.width, bounds.height)
        return CGAffineTransform(translationX: -bounds.midX, y: -bounds.midY)
            .concatenating(CGAffineTransform(scaleX: scale, y: scale))
            .concatenating(CGAffineTransform(translationX: Layout.cloudCenter.x, y: Layout.cloudCenter.y))
            .concatenating(groupTransform)
    }

    static func draw(in context: CGContext) {
        context.addPath(shape)
        context.setFillColor(RGB(255, 255, 255).cgColor())
        context.fillPath()
    }
}

func renderLayer(transform: CGAffineTransform, draw: (CGContext) -> Void) -> CGImage {
    let context = makeContext()
    context.concatenate(transform)
    draw(context)
    return context.makeImage()!
}

func renderBackground() -> CGImage {
    let context = makeContext()
    fillGradient(
        in: context,
        clippedTo: [CGPath(rect: CGRect(x: 0, y: 0, width: canvasLength, height: canvasLength), transform: nil)],
        stops: [GradientStop(0, Layout.backgroundTop), GradientStop(canvasLength, Layout.backgroundBottom)],
        axis: .vertical
    )
    return context.makeImage()!
}

func renderGrid() -> CGImage {
    let context = makeContext()
    let firstOffset = CGFloat(canvasSize % Int(Layout.gridSpacing)) / 2 + Layout.gridSpacing / 2
    var position = firstOffset - Layout.gridSpacing * floor(firstOffset / Layout.gridSpacing)
    while position < canvasLength {
        let index = Int(((position - canvasLength / 2) / Layout.gridSpacing).rounded(.toNearestOrEven))
        let isMajor = index % 4 == 0
        let width = isMajor ? Layout.gridMajorWidth : Layout.gridMinorWidth
        context.setFillColor(RGB(255, 255, 255).cgColor(alpha: isMajor ? Layout.gridMajorAlpha : Layout.gridMinorAlpha))
        context.fill(CGRect(x: position - width / 2, y: 0, width: width, height: canvasLength))
        context.fill(CGRect(x: 0, y: position - width / 2, width: canvasLength, height: width))
        position += Layout.gridSpacing
    }
    guard let pixels = context.data?.bindMemory(to: UInt8.self, capacity: context.bytesPerRow * canvasSize) else {
        return context.makeImage()!
    }
    let maximumDistance = canvasLength / 2 * sqrt(2)
    for row in 0..<canvasSize {
        for column in 0..<canvasSize {
            let distance = hypot(CGFloat(column) + 0.5 - canvasLength / 2, CGFloat(row) + 0.5 - canvasLength / 2)
            let fade = max(0, min(1, 1 - 0.9 * pow(min(distance / maximumDistance, 1), 1.6)))
            let offset = row * context.bytesPerRow + column * 4
            for channel in 0..<4 {
                pixels[offset + channel] = UInt8((CGFloat(pixels[offset + channel]) * fade).rounded())
            }
        }
    }
    return context.makeImage()!
}

func flatten(_ layers: [CGImage]) -> CGImage {
    let context = CGContext(
        data: nil,
        width: canvasSize,
        height: canvasSize,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    for layer in layers {
        context.draw(layer, in: CGRect(x: 0, y: 0, width: canvasLength, height: canvasLength))
    }
    return context.makeImage()!
}

let background = renderBackground()
let grid = renderGrid()
let cloud = renderLayer(transform: Cloud.transform, draw: Cloud.draw)
let hammerTransform = Hammer.transform
let shaft = renderLayer(transform: hammerTransform, draw: Hammer.drawShaft)
let grip = renderLayer(transform: hammerTransform, draw: Hammer.drawGrip)
let head = renderLayer(transform: hammerTransform, draw: Hammer.drawHead)
let flattened = flatten([background, grid, cloud, shaft, grip, head])

let iconLayers: [(String, CGImage)] = [("Grid", grid), ("Cloud", cloud), ("Handle", shaft), ("Grip", grip), ("Head", head)]
for (name, image) in iconLayers + [("Background", background), ("Flattened", flattened)] {
    save(image, named: name, to: outputDirectory)
}
print("Saved layers to \(outputDirectory.path)")

if CommandLine.arguments.contains("--install"), FileManager.default.fileExists(atPath: iconAssetsDirectory.path) {
    for (name, image) in iconLayers {
        save(image, named: name, to: iconAssetsDirectory)
    }
    print("Installed layers into \(iconAssetsDirectory.path)")
}
