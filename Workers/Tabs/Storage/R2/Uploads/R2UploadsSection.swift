import CloudflareKit
import SwiftUI

struct R2UploadsSection: View {
    let uploads: [R2Upload]
    let client: CloudflareClient
    var showsLocation = false

    var body: some View {
        Section {
            ForEach(uploads) { upload in
                R2UploadRow(upload: upload, client: client, showsLocation: showsLocation)
            }
        } header: {
            Text(.storageR2UploadsTitle)
        } footer: {
            Text(.storageR2UploadsFooter)
        }
    }
}
