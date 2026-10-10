import Foundation

struct ViewerData<Viewer: Decodable>: Decodable {
    let viewer: Viewer
}
