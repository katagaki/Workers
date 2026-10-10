import SwiftUI

struct SwingingHammer: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let gripAnchor = UnitPoint(x: 0.37, y: 0.79)

    var body: some View {
        if reduceMotion {
            hammer
        } else {
            hammer
                .keyframeAnimator(initialValue: 0.0, repeating: true) { content, angle in
                    content.rotationEffect(.degrees(angle), anchor: gripAnchor)
                } keyframes: { _ in
                    CubicKeyframe(-16, duration: 1.6)
                    CubicKeyframe(-18, duration: 0.4)
                    CubicKeyframe(6, duration: 0.7)
                    SpringKeyframe(0, duration: 0.6, spring: .bouncy)
                    LinearKeyframe(0, duration: 0.8)
                }
        }
    }

    private var hammer: some View {
        Image("SignInHammer")
            .resizable()
            .scaledToFit()
    }
}
