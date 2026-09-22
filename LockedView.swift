import SwiftUI

struct LockedView: View {
    let onUnlock: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "lock.fill")
                .font(.system(size: 44))
                .foregroundStyle(MyLogTheme.purple)
            Text("MyLog 已锁定").font(.title2.bold())
            Button("解锁") {
                Task { if await AppLock.authenticate() { onUnlock() } }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

