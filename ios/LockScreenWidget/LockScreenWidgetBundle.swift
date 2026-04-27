import SwiftUI
import WidgetKit

@main
struct LockScreenWidgetBundle: WidgetBundle {
    var body: some Widget {
        DialogoLockScreenWidget()
        DialogoLuzSmallSolidWidget()
        DialogoPurposeSmallSolidWidget()
        DialogoCombinedMediumSolidWidget()
    }
}
