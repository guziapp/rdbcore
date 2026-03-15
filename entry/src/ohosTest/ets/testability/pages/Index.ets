@Entry
@Component
struct Index {
  aboutToAppear(): void {
  }

  build() {
    Row() {
      Column() {
        Text('Entry Test')
          .fontSize(50)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
    }
    .height('100%')
  }
}
