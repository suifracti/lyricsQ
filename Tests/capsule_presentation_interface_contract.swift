import Foundation

@main
struct CapsulePresentationInterfaceContract {
    static func main() {
        let v4 = CapsuleLyricsPresentationVersion.dynamicIslandDarkV4
        precondition(v4.id == "capsule.dynamicIslandDark.v4")

        // The restored island is the product default; legacy IDs remain compatible.
        precondition(CapsuleLyricsPresentationVersion.current == .dynamicIslandDarkV4)

        let sharedPresentation: any CapsulePresentation = v4
        precondition(sharedPresentation.id == "capsule.dynamicIslandDark.v4")

        print("capsule presentation interface contract passed")
    }
}
