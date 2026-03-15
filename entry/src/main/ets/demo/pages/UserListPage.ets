/**
 * 用户列表页面
 * 
 * 演示完整的用户管理功能：
 * - 用户列表展示
 * - 搜索和筛选
 * - 创建用户
 * - 更新状态
 * - 删除用户
 */
import { 
  UserListViewModel, 
  UserListViewState, 
  UserListItem,
  createUserListViewModel 
} from '../viewmodel'
import { UserStatus } from '../entity'

@Builder
export function UserListPageBuilder() {
  UserListPage()
}

@Component
export struct UserListPage {
  @State private state: UserListViewState = new UserListViewState()
  private viewModel: UserListViewModel = createUserListViewModel()
  
  // 输入框状态
  @State private searchKeyword: string = ''
  @State private newUsername: string = ''
  @State private newNickname: string = ''
  @State private showCreateDialog: boolean = false

  aboutToAppear(): void {
    this.viewModel.setStateChangeCallback((state: UserListViewState): void => {
      this.state = state
    })
    this.viewModel.initialize()
  }

  build() {
    NavDestination() {
      Column() {
        // 标题
        Text($r('app.string.demo_user_list_title'))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .margin({ bottom: 16 })

        // 搜索栏
        Row({ space: 8 }) {
          TextInput({ placeholder: '搜索用户名' })
            .layoutWeight(1)
            .onChange((value: string): void => {
              this.searchKeyword = value
            })
          
          Button('搜索')
            .onClick((): void => {
              this.viewModel.search(this.searchKeyword)
            })
        }
        .width('100%')
        .margin({ bottom: 12 })

        // 状态筛选
        Row({ space: 8 }) {
          Text('状态筛选:')
            .fontSize(14)
          
          Button('全部')
            .fontSize(12)
            .height(32)
            .onClick((): void => {
              this.viewModel.filterByStatus(null)
            })
          
          Button('已激活')
            .fontSize(12)
            .height(32)
            .onClick((): void => {
              this.viewModel.filterByStatus(UserStatus.ACTIVE)
            })
          
          Button('未激活')
            .fontSize(12)
            .height(32)
            .onClick((): void => {
              this.viewModel.filterByStatus(UserStatus.INACTIVE)
            })
        }
        .width('100%')
        .margin({ bottom: 12 })

        // 创建按钮
        Button('创建用户')
          .width('100%')
          .margin({ bottom: 8 })
          .onClick((): void => {
            this.showCreateDialog = true
          })

        // 模拟数据按钮
        Button('添加模拟数据(100条)')
          .width('100%')
          .margin({ bottom: 12 })
          .backgroundColor('#4CAF50')
          .onClick((): void => {
            this.viewModel.createMockData(100)
          })

        // 错误提示
        if (this.state.errorMessage !== '') {
          Text(this.state.errorMessage)
            .fontSize(14)
            .fontColor('#FF0000')
            .width('100%')
            .margin({ bottom: 12 })
        }

        // 加载状态
        if (this.state.loading) {
          LoadingProgress()
            .width(48)
            .height(48)
            .margin({ top: 48 })
        } else if (this.state.items.length === 0) {
          Text('暂无数据')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ top: 48 })
        } else {
          // 用户列表
          List() {
            ForEach(this.state.items, (item: UserListItem) => {
              ListItem() {
                this.UserItemCard(item)
              }
            }, (item: UserListItem): string => item.id.toString())
          }
          .layoutWeight(1)
          .width('100%')

          // 分页
          Row({ space: 16 }) {
            Button('上一页')
              .enabled(this.state.current > 1)
              .onClick((): void => {
                this.viewModel.prevPage()
              })
            
            Text(this.state.current.toString() + ' / ' + this.state.pages.toString())
              .fontSize(14)
            
            Button('下一页')
              .enabled(this.state.current < this.state.pages)
              .onClick((): void => {
                this.viewModel.nextPage()
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ top: 12 })
        }
      }
      .padding(16)
      .width('100%')
      .height('100%')
      .bindSheet($$this.showCreateDialog, this.CreateUserSheet(), {
        height: 300,
        backgroundColor: Color.White
      })
    }.hideTitleBar(true)
  }

  @Builder
  private UserItemCard(item: UserListItem) {
    Column() {
      Row() {
        Column() {
          Text(item.username)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
          
          Text(item.nickname)
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column() {
          Text(item.statusLabel)
            .fontSize(12)
            .fontColor(item.status === UserStatus.ACTIVE ? '#00AA00' : '#999999')
          
          Text(item.createdAtLabel)
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')

      Row({ space: 8 }) {
        if (item.status === UserStatus.INACTIVE) {
          Button('激活')
            .fontSize(12)
            .height(28)
            .onClick((): void => {
              this.viewModel.updateUserStatus(item.id, UserStatus.ACTIVE)
            })
        } else if (item.status === UserStatus.ACTIVE) {
          Button('禁用')
            .fontSize(12)
            .height(28)
            .onClick((): void => {
              this.viewModel.updateUserStatus(item.id, UserStatus.BANNED)
            })
        }
        
        Button('删除')
          .fontSize(12)
          .height(28)
          .backgroundColor('#FF4444')
          .onClick((): void => {
            this.viewModel.deleteUser(item.id)
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
      .margin({ top: 8 })
    }
    .padding(12)
    .backgroundColor('#F5F5F5')
    .borderRadius(8)
    .width('100%')
    .margin({ bottom: 8 })
  }

  @Builder
  private CreateUserSheet() {
    Column() {
      Text('创建用户')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16 })

      TextInput({ placeholder: '用户名' })
        .width('100%')
        .onChange((value: string): void => {
          this.newUsername = value
        })
        .margin({ bottom: 12 })

      TextInput({ placeholder: '昵称' })
        .width('100%')
        .onChange((value: string): void => {
          this.newNickname = value
        })
        .margin({ bottom: 16 })

      Row({ space: 16 }) {
        Button('取消')
          .layoutWeight(1)
          .backgroundColor('#999999')
          .onClick((): void => {
            this.showCreateDialog = false
            this.newUsername = ''
            this.newNickname = ''
          })
        
        Button('创建')
          .layoutWeight(1)
          .onClick((): void => {
            if (this.newUsername !== '' && this.newNickname !== '') {
              this.viewModel.createUser(this.newUsername, this.newNickname)
              this.showCreateDialog = false
              this.newUsername = ''
              this.newNickname = ''
            }
          })
      }
      .width('100%')
    }
    .padding(16)
    .width('100%')
  }
}
