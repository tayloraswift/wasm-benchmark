#if !WebAssembly
enum GameAPI {
    #error("this target requires the 'WebAssembly' trait to be enabled")
}
#else

import GameEconomy
import Identifiers
import JavaScriptEventLoop
import JavaScriptKit

typealias DefaultExecutorFactory = JavaScriptEventLoop

@MainActor struct GameAPI {
    init() {
    }
}

@main extension GameAPI {
    static func main() async throws {
        JavaScriptEventLoop.installGlobalExecutor()

        do {
            let main: Self = .init()
            try await main.run()
        } catch let error {
            print("Fatal error in main: \(error)")
        }
    }
}
extension GameAPI {
    private func run() async throws {
        let executor: WebWorkerTaskExecutor = try await .init(numberOfThreads: 4)
        defer {
            executor.terminate()
        }

        print("Game engine initialized!")

        print("Game engine launched!")
        let _: Task<Void, any Error> = .init(executorPreference: executor) {
            let resources: [Quantity<Resource>] = [
                .init(amount: 10, unit: 0),
                .init(amount: 20, unit: 1),
                .init(amount: 30, unit: 2),
                .init(amount: 30, unit: 3),
            ]
            var buffer: [ResourceInputs] = (0 ..< 10000).map { _ in .empty }
            for i: Int in buffer.indices {
                buffer[i].sync(
                    tier: resources,
                    scale: (x: Int64.init(i), z: 0.05 * Double.init(1 + i))
                )
            }

            print("Starting benchmark...")

            for loop: Int64 in 0... {
                print("Tick \(loop)")
                for i: Int in buffer.indices {
                    buffer[i].touch(
                        tier: resources,
                        scale: (x: Int64.init(i), z: 0.05 * Double.init(1 + i)),
                    )
                }
            }

            print(buffer.reduce(0) { $0 + $1.fulfilled })
        }
        try await Task.sleep(for: .seconds(100))
    }
}

#endif
