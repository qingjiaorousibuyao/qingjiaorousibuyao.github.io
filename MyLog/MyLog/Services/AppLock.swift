import LocalAuthentication

enum AppLock {
    static func authenticate() async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else { return false }
        return (try? await context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "解锁 MyLog，查看你的私人记录"
        )) ?? false
    }
}

