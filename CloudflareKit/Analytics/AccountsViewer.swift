import Foundation

struct AccountsViewer<Account: Decodable>: Decodable {
    let accounts: [Account]
}
