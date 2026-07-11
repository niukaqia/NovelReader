/**
 * 书架组件
 * 负责展示书籍列表、分类筛选、书籍扫描和阅读进度显示
 */
import { Book, BookCategory, BOOK_CATEGORIES, ThemeConfig } from '../model/Book';
import { BookDataService } from '../service/BookDataService';
import { BookScanService } from '../service/BookScanService';
import { ReaderConfigService } from '../service/ReaderConfigService';

@Component
export struct BookShelf {
  @State books: Book[] = [];
  @State isScanning: boolean = false;
  @State currentCategory: BookCategory = '全部';
  @State themeConfig: ThemeConfig = {
    backgroundColor: '#FFFFFF',
    textColor: '#333333',
    titleColor: '#000000'
  };
  @Prop @Watch('onRefreshTheme') refreshTheme: number = 0;
  @Prop @Watch('onRefreshBooks') refreshBooks: number = 0;
  private bookDataService: BookDataService = BookDataService.getInstance();
  private bookScanService: BookScanService = BookScanService.getInstance();
  private readerConfigService: ReaderConfigService = ReaderConfigService.getInstance();
  onBookClick?: (book: Book) => void;

  aboutToAppear(): void {
    this.loadThemeConfig();
    this.loadBooks();
  }

  private onRefreshTheme() {
    this.loadThemeConfig();
  }

  private onRefreshBooks() {
    this.scanBooks();
  }

  private loadThemeConfig(): void {
    const config = this.readerConfigService.loadConfig();
    this.themeConfig = this.readerConfigService.getThemeConfig(config.theme);
  }

  /**
   * 根据当前分类加载书籍列表
   */
  private async loadBooks(): Promise<void> {
    const books: Book[] = this.bookDataService.getBooksByCategory(this.currentCategory);
    this.books = JSON.parse(JSON.stringify(books));
  }

  private onCategoryChange(category: BookCategory): void {
    this.currentCategory = category;
    this.loadBooks();
  }

  /**
   * 扫描本地书籍文件
   * 调用 BookScanService 扫描所有目录，并将扫描结果添加到书架
   * 如果测试书籍不存在，则自动创建
   */
  private async scanBooks(): Promise<void> {
    if (this.isScanning) {
      return;
    }
    this.isScanning = true;
    await this.bookScanService.createTestBooks();
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

  private getCategoryBtnBgColor(): string {
    if (this.themeConfig.backgroundColor === '#FFFFFF' || this.themeConfig.backgroundColor === '#F5E6D3') {
      return '#EEEEEE';
    } else {
      return '#333333';
    }
  }

  build() {
    Column() {
      Row() {
        Scroll() {
          Row() {
            ForEach(BOOK_CATEGORIES, (category: BookCategory) => {
              Button(category)
                .width(60)
                .height(32)
                .margin({ left: 10 })
                .backgroundColor(this.currentCategory === category ? '#4A90D9' : this.getCategoryBtnBgColor())
                .fontColor(this.currentCategory === category ? '#FFFFFF' : this.themeConfig.textColor)
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
            .fontColor(this.themeConfig.textColor);
          Text('点击右上角扫描按钮添加书籍')
            .fontSize(14)
            .fontColor(this.themeConfig.textColor)
            .opacity(0.6)
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
                  .backgroundColor(item.cover || '#4A90D9');
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
                  .fontColor(this.themeConfig.textColor)
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