import { Book, Chapter, ReadingProgress, Bookmark, ReaderConfig, ThemeConfig } from '../model/Book';
import { BookDataService } from '../service/BookDataService';
import { ReaderConfigService } from '../service/ReaderConfigService';
import { SpeechService } from '../service/SpeechService';
import fileIo from '@ohos.file.fs';

@Component
export struct ReaderPage {
  @Prop @Watch('onBookIdChange') bookId: string = '';
  @State currentChapter: number = 0;
  @State currentPage: number = 0;
  @State content: string = '';
  @State chapters: Chapter[] = [];
  @State showMenu: boolean = false;
  @State showChapters: boolean = false;
  @State showSettings: boolean = false;
  @State showBookmarks: boolean = false;
  @State bookmarks: Bookmark[] = [];
  @State book: Book | undefined = undefined;
  @State config: ReaderConfig = {
    fontSize: 16,
    lineSpacing: 1.5,
    theme: 'light',
    pageTurnMode: 'slide',
    brightness: 100,
    keepScreenOn: false,
    textToSpeechEnabled: false
  };
  @State themeConfig: ThemeConfig = {
    backgroundColor: '#FFFFFF',
    textColor: '#333333',
    titleColor: '#000000'
  };
  @State translateX: number = 0;
  @State isDragging: boolean = false;
  @State startX: number = 0;
  @State startY: number = 0;
  @State animating: boolean = false;
  @State showSpeechControls: boolean = false;
  @State timerDuration: number = 0;
  @State remainingTime: number = 0;
  private bookDataService: BookDataService = BookDataService.getInstance();
  private readerConfigService: ReaderConfigService = ReaderConfigService.getInstance();
  private speechService: SpeechService = SpeechService.getInstance();
  private pageSize: number = 1000;
  private screenWidth: number = 360;
  onBack?: () => void;

  aboutToAppear(): void {
    this.loadConfig();
    this.loadBook();
  }

  private onBookIdChange() {
    if (this.bookId) {
      this.loadBook();
    }
  }

  private loadConfig(): void {
    const savedConfig: ReaderConfig = this.readerConfigService.loadConfig();
    this.config.fontSize = savedConfig.fontSize;
    this.config.lineSpacing = savedConfig.lineSpacing;
    this.config.theme = savedConfig.theme;
    this.config.pageTurnMode = savedConfig.pageTurnMode;
    this.config.brightness = savedConfig.brightness;
    this.config.keepScreenOn = savedConfig.keepScreenOn;
    this.config.textToSpeechEnabled = savedConfig.textToSpeechEnabled;
    this.updateThemeConfig();
  }

  private updateThemeConfig(): void {
    const config: ThemeConfig = this.readerConfigService.getThemeConfig(this.config.theme);
    this.themeConfig.backgroundColor = config.backgroundColor;
    this.themeConfig.textColor = config.textColor;
    this.themeConfig.titleColor = config.titleColor;
  }

  private async loadBook(): Promise<void> {
    console.info('ReaderPage', `Loading book with id: ${this.bookId}`);
    const bookItem: Book | undefined = this.bookDataService.getBookById(this.bookId);
    if (bookItem) {
      this.book = bookItem;
      console.info('ReaderPage', `Found book: ${bookItem.name}, filePath: ${bookItem.filePath}`);
      this.currentChapter = bookItem.lastReadChapter;
      this.currentPage = bookItem.lastReadProgress;
      await this.loadChapterContent(this.currentChapter);
    } else {
      console.error('ReaderPage', `Book not found with id: ${this.bookId}`);
      this.content = '未找到书籍';
    }
  }

  private async loadChapterContent(chapterIndex: number): Promise<void> {
    if (!this.book) {
      console.error('ReaderPage', 'Book is null');
      this.content = '书籍信息为空';
      return;
    }
    try {
      const filePath: string = this.book.filePath;
      console.info('ReaderPage', `Loading book from path: ${filePath}`);
      
      const fullContent: string = fileIo.readTextSync(filePath);
      console.info('ReaderPage', `Content length: ${fullContent.length}`);
      
      if (!fullContent || fullContent.length === 0) {
        this.content = '书籍内容为空';
        return;
      }
      
      this.chapters = this.parseChapters(fullContent);
      console.info('ReaderPage', `Parsed chapters: ${this.chapters.length}`);
      
      if (chapterIndex >= 0 && chapterIndex < this.chapters.length && this.chapters[chapterIndex].content && this.chapters[chapterIndex].content.length > 0) {
        this.content = this.chapters[chapterIndex].content;
        console.info('ReaderPage', `Chapter ${chapterIndex} content length: ${this.content.length}`);
      } else {
        this.content = fullContent;
        console.info('ReaderPage', 'Displaying full content');
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error('ReaderPage', `Failed to read book content: ${err.message}`);
      this.content = '无法读取书籍内容';
    }
  }

  private parseChapters(content: string): Chapter[] {
    const result: Chapter[] = [];
    const lines: string[] = content.split('\n');
    let currentChapter: string = '';
    let chapterIndex: number = 0;
    let chapterTitle: string = '第1章';
    let currentOffset: number = 0;
    const chapterPattern = /^第[\d一二三四五六七八九十百千万零〇]+[章回]/;

    const len: number = lines.length;
    for (let i: number = 0; i < len; i++) {
      const line: string = lines[i];
      const trimmedLine: string = line.trim();
      if (chapterPattern.test(trimmedLine)) {
        if (currentChapter.length > 0) {
          const chapter: Chapter = {} as Chapter;
          chapter.bookId = this.bookId;
          chapter.chapterIndex = chapterIndex;
          chapter.title = chapterTitle;
          chapter.content = currentChapter.trim();
          chapter.startOffset = currentOffset;
          chapter.endOffset = currentOffset + currentChapter.length;
          result.push(chapter);
          currentOffset = chapter.endOffset;
        }
        chapterIndex++;
        chapterTitle = trimmedLine;
        currentChapter = '';
      } else {
        currentChapter += line + '\n';
      }
    }

    if (currentChapter.length > 0) {
      const chapter: Chapter = {} as Chapter;
      chapter.bookId = this.bookId;
      chapter.chapterIndex = chapterIndex;
      chapter.title = chapterTitle;
      chapter.content = currentChapter.trim();
      chapter.startOffset = currentOffset;
      chapter.endOffset = currentOffset + currentChapter.length;
      result.push(chapter);
    }

    if (result.length === 0) {
      const chapter: Chapter = {} as Chapter;
      chapter.bookId = this.bookId;
      chapter.chapterIndex = 0;
      chapter.title = '第1章';
      chapter.content = content.trim();
      chapter.startOffset = 0;
      chapter.endOffset = content.length;
      result.push(chapter);
    }

    return result;
  }

  private getCurrentPageContent(): string {
    const start: number = this.currentPage * this.pageSize;
    const end: number = start + this.pageSize;
    return this.content.substring(start, end);
  }

  private nextPage(): void {
    const totalPages: number = Math.ceil(this.content.length / this.pageSize);
    if (this.currentPage < totalPages - 1) {
      this.currentPage++;
    } else if (this.currentChapter < this.chapters.length - 1) {
      this.currentChapter++;
      this.currentPage = 0;
      this.content = this.chapters[this.currentChapter].content;
    }
    this.saveProgress();
  }

  private prevPage(): void {
    if (this.currentPage > 0) {
      this.currentPage--;
    } else if (this.currentChapter > 0) {
      this.currentChapter--;
      this.content = this.chapters[this.currentChapter].content;
      this.currentPage = Math.ceil(this.content.length / this.pageSize) - 1;
    }
    this.saveProgress();
  }

  private saveProgress(): void {
    if (!this.book) {
      return;
    }
    const progress: ReadingProgress = {} as ReadingProgress;
    progress.bookId = this.bookId;
    progress.chapterIndex = this.currentChapter;
    progress.progress = this.currentPage;
    progress.readTime = Date.now();
    this.bookDataService.saveProgress(progress);

    if (this.book) {
      this.book.lastReadChapter = this.currentChapter;
      this.book.lastReadProgress = this.currentPage;
      this.book.lastReadTime = Date.now();
      this.bookDataService.updateBook(this.book);
    }
  }

  private addBookmark(): void {
    if (!this.book) {
      return;
    }
    const bookmark: Bookmark = {} as Bookmark;
    bookmark.id = this.bookId + '_' + Date.now();
    bookmark.bookId = this.bookId;
    bookmark.chapterIndex = this.currentChapter;
    bookmark.paragraphIndex = this.currentPage;
    bookmark.content = this.getCurrentPageContent().substring(0, 50);
    bookmark.createTime = Date.now();
    this.bookDataService.addBookmark(bookmark);
    this.showMenu = false;
    this.loadBookmarks();
  }

  private loadBookmarks(): void {
    this.bookmarks = this.bookDataService.getBookmarks(this.bookId);
    const len: number = this.bookmarks.length;
    for (let i: number = 0; i < len; i++) {
      for (let j: number = i + 1; j < len; j++) {
        if (this.bookmarks[i].createTime < this.bookmarks[j].createTime) {
          const temp = this.bookmarks[i];
          this.bookmarks[i] = this.bookmarks[j];
          this.bookmarks[j] = temp;
        }
      }
    }
  }

  private deleteBookmark(bookmarkId: string): void {
    this.bookDataService.deleteBookmark(this.bookId, bookmarkId);
    this.loadBookmarks();
  }

  private jumpToBookmark(bookmark: Bookmark): void {
    this.currentChapter = bookmark.chapterIndex;
    this.currentPage = bookmark.paragraphIndex;
    if (this.chapters[this.currentChapter]) {
      this.content = this.chapters[this.currentChapter].content;
    }
    this.showBookmarks = false;
    this.saveProgress();
  }

  private toggleSpeech(): void {
    if (this.speechService.isPlayingStatus()) {
      this.speechService.stopSpeech();
    } else {
      this.speechService.startSpeech(this.getCurrentPageContent());
    }
  }

  private showSpeechControlPanel(): void {
    this.showSpeechControls = true;
    this.showMenu = false;
  }

  private setTimer(minutes: number): void {
    this.timerDuration = minutes;
    if (minutes > 0) {
      this.speechService.setTimer(minutes);
      this.updateRemainingTime();
    } else {
      this.speechService.cancelTimer();
      this.remainingTime = 0;
    }
  }

  private updateRemainingTime(): void {
    if (this.timerDuration > 0) {
      setTimeout(() => {
        this.remainingTime = this.speechService.getRemainingTime();
        if (this.remainingTime > 0) {
          this.updateRemainingTime();
        }
      }, 60000);
    }
  }

  private handleClick(event: ClickEvent): void {
    const x: number = event.x;
    if (this.config.pageTurnMode === 'scroll') {
      this.showMenu = !this.showMenu;
      return;
    }
    if (x < this.screenWidth / 3) {
      this.prevPage();
    } else if (x > this.screenWidth * 2 / 3) {
      this.nextPage();
    } else {
      this.showMenu = !this.showMenu;
    }
  }

  private onTouchStart(event: TouchEvent): void {
    if (this.showMenu || this.showChapters || this.showSettings || this.animating) {
      return;
    }
    if (event.type === TouchType.Down) {
      this.isDragging = true;
      this.startX = event.touches[0].x;
      this.startY = event.touches[0].y;
    }
  }

  private onTouchMove(event: TouchEvent): void {
    if (!this.isDragging || this.showMenu || this.showChapters || this.showSettings) {
      return;
    }
    if (event.type === TouchType.Move) {
      const deltaX: number = event.touches[0].x - this.startX;
      const deltaY: number = event.touches[0].y - this.startY;
      if (Math.abs(deltaX) > Math.abs(deltaY) && this.config.pageTurnMode === 'slide') {
        this.translateX = deltaX;
      }
    }
  }

  private onTouchEnd(event: TouchEvent): void {
    if (!this.isDragging || this.showMenu || this.showChapters || this.showSettings) {
      return;
    }
    if (event.type === TouchType.Up) {
      this.isDragging = false;
      if (this.config.pageTurnMode === 'slide') {
        const threshold: number = this.screenWidth / 4;
        if (this.translateX > threshold) {
          this.animating = true;
          animateTo({
            duration: 200,
            curve: Curve.EaseOut,
            onFinish: () => {
              this.prevPage();
              this.translateX = 0;
              this.animating = false;
            }
          }, () => {
            this.translateX = this.screenWidth;
          });
        } else if (this.translateX < -threshold) {
          this.animating = true;
          animateTo({
            duration: 200,
            curve: Curve.EaseOut,
            onFinish: () => {
              this.nextPage();
              this.translateX = 0;
              this.animating = false;
            }
          }, () => {
            this.translateX = -this.screenWidth;
          });
        } else {
          animateTo({
            duration: 200,
            curve: Curve.EaseOut
          }, () => {
            this.translateX = 0;
          });
        }
      } else if (this.config.pageTurnMode === 'flip') {
        const deltaX: number = event.changedTouches[0].x - this.startX;
        if (deltaX > 50) {
          this.prevPage();
        } else if (deltaX < -50) {
          this.nextPage();
        }
      }
    }
  }

  private handleBack(): void {
    this.saveProgress();
    if (this.onBack) {
      this.onBack();
    }
  }

  private selectChapter(index: number): void {
    this.currentChapter = index;
    this.currentPage = 0;
    if (this.chapters[index]) {
      this.content = this.chapters[index].content;
    }
    this.showChapters = false;
    this.saveProgress();
  }

  private updateFontSize(delta: number): void {
    this.config.fontSize = Math.max(12, Math.min(32, this.config.fontSize + delta));
    this.readerConfigService.saveConfig(this.config);
  }

  private updateLineSpacing(delta: number): void {
    this.config.lineSpacing = Math.max(1.0, Math.min(3.0, this.config.lineSpacing + delta));
    this.readerConfigService.saveConfig(this.config);
  }

  private changeTheme(theme: string): void {
    const themeValue = theme as 'light' | 'dark' | 'sepia' | 'green';
    this.config.theme = themeValue;
    this.readerConfigService.saveConfig(this.config);
    this.updateThemeConfig();
    this.showSettings = false;
  }

  private getChapterTitle(): string {
    if (this.chapters[this.currentChapter]) {
      return this.chapters[this.currentChapter].title;
    }
    return '第1章';
  }

  build() {
    Stack() {
      Column() {
        Row() {
          Button('返回')
            .width(60)
            .height(36)
            .onClick(() => {
              this.handleBack();
            });
          Blank();
          Text(this.getChapterTitle())
            .fontSize(16)
            .fontColor(this.themeConfig.titleColor);
          Blank();
          Text(' ')
            .width(60);
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 10 });

        if (this.config.pageTurnMode === 'scroll') {
          Scroll() {
            Text(this.content)
              .fontSize(this.config.fontSize)
              .lineHeight(this.config.fontSize * this.config.lineSpacing)
              .fontColor(this.themeConfig.textColor)
              .backgroundColor(this.themeConfig.backgroundColor)
              .padding({ left: 20, right: 20, top: 20, bottom: 20 })
              .width('100%');
          }
          .width('100%')
          .height('100%')
          .backgroundColor(this.themeConfig.backgroundColor)
          .onClick(() => {
            this.showMenu = !this.showMenu;
          });
        } else {
          Stack() {
            Text(this.getCurrentPageContent())
              .fontSize(this.config.fontSize)
              .lineHeight(this.config.fontSize * this.config.lineSpacing)
              .fontColor(this.themeConfig.textColor)
              .backgroundColor(this.themeConfig.backgroundColor)
              .padding({ left: 20, right: 20, top: 20, bottom: 20 })
              .width('100%');
          }
          .width('100%')
          .height('100%')
          .backgroundColor(this.themeConfig.backgroundColor)
          .translate({ x: this.translateX })
          .onClick((event: ClickEvent) => {
            this.handleClick(event);
          })
          .onTouch((event: TouchEvent) => {
            this.onTouchStart(event);
            this.onTouchMove(event);
            this.onTouchEnd(event);
          });
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.themeConfig.backgroundColor);

      if (this.showMenu) {
        Column() {
          Row() {
            Button('返回')
              .width(60)
              .height(36)
              .onClick(() => {
                this.handleBack();
              });
            Blank();
            Text(this.getChapterTitle())
              .fontSize(16)
              .fontColor(this.themeConfig.textColor);
            Blank();
            Button('目录')
              .width(60)
              .height(36)
              .onClick(() => {
                this.showChapters = true;
                this.showMenu = false;
              });
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 10 });

          Row() {
            Button('上一章')
              .width(80)
              .height(36)
              .onClick(() => {
                if (this.currentChapter > 0) {
                  this.currentChapter--;
                  this.currentPage = 0;
                  this.content = this.chapters[this.currentChapter].content;
                  this.saveProgress();
                }
              });
            Blank();
            Button(this.speechService.isPlayingStatus() ? '停止朗读' : '开始朗读')
              .width(100)
              .height(36)
              .onClick(() => {
                this.toggleSpeech();
              });
            Blank();
            Button('下一章')
              .width(80)
              .height(36)
              .onClick(() => {
                if (this.currentChapter < this.chapters.length - 1) {
                  this.currentChapter++;
                  this.currentPage = 0;
                  this.content = this.chapters[this.currentChapter].content;
                  this.saveProgress();
                }
              });
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 10 });

          Row() {
            Button('字体-')
              .width(60)
              .height(36)
              .onClick(() => {
                this.updateFontSize(-2);
              });
            Text(`${this.config.fontSize}px`)
              .fontSize(16)
              .fontColor(this.themeConfig.textColor);
            Button('字体+')
              .width(60)
              .height(36)
              .onClick(() => {
                this.updateFontSize(2);
              });
            Blank();
            Button('设置')
              .width(60)
              .height(36)
              .onClick(() => {
                this.showSettings = true;
                this.showMenu = false;
              });
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 10 });

          Button('添加书签')
            .width('80%')
            .height(36)
            .margin({ top: 10 })
            .onClick(() => {
              this.addBookmark();
            });

          Button('书签列表')
            .width('80%')
            .height(36)
            .margin({ top: 10 })
            .onClick(() => {
              this.loadBookmarks();
              this.showBookmarks = true;
              this.showMenu = false;
            });

          Button('朗读控制')
            .width('80%')
            .height(36)
            .margin({ top: 10 })
            .onClick(() => {
              this.showSpeechControlPanel();
            });
        }
        .width('100%')
        .backgroundColor(this.config.theme === 'dark' ? '#333333' : '#FFFFFF')
        .padding({ bottom: 20 })
        .position({ bottom: 0 });
      }

      if (this.showChapters) {
        Column() {
          Text('目录')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 20, bottom: 10 });
          Scroll() {
            Column() {
              ForEach(this.chapters, (chapter: Chapter, index: number) => {
                Text(chapter.title)
                  .fontSize(16)
                  .fontColor(index === this.currentChapter ? '#4A90D9' : this.themeConfig.textColor)
                  .padding({ left: 20, right: 20, top: 10, bottom: 10 })
                  .onClick(() => {
                    this.selectChapter(index);
                  });
              }, (chapter: Chapter) => chapter.chapterIndex.toString());
            }
            .width('100%');
          }
          .width('100%')
          .height('70%');
          Button('关闭')
            .width('80%')
            .height(36)
            .margin({ top: 10 })
            .onClick(() => {
              this.showChapters = false;
            });
        }
        .width('100%')
        .height('100%')
        .backgroundColor(this.config.theme === 'dark' ? '#222222' : '#FFFFFF');
      }

      if (this.showSettings) {
        Column() {
          Text('阅读设置')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 20, bottom: 20 });

          Text('字体大小')
            .fontSize(16)
            .margin({ left: 20 });
          Row() {
            Button('-')
              .width(50)
              .height(36)
              .onClick(() => {
                this.updateFontSize(-2);
              });
            Text(`${this.config.fontSize}px`)
              .fontSize(16)
              .margin({ left: 20, right: 20 });
            Button('+')
              .width(50)
              .height(36)
              .onClick(() => {
                this.updateFontSize(2);
              });
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ top: 10 });

          Text('行间距')
            .fontSize(16)
            .margin({ left: 20, top: 20 });
          Row() {
            Button('-')
              .width(50)
              .height(36)
              .onClick(() => {
                this.updateLineSpacing(-0.2);
              });
            Text(`${this.config.lineSpacing.toFixed(1)}`)
              .fontSize(16)
              .margin({ left: 20, right: 20 });
            Button('+')
              .width(50)
              .height(36)
              .onClick(() => {
                this.updateLineSpacing(0.2);
              });
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ top: 10 });

          Text('主题')
            .fontSize(16)
            .margin({ left: 20, top: 20 });
          Row() {
            Button('明亮')
              .width(60)
              .height(36)
              .margin({ left: 10 })
              .onClick(() => {
                this.changeTheme('light');
              });
            Button('暗黑')
              .width(60)
              .height(36)
              .margin({ left: 10 })
              .onClick(() => {
                this.changeTheme('dark');
              });
            Button('护眼')
              .width(60)
              .height(36)
              .margin({ left: 10 })
              .onClick(() => {
                this.changeTheme('sepia');
              });
            Button('绿色')
              .width(60)
              .height(36)
              .margin({ left: 10 })
              .onClick(() => {
                this.changeTheme('green');
              });
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ top: 10 });

          Button('关闭')
            .width('80%')
            .height(36)
            .margin({ top: 30 })
            .onClick(() => {
              this.showSettings = false;
            });
        }
        .width('100%')
        .height('100%')
        .backgroundColor(this.config.theme === 'dark' ? '#222222' : '#FFFFFF');
      }

      if (this.showBookmarks) {
        Column() {
          Row() {
            Button('返回')
              .width(60)
              .height(36)
              .onClick(() => {
                this.showBookmarks = false;
              });
            Blank();
            Text('书签列表')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.themeConfig.titleColor);
            Blank();
            Text(' ')
              .width(60);
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 20 });

          if (this.bookmarks.length === 0) {
            Column() {
              Text('暂无书签')
                .fontSize(18)
                .fontColor('#999999');
            }
            .width('100%')
            .height('60%')
            .justifyContent(FlexAlign.Center);
          } else {
            Scroll() {
              Column() {
                ForEach(this.bookmarks, (bookmark: Bookmark) => {
                  Column() {
                    Row() {
                      Column() {
                        Text(this.chapters[bookmark.chapterIndex]?.title || `第${bookmark.chapterIndex + 1}章`)
                          .fontSize(16)
                          .fontColor(this.themeConfig.titleColor);
                        Text(bookmark.content)
                          .fontSize(13)
                          .fontColor('#999999')
                          .maxLines(2)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .margin({ top: 5 });
                        Text(new Date(bookmark.createTime).toLocaleString())
                          .fontSize(11)
                          .fontColor('#CCCCCC')
                          .margin({ top: 5 });
                      }
                      .flexGrow(1);
                      Button('删除')
                        .width(50)
                        .height(30)
                        .margin({ right: 10 })
                        .onClick(() => {
                          this.deleteBookmark(bookmark.id);
                        });
                    }
                    .width('100%')
                    .padding({ left: 20, right: 20, top: 15, bottom: 15 });
                    Divider()
                      .width('90%');
                  }
                  .width('100%')
                  .onClick(() => {
                    this.jumpToBookmark(bookmark);
                  });
                }, (bookmark: Bookmark) => bookmark.id);
              }
              .width('100%');
            }
            .width('100%')
            .height('70%');
          }

          Button('关闭')
            .width('80%')
            .height(36)
            .margin({ top: 10 })
            .onClick(() => {
              this.showBookmarks = false;
            });
        }
        .width('100%')
        .height('100%')
        .backgroundColor(this.config.theme === 'dark' ? '#222222' : '#FFFFFF');
      }

      if (this.showSpeechControls) {
        Column() {
          Row() {
            Button('返回')
              .width(60)
              .height(36)
              .onClick(() => {
                this.showSpeechControls = false;
              });
            Blank();
            Text('朗读控制')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.themeConfig.titleColor);
            Blank();
            Text(' ')
              .width(60);
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 20 });

          Row() {
            Button(this.speechService.isPlayingStatus() ? '暂停' : '播放')
              .width(80)
              .height(48)
              .margin({ left: 20 })
              .onClick(() => {
                this.toggleSpeech();
              });
            Button('停止')
              .width(80)
              .height(48)
              .margin({ left: 20 })
              .onClick(() => {
                this.speechService.stopSpeech();
              });
          }
          .width('100%')
          .margin({ top: 20 });

          Text('定时停止')
            .fontSize(16)
            .margin({ left: 20, top: 30 });
          Row() {
            Button('15分钟')
              .width(80)
              .height(36)
              .margin({ left: 10 })
              .backgroundColor(this.timerDuration === 15 ? '#4A90D9' : '#EEEEEE')
              .fontColor(this.timerDuration === 15 ? '#FFFFFF' : '#000000')
              .onClick(() => {
                this.setTimer(15);
              });
            Button('30分钟')
              .width(80)
              .height(36)
              .margin({ left: 10 })
              .backgroundColor(this.timerDuration === 30 ? '#4A90D9' : '#EEEEEE')
              .fontColor(this.timerDuration === 30 ? '#FFFFFF' : '#000000')
              .onClick(() => {
                this.setTimer(30);
              });
            Button('60分钟')
              .width(80)
              .height(36)
              .margin({ left: 10 })
              .backgroundColor(this.timerDuration === 60 ? '#4A90D9' : '#EEEEEE')
              .fontColor(this.timerDuration === 60 ? '#FFFFFF' : '#000000')
              .onClick(() => {
                this.setTimer(60);
              });
            Button('关闭')
              .width(80)
              .height(36)
              .margin({ left: 10 })
              .backgroundColor(this.timerDuration === 0 ? '#4A90D9' : '#EEEEEE')
              .fontColor(this.timerDuration === 0 ? '#FFFFFF' : '#000000')
              .onClick(() => {
                this.setTimer(0);
              });
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ top: 10 });

          if (this.remainingTime > 0) {
            Text(`剩余时间: ${this.remainingTime} 分钟`)
              .fontSize(14)
              .fontColor('#4A90D9')
              .margin({ top: 10 });
          }

          Text('语速调节')
            .fontSize(16)
            .margin({ left: 20, top: 30 });
          Row() {
            Button('-')
              .width(40)
              .height(36)
              .margin({ left: 20 })
              .onClick(() => {
                this.speechService.setSpeechRate(this.speechService.getSpeechRate() - 0.1);
              });
            Text(`${this.speechService.getSpeechRate().toFixed(1)}x`)
              .fontSize(16)
              .fontColor(this.themeConfig.textColor)
              .margin({ left: 20 });
            Button('+')
              .width(40)
              .height(36)
              .margin({ left: 20 })
              .onClick(() => {
                this.speechService.setSpeechRate(this.speechService.getSpeechRate() + 0.1);
              });
          }
          .width('100%')
          .margin({ top: 10 });

          Button('关闭')
            .width('80%')
            .height(36)
            .margin({ top: 30 })
            .onClick(() => {
              this.showSpeechControls = false;
            });
        }
        .width('100%')
        .height('100%')
        .backgroundColor(this.config.theme === 'dark' ? '#222222' : '#FFFFFF');
      }
    }
    .width('100%')
    .height('100%');
  }
}