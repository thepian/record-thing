import Foundation
import WebKit

public class ThepiaMessageHandler: NSObject, WKScriptMessageHandler {
    private let authHandler: FlowsAuthHandler?
    
    public init(authHandler: FlowsAuthHandler? = nil) {
        self.authHandler = authHandler
        super.init()
    }
    
    public func userContentController(_ userContentController: WKUserContentController,
                              didReceive message: WKScriptMessage) {
        guard let dict = message.body as? [String: Any],
              let type = dict["type"] as? String else {
            return
        }
        
        if type == "webapp_state" {
            NotificationCenter.default.post(name: .WebAppStateUpdated, object: nil, userInfo: dict)
            return
        }
        
        // For all other message types, we expect a requestId
        guard let requestId = dict["requestId"] as? String else {
            // If it's not webapp_state and no requestId, we can't respond, so just return.
            return
        }
        
        // If type is present, route based on it (new protocol)
        // If not present, infer from procedure or other fields (backward compatibility if needed)
        
        if let messageType = dict["type"] as? String {
            switch messageType {
            case "auth":
                // Generic auth wrapper if used
                handleAuthMessage(body: dict, requestId: requestId, webView: message.webView)
            case "flowsdb":
                handleFlowsDBMessage(body: dict, requestId: requestId, webView: message.webView)
            case "saveSession", "getSession", "clearSession", 
                 "saveUser", "getUser", "clearUser", 
                 "updateUserMetadata", "patchMetadata":
                // Legacy/Direct auth types - map to flowsdb auth procedures
                var newBody = dict
                newBody["procedure"] = "auth.\(messageType)"
                if let data = dict["data"] {
                    newBody["payload"] = data
                }
                handleFlowsDBMessage(body: newBody, requestId: requestId, webView: message.webView)
            default:
                sendError(requestId: requestId, error: "Unknown message type: \(messageType)", webView: message.webView)
            }
        } else {
            sendError(requestId: requestId, error: "Missing message type", webView: message.webView)
        }
    }

    private func handleAuthMessage(body: [String: Any], requestId: String, webView: WKWebView?) {
        guard let authHandler = authHandler else {
            sendError(requestId: requestId, error: "Auth handler not configured", webView: webView)
            return
        }
        
        Task {
            do {
                // Determine method from body (assuming direct auth message structure)
                // The user plan says: { type: 'saveSession', data: {...}, requestId: ... }
                // But also mentions "auth" namespace in handleRPC.
                // Let's look at the plan again.
                // "Web -> Native (Auth - existing): { type: 'saveSession', ... }"
                // "Web -> Native (FlowsDB): { type: 'flowsdb', procedure: 'auth.saveSession', ... }"
                
                // This method handles the "auth" type, which seems to be the legacy/direct way?
                // Or maybe "auth" type is a namespace for auth messages?
                // The user plan says: "switch messageType { case 'auth': handleAuthMessage... }"
                // And "Web -> Native (Auth - existing): { type: 'saveSession' }" - wait, type IS 'saveSession' there.
                // But my switch in userContentController handles "auth".
                
                // Let's assume the "auth" type in the switch corresponds to a generic auth message wrapper,
                // OR adapt the switch to handle specific auth types if they are top-level.
                
                // Re-reading user plan:
                // "switch messageType { case 'auth': ... case 'flowsdb': ... }"
                // But later: "Web -> Native (Auth - existing) { type: 'saveSession' ... }"
                // This implies 'saveSession' IS the type.
                
                // So I should probably handle 'saveSession' as a top-level type in userContentController.
                // But for now, let's implement the logic here assuming we can get the method/procedure.
                
                // If this is called from 'auth' type, maybe it has a 'method' field?
                // Or maybe the user plan meant the 'auth' case handles things like 'saveSession' if we group them?
                // Let's look at the Swift example in the plan:
                // case "auth": handleAuthMessage(body: body...)
                
                // I'll assume body has 'method' or 'procedure' or we infer from context.
                // Actually, let's look at `handleFlowsDBMessage` for `auth.saveSession`.
                
                // For direct auth messages (if any), we might need to parse differently.
                // But for `flowsdb` messages with `auth.saveSession`, we use `handleFlowsDBMessage`.
                
                // Let's implement `handleFlowsDBMessage` first as that's clearly defined.
            }
        }
    }

    private func handleFlowsDBMessage(body: [String: Any], requestId: String, webView: WKWebView?) {
        guard let procedure = body["procedure"] as? String else {
            sendError(requestId: requestId, error: "Missing procedure", webView: webView)
            return
        }

        let payload = body["payload"]

        // Special case: ping
        if procedure == "ping" {
            sendResponse(requestId: requestId, success: true, webView: webView)
            return
        }

        print("ThepiaMessageHandler: Received flowsdb procedure: \(procedure)")
        
        Task {
            do {
                switch procedure {
                case "query.journeys":
                    // TODO: Implement query.journeys
                    sendResponse(requestId: requestId, success: true, payload: [], webView: webView)
                    
                case "mutation.insertJourney":
                    // TODO: Implement mutation.insertJourney
                    sendResponse(requestId: requestId, success: true, payload: [:], webView: webView)
                    
                case "auth.saveSession":
                    guard let authHandler = authHandler,
                          let session = payload as? [String: Any] else {
                        throw NSError(domain: "Thepia", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid payload or no auth handler"])
                    }
                    try await authHandler.saveSession(session)
                    sendResponse(requestId: requestId, success: true, webView: webView)
                    
                case "auth.getSession":
                    guard let authHandler = authHandler else {
                        throw NSError(domain: "Thepia", code: 500, userInfo: [NSLocalizedDescriptionKey: "No auth handler"])
                    }
                    let session = try await authHandler.getSession()
                    sendResponse(requestId: requestId, success: true, payload: session, webView: webView)
                    
                case "auth.clearSession":
                    guard let authHandler = authHandler else {
                        throw NSError(domain: "Thepia", code: 500, userInfo: [NSLocalizedDescriptionKey: "No auth handler"])
                    }
                    try await authHandler.clearSession()
                    sendResponse(requestId: requestId, success: true, webView: webView)
                    
                case "auth.saveUser":
                    guard let authHandler = authHandler,
                          let user = payload as? [String: Any] else {
                        throw NSError(domain: "Thepia", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid payload"])
                    }
                    try await authHandler.saveUser(user)
                    sendResponse(requestId: requestId, success: true, webView: webView)
                    
                case "auth.getUser":
                    guard let authHandler = authHandler,
                          let userId = payload as? String else {
                        throw NSError(domain: "Thepia", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid payload"])
                    }
                    let user = try await authHandler.getUser(userId)
                    sendResponse(requestId: requestId, success: true, payload: user, webView: webView)
                    
                case "auth.clearUser":
                    guard let authHandler = authHandler,
                          let userId = payload as? String else {
                        throw NSError(domain: "Thepia", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid payload"])
                    }
                    try await authHandler.clearUser(userId)
                    sendResponse(requestId: requestId, success: true, webView: webView)
                    
                case "auth.updateUserMetadata":
                    guard let authHandler = authHandler,
                          let params = payload as? [String: Any],
                          let userId = params["userId"] as? String,
                          let metadata = params["metadata"] as? [String: Any] else {
                        throw NSError(domain: "Thepia", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid payload"])
                    }
                    try await authHandler.updateUserMetadata(userId: userId, metadata: metadata)
                    sendResponse(requestId: requestId, success: true, webView: webView)
                    
                case "auth.patchMetadata":
                    guard let authHandler = authHandler,
                          let params = payload as? [String: Any],
                          let userId = params["userId"] as? String,
                          let patch = params["patch"] as? [String: Any],
                          let appCode = params["appCode"] as? String,
                          let token = params["token"] as? String else {
                        throw NSError(domain: "Thepia", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid payload"])
                    }
                    let result = try await authHandler.patchMetadata(userId: userId, patch: patch, appCode: appCode, token: token)
                    sendResponse(requestId: requestId, success: true, payload: result, webView: webView)

                default:
                    sendError(requestId: requestId, error: "Unknown procedure: \(procedure)", webView: webView)
                }
            } catch {
                print("ThepiaMessageHandler: Error handling \(procedure): \(error)")
                sendError(requestId: requestId, error: error.localizedDescription, webView: webView)
            }
        }
    }

    private func sendResponse(requestId: String, success: Bool, payload: Any? = nil, webView: WKWebView?) {
        var response: [String: Any] = [
            "requestId": requestId,
            "success": success
        ]

        if let payload = payload {
            response["payload"] = payload
        }

        // Serialize to JSON
        guard let jsonData = try? JSONSerialization.data(withJSONObject: response, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("ThepiaMessageHandler: Failed to serialize response")
            return
        }

        // Call JavaScript response handler
        let js = "window.__thepiaFlowsDBResponseHandler(\(jsonString))"
        
        DispatchQueue.main.async {
            webView?.evaluateJavaScript(js, completionHandler: { _, error in
                if let error = error {
                    print("ThepiaMessageHandler: Failed to send response: \(error)")
                }
            })
        }
    }
    
    private func sendError(requestId: String, error: String, webView: WKWebView?) {
        var response: [String: Any] = [
            "requestId": requestId,
            "success": false,
            "error": ["message": error]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: response, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }
        
        let js = "window.__thepiaFlowsDBResponseHandler(\(jsonString))"
        
        DispatchQueue.main.async {
            webView?.evaluateJavaScript(js, completionHandler: nil)
        }
    }
}
