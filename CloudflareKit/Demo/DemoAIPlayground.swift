import Foundation

enum DemoAIPlayground {
    static func response(method: String, parts: [String], body: [String: Any]?) -> [String: Any]? {
        if method == "GET", parts == ["ai", "models", "search"] {
            return DemoRouter.envelope([
                ["id": "demo-text", "name": "@cf/seminar-research/koyuki-chat-2-2b", "task": ["name": "Text Generation"]],
                ["id": "demo-code", "name": "@cf/veritas/code-assistant", "task": ["name": "Text Generation"]]
            ], info: ["total_pages": 1])
        }
        if method == "GET", parts == ["ai", "models", "schema"] {
            return DemoRouter.envelope([
                "input": ["properties": ["prompt": ["type": "string"], "temperature": ["type": "number"],
                    "max_tokens": ["type": "integer"], "stream": ["type": "boolean"]]],
                "output": ["properties": ["response": ["type": "string"]]]
            ])
        }
        if method == "POST", parts.count > 2, parts[0] == "ai", parts[1] == "run" {
            return DemoRouter.envelope(["response": String(localized: .demoPlaygroundResponse)])
        }
        return nil
    }
}
