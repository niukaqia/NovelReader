import { Book, BookCategory, BOOK_CATEGORIES } from '../model/Book';
import { BookDataService } from '../service/BookDataService';
import { BookScanService } from '../service/BookScanService';

@Component
export struct BookShelf {
  @State books: Book[] = [];
  @State isScanning: boolean = false;
  @State currentCategory: BookCategory = '全部';
  private bookDataService: BookDataService = BookDataService.getInstance();
  private bookScanService: BookScanService = BookScanService.getInstance();
  onBookClick?: (book: Book) => void;
  onSettingsClick?: () => void;

  aboutToAppear(): void {
    this.loadBooks();
  }

  private async loadBooks(): Promise<void> {
    const books: Book[] = this.bookDataService.getBooksByCategory(this.currentCategory);
    this.books = JSON.parse(JSON.stringify(books));
  }

  private onCategoryChange(category: BookCategory): void {
    this.currentCategory = category;
    this.loadBooks();
  }

  private async scanBooks(): Promise<void> {
    if (this.isScanning) {
      return;
    }
    this.isScanning = true;
    const scannedBooks: Book[] = await this.bookScanService.scanAllBooks();
    const len: number = scannedBooks.length;
    for (let i: number = 0; i < len; i++) {
      const book: Book = scannedBooks[i];
      this.bookDataService.addBook(book);
    }
    await this.loadBooks();
    this.isScanning = false;
  }

  private formatProgress(book: Book): string {
    if (book.lastReadTime === 0) {
      return '未开始';
    }
    return `第${book.lastReadChapter + 1}章 第${book.lastReadProgress + 1}页`;
  }

  private getBookWidth(): number {
    return 120;
  }

  private getBookHeight(): number {
    return 180;
  }

  build() {
    Column() {
      Row() {
        Text('书架')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 20, top: 20 });
        Blank();
        Button('设置')
          .width(60)
          .height(36)
          .margin({ right: 10, top: 20 })
          .onClick(() => {
            if (this.onSettingsClick) {
              this.onSettingsClick();
            }
          });
        Button(this.isScanning ? '扫描中...' : '+ 扫描')
          .width(80)
          .height(36)
          .margin({ right: 20, top: 20 })
          .onClick(() => {
            this.scanBooks();
          });
      }
      .width('100%');

      Row() {
        Scroll() {
          Row() {
            ForEach(BOOK_CATEGORIES, (category: BookCategory) => {
              Button(category)
                .width(60)
                .height(32)
                .margin({ left: 10 })
                .backgroundColor(this.currentCategory === category ? '#4A90D9' : '#EEEEEE')
                .fontColor(this.currentCategory === category ? '#FFFFFF' : '#000000')
                .onClick(() => {
                  this.onCategoryChange(category);
                });
            }, (category: BookCategory) => category);
          }
          .width('100%')
          .padding({ left: 10, top: 10, bottom: 10 });
        }
        .width('100%')
        .scrollBar(BarState.Off);
      }
      .width('100%');

      if (this.books.length === 0) {
        Column() {
          Text('暂无书籍')
            .fontSize(18)
            .fontColor('#999999');
          Text('点击右上角扫描按钮添加书籍')
            .fontSize(14)
            .fontColor('#CCCCCC')
            .margin({ top: 10 });
        }
        .width('100%')
        .height('60%')
        .justifyContent(FlexAlign.Center);
      } else {
        Scroll() {
          Column() {
            ForEach(this.books, (item: Book) => {
              Column() {
                Stack() {
                  Column() {
                    Text(item.name.substring(0, 2))
                      .fontSize(32)
                      .fontColor('#FFFFFF');
                  }
                  .width(this.getBookWidth())
                  .height(this.getBookHeight())
                  .justifyContent(FlexAlign.Center)
                  .backgroundColor('#4A90D9');
                  if (item.lastReadTime !== 0) {
                    Text(this.formatProgress(item))
                      .fontSize(10)
                      .fontColor('#FFFFFF')
                      .backgroundColor('#FF6B6B')
                      .padding({ left: 4, right: 4, top: 2, bottom: 2 })
                      .position({ bottom: 0, right: 0 });
                  }
                }
                .width(this.getBookWidth())
                .height(this.getBookHeight())
                .margin({ top: 10 });

                Text(item.name)
                  .fontSize(13)
                  .width(this.getBookWidth())
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ top: 5 });

                
              }
              .width(this.getBookWidth())
              .margin({ left: 15, right: 15 })
              .onClick(() => {
                if (this.onBookClick) {
                  this.onBookClick(item);
                }
              });
            }, (item: Book) => item.id);
          }
          .width('100%');
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off);
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start);
  }
}