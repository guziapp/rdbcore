/**
 * 订单页面
 * 
 * 演示完整的订单管理功能：
 * - 订单列表展示
 * - 订单详情
 * - 订单状态流转
 * - 创建订单
 */
import { 
  OrderViewModel, 
  OrderListViewState, 
  OrderDetailViewState,
  OrderView,
  OrderItemView,
  createOrderViewModel 
} from '../viewmodel'
import { OrderStatus } from '../entity'

@Builder
export function OrderPageBuilder() {
  OrderPage()
}

@Component
export struct OrderPage {
  @State private listState: OrderListViewState = new OrderListViewState()
  @State private detailState: OrderDetailViewState = new OrderDetailViewState()
  private viewModel: OrderViewModel = createOrderViewModel()
  
  // 输入框状态
  @State private searchOrderNo: string = ''
  @State private showDetailDialog: boolean = false
  @State private selectedOrderId: number = 0

  aboutToAppear(): void {
    this.viewModel.setListStateCallback((state: OrderListViewState): void => {
      this.listState = state
    })
    this.viewModel.setDetailStateCallback((state: OrderDetailViewState): void => {
      this.detailState = state
    })
    this.viewModel.initializeList()
  }

  build() {
    NavDestination() {
      Column() {
        // 标题
        Text($r('app.string.demo_order_title'))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .margin({ bottom: 16 })

        // 搜索栏
        Row({ space: 8 }) {
          TextInput({ placeholder: '搜索订单号' })
            .layoutWeight(1)
            .onChange((value: string): void => {
              this.searchOrderNo = value
            })
          
          Button('搜索')
            .onClick((): void => {
              this.viewModel.searchByOrderNo(this.searchOrderNo)
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
          
          Button('待支付')
            .fontSize(12)
            .height(32)
            .onClick((): void => {
              this.viewModel.filterByStatus(OrderStatus.PENDING_PAYMENT)
            })
          
          Button('已支付')
            .fontSize(12)
            .height(32)
            .onClick((): void => {
              this.viewModel.filterByStatus(OrderStatus.PAID)
            })
          
          Button('已完成')
            .fontSize(12)
            .height(32)
            .onClick((): void => {
              this.viewModel.filterByStatus(OrderStatus.COMPLETED)
            })
        }
        .width('100%')
        .margin({ bottom: 12 })

        // 错误提示
        if (this.listState.errorMessage !== '') {
          Text(this.listState.errorMessage)
            .fontSize(14)
            .fontColor('#FF0000')
            .width('100%')
            .margin({ bottom: 12 })
        }

        // 加载状态
        if (this.listState.loading) {
          LoadingProgress()
            .width(48)
            .height(48)
            .margin({ top: 48 })
        } else if (this.listState.items.length === 0) {
          Text('暂无数据')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ top: 48 })
        } else {
          // 订单列表
          List() {
            ForEach(this.listState.items, (item: OrderView) => {
              ListItem() {
                this.OrderItemCard(item)
              }
            }, (item: OrderView): string => item.id.toString())
          }
          .layoutWeight(1)
          .width('100%')

          // 分页
          Row({ space: 16 }) {
            Button('上一页')
              .enabled(this.listState.current > 1)
              .onClick((): void => {
                this.viewModel.goToPage(this.listState.current - 1)
              })
            
            Text(this.listState.current.toString() + ' / ' + this.listState.pages.toString())
              .fontSize(14)
            
            Button('下一页')
              .enabled(this.listState.current < this.listState.pages)
              .onClick((): void => {
                this.viewModel.goToPage(this.listState.current + 1)
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
      .bindSheet($$this.showDetailDialog, this.OrderDetailSheet(), {
        height: 500,
        backgroundColor: Color.White
      })
    }
    .hideTitleBar(true)
  }

  @Builder
  private OrderItemCard(item: OrderView) {
    Column() {
      Row() {
        Text(item.orderNo)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)

        Text(item.statusLabel)
          .fontSize(12)
          .fontColor(this.getStatusColor(item.status))
      }
      .width('100%')

      Row() {
        Text('用户ID: ' + item.userId.toString())
          .fontSize(14)
          .fontColor('#666666')
          .layoutWeight(1)

        Text('金额: ¥' + item.totalAmount.toFixed(2))
          .fontSize(14)
          .fontColor('#FF6600')
      }
      .width('100%')
      .margin({ top: 8 })

      Row() {
        Text(item.createdAtLabel)
          .fontSize(12)
          .fontColor('#999999')
          .layoutWeight(1)

        Button('查看详情')
          .fontSize(12)
          .height(28)
          .onClick((): void => {
            this.selectedOrderId = item.id
            this.viewModel.loadOrderDetail(item.id)
            this.showDetailDialog = true
          })
      }
      .width('100%')
      .margin({ top: 8 })
    }
    .padding(12)
    .backgroundColor('#F5F5F5')
    .borderRadius(8)
    .width('100%')
    .margin({ bottom: 8 })
  }

  @Builder
  private OrderDetailSheet() {
    Column() {
      Text('订单详情')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16 })

      if (this.detailState.loading) {
        LoadingProgress()
          .width(48)
          .height(48)
      } else if (this.detailState.order !== null) {
        this.OrderDetailContent(this.detailState.order)
      } else if (this.detailState.errorMessage !== '') {
        Text(this.detailState.errorMessage)
          .fontSize(14)
          .fontColor('#FF0000')
      }

      Button('关闭')
        .width('100%')
        .margin({ top: 16 })
        .onClick((): void => {
          this.showDetailDialog = false
        })
    }
    .padding(16)
    .width('100%')
  }

  @Builder
  private OrderDetailContent(order: OrderView) {
    Column() {
      // 基本信息
      Row() {
        Text('订单号:')
          .fontSize(14)
          .width(80)
        Text(order.orderNo)
          .fontSize(14)
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ bottom: 8 })

      Row() {
        Text('状态:')
          .fontSize(14)
          .width(80)
        Text(order.statusLabel)
          .fontSize(14)
          .fontColor(this.getStatusColor(order.status))
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ bottom: 8 })

      Row() {
        Text('总金额:')
          .fontSize(14)
          .width(80)
        Text('¥' + order.totalAmount.toFixed(2))
          .fontSize(14)
          .fontColor('#FF6600')
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ bottom: 8 })

      Row() {
        Text('备注:')
          .fontSize(14)
          .width(80)
        Text(order.remark !== '' ? order.remark : '无')
          .fontSize(14)
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 订单明细
      Text('订单明细')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .margin({ bottom: 8 })

      if (order.items.length > 0) {
        List() {
          ForEach(order.items, (item: OrderItemView) => {
            ListItem() {
              Row() {
                Text(item.productName)
                  .fontSize(14)
                  .layoutWeight(1)
                
                Text('¥' + item.price.toFixed(2) + ' x ' + item.quantity.toString())
                  .fontSize(12)
                  .fontColor('#666666')
                  .margin({ left: 8 })
                
                Text('¥' + item.subtotal.toFixed(2))
                  .fontSize(14)
                  .fontColor('#FF6600')
                  .margin({ left: 8 })
              }
              .width('100%')
              .padding({ top: 8, bottom: 8 })
            }
          })
        }
        .width('100%')
        .height(120)
      } else {
        Text('暂无明细')
          .fontSize(14)
          .fontColor('#999999')
      }

      // 操作按钮
      Row({ space: 8 }) {
        if (order.status === OrderStatus.PENDING_PAYMENT) {
          Button('支付')
            .layoutWeight(1)
            .onClick((): void => {
              this.viewModel.payOrder(order.id)
            })
          
          Button('取消')
            .layoutWeight(1)
            .backgroundColor('#FF4444')
            .onClick((): void => {
              this.viewModel.cancelOrder(order.id)
            })
        } else if (order.status === OrderStatus.PAID) {
          Button('发货')
            .layoutWeight(1)
            .onClick((): void => {
              this.viewModel.shipOrder(order.id)
            })
        } else if (order.status === OrderStatus.SHIPPED) {
          Button('完成')
            .layoutWeight(1)
            .onClick((): void => {
              this.viewModel.completeOrder(order.id)
            })
        }
      }
      .width('100%')
      .margin({ top: 16 })
    }
    .width('100%')
  }

  private getStatusColor(status: number): string {
    if (status === OrderStatus.PENDING_PAYMENT) {
      return '#FF9900'
    }
    if (status === OrderStatus.PAID) {
      return '#0099FF'
    }
    if (status === OrderStatus.SHIPPED) {
      return '#00AA00'
    }
    if (status === OrderStatus.COMPLETED) {
      return '#00AA00'
    }
    if (status === OrderStatus.CANCELLED) {
      return '#999999'
    }
    return '#000000'
  }
}
