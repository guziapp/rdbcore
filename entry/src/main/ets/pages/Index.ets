import { OrderPage } from '../demo/pages/OrderPage'
import { UserListPage } from '../demo/pages/UserListPage'

@Entry
@Component
struct Index {
  private stack: NavPathStack = new NavPathStack()

  build() {
    Navigation(this.stack) {
      Column() {
        // OrderPage()
        UserListPage()
      }
      .height('100%')
      .width('100%')
    }
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)  }
}