/**
 * 设置页面组件
 * 负责阅读配置管理字体大小、行间距、主题、翻页模式
 * 提供书籍管理功能 清空书籍、重新扫描
 */
import { Book, ReaderConfig, ThemeConfig } from '../model/Book';
import { ReaderConfigService } from '../service/ReaderConfigService';
import { BookDataService } from '../service/BookDataService';
import { BookScanService } from '../service/BookScanService';
import { CloudStorageService } from '../service/CloudStorageService';
import promptAction from '@ohos.promptAction';

@Component
export struct SettingsPage {
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
  @State bookCount: number = 0;
  @State cloudSyncEnabled: boolean = false;
  @State cloudSyncStatus: string = '未连接';
  private readerConfigService: ReaderConfigService = ReaderConfigService.getInstance();
  private bookDataService: BookDataService = BookDataService.getInstance();
  private bookScanService: BookScanService = BookScanService.getInstance();
  private cloudStorageService: CloudStorageService = CloudStorageService.getInstance();
  onBack?: () => void;
  onLogout?: () => void;

  aboutToAppear(): void {
    this.loadConfig();
    this.updateBookCount();
    this.updateCloudSyncStatus();
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

  private updateBookCount(): void {
    const books = this.bookDataService.getAllBooks();
    this.bookCount = books.length;
  }

  private updateFontSize(delta: number): void {
    this.config.fontSize = Math.max(12, Math.min(32, this.config.fontSize + delta));
    this.readerConfigService.saveConfig(this.config);
  }

  private updateLineSpacing(delta: number): void {
    this.config.lineSpacing = Math.max(1.0, Math.min(3.0, this.config.lineSpacing + delta));
    this.readerConfigService.saveConfig(this.config);
  }

  private updateBrightness(delta: number): void {
    this.config.brightness = Math.max(20, Math.min(100, this.config.brightness + delta));
    this.readerConfigService.saveConfig(this.config);
  }

  private changeTheme(theme: 'light' | 'dark' | 'sepia' | 'green'): void {
    this.config.theme = theme;
    this.readerConfigService.saveConfig(this.config);
    this.updateThemeConfig();
  }

  private changePageTurnMode(mode: 'slide' | 'flip' | 'scroll'): void {
    this.config.pageTurnMode = mode;
    this.readerConfigService.saveConfig(this.config);
  }

  private toggleKeepScreenOn(): void {
    this.config.keepScreenOn = !this.config.keepScreenOn;
    this.readerConfigService.saveConfig(this.config);
  }

  private toggleTextToSpeech(): void {
    this.config.textToSpeechEnabled = !this.config.textToSpeechEnabled;
    this.readerConfigService.saveConfig(this.config);
  }

  private async rescanBooks(): Promise<void> {
    try {
      promptAction.showToast({ message: '开始扫描书籍...', duration: 2000 });
      const books: Book[] = await this.bookScanService.scanAllBooks();
      const booksLen: number = books.length;
      for (let i: number = 0; i < booksLen; i++) {
        this.bookDataService.addBook(books[i]);
      }
      this.updateBookCount();
      promptAction.showToast({ message: '扫描完成', duration: 2000 });
    } catch (error) {
      promptAction.showToast({ message: '扫描失败', duration: 2000 });
    }
  }

  private async importBook(): Promise<void> {
    try {
      promptAction.showToast({ message: '请选择书籍文件', duration: 2000 });
      const book: Book | null = await this.bookScanService.selectBookFile();
      if (book) {
        const success: boolean = this.bookDataService.addBook(book);
        if (success) {
          this.updateBookCount();
          promptAction.showToast({ message: `成功导入: ${book.name}`, duration: 2000 });
        } else {
          promptAction.showToast({ message: '书籍已存在', duration: 2000 });
        }
      } else {
        promptAction.showToast({ message: '未选择文件', duration: 2000 });
      }
    } catch (error) {
      promptAction.showToast({ message: '导入失败', duration: 2000 });
    }
  }

  private async importMultipleBooks(): Promise<void> {
    try {
      promptAction.showToast({ message: '请选择书籍文件', duration: 2000 });
      const books: Book[] = await this.bookScanService.selectMultipleBooks();
      if (books.length > 0) {
        let count: number = 0;
        const len: number = books.length;
        for (let i: number = 0; i < len; i++) {
          if (this.bookDataService.addBook(books[i])) {
            count++;
          }
        }
        this.updateBookCount();
        promptAction.showToast({ message: `成功导入 ${count} 本书籍`, duration: 2000 });
      } else {
        promptAction.showToast({ message: '未选择文件', duration: 2000 });
      }
    } catch (error) {
      promptAction.showToast({ message: '导入失败', duration: 2000 });
    }
  }

  private clearAllBooks(): void {
    this.bookDataService.clearAllBooks();
    this.updateBookCount();
    promptAction.showToast({ message: '已清空书架', duration: 2000 });
  }

  private async createTestBooks(): Promise<void> {
    try {
      promptAction.showToast({ message: '正在生成测试书籍...', duration: 2000 });
      await this.bookScanService.createTestBooks();
      const books: Book[] = await this.bookScanService.scanAllBooks();
      const booksLen: number = books.length;
      for (let i: number = 0; i < booksLen; i++) {
        this.bookDataService.addBook(books[i]);
      }
      this.updateBookCount();
      promptAction.showToast({ message: '测试书籍生成完成', duration: 2000 });
    } catch (error) {
      promptAction.showToast({ message: '生成失败', duration: 2000 });
    }
  }

  private resetToDefault(): void {
    this.readerConfigService.resetToDefault();
    this.loadConfig();
    promptAction.showToast({ message: '已恢复默认设置', duration: 2000 });
  }

  private updateCloudSyncStatus(): void {
    this.cloudSyncEnabled = this.cloudStorageService.isSyncEnabled();
    this.cloudSyncStatus = this.cloudStorageService.isSyncConnected() ? '已连接' : '未连接';
  }

  private async toggleCloudSync(): Promise<void> {
    if (this.cloudSyncEnabled) {
      this.cloudStorageService.disableSync();
      this.cloudSyncEnabled = false;
      this.cloudSyncStatus = '已关闭';
      promptAction.showToast({ message: '云同步已关闭', duration: 2000 });
    } else {
      const success = await this.cloudStorageService.enableSync();
      if (success) {
        this.cloudSyncEnabled = true;
        this.cloudSyncStatus = '已连接';
        await this.bookDataService.syncFromCloud();
        this.updateBookCount();
        promptAction.showToast({ message: '云同步已开启', duration: 2000 });
      } else {
        promptAction.showToast({ message: '云同步开启失败', duration: 2000 });
      }
    }
  }

  private handleBack(): void {
    if (this.onBack) {
      this.onBack();
    }
  }

  build() {
    Column() {
      Row() {
        Button('返回')
          .width(60)
          .height(36)
          .onClick(() => {
            this.handleBack();
          });
        Blank();
        Text('设置')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeConfig.titleColor);
        Blank();
        Text(' ')
          .width(60);
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 20 });

      Scroll() {
        Column() {
          Text('书架信息')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 20, top: 20, bottom: 10 })
            .fontColor(this.themeConfig.titleColor);
          Row() {
            Text('书籍数量')
              .fontSize(16)
              .margin({ left: 20 })
              .fontColor(this.themeConfig.textColor);
            Blank();
            Text(`${this.bookCount} 本`)
              .fontSize(16)
              .margin({ right: 20 })
              .fontColor(this.themeConfig.textColor);
          }
          .width('100%')
          .padding({ top: 10, bottom: 10 });

          Button('重新扫描书籍')
            .width('80%')
            .height(44)
            .margin({ top: 10 })
            .onClick(() => {
              this.rescanBooks();
            });

          Button('导入单本书')
            .width('80%')
            .height(44)
            .margin({ top: 10 })
            .onClick(() => {
              this.importBook();
            });

          Button('批量导入书籍')
            .width('80%')
            .height(44)
            .margin({ top: 10 })
            .onClick(() => {
              this.importMultipleBooks();
            });

          Button('清空书架')
            .width('80%')
            .height(44)
            .margin({ top: 10 })
            .onClick(() => {
              this.clearAllBooks();
            });

          Button('生成测试书籍')
            .width('80%')
            .height(44)
            .margin({ top: 10 })
            .backgroundColor('#4ECDC4')
            .fontColor('#FFFFFF')
            .onClick(() => {
              this.createTestBooks();
            });

          Divider()
            .width('90%')
            .margin({ top: 20 });

          Text('阅读设置')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 20, top: 20, bottom: 10 })
            .fontColor(this.themeConfig.titleColor);

          Text('字体大小')
            .fontSize(16)
            .margin({ left: 20 })
            .fontColor(this.themeConfig.textColor);
          Row() {
            Button('-')
              .width(50)
              .height(36)
              .onClick(() => {
                this.updateFontSize(-2);
              });
            Text(`${this.config.fontSize}px`)
              .fontSize(16)
              .margin({ left: 20, right: 20 })
              .fontColor(this.themeConfig.textColor);
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
            .margin({ left: 20, top: 20 })
            .fontColor(this.themeConfig.textColor);
          Row() {
            Button('-')
              .width(50)
              .height(36)
              .onClick(() => {
                this.updateLineSpacing(-0.2);
              });
            Text(`${this.config.lineSpacing.toFixed(1)}`)
              .fontSize(16)
              .margin({ left: 20, right: 20 })
              .fontColor(this.themeConfig.textColor);
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

          Text('亮度')
            .fontSize(16)
            .margin({ left: 20, top: 20 })
            .fontColor(this.themeConfig.textColor);
          Row() {
            Button('-')
              .width(50)
              .height(36)
              .onClick(() => {
                this.updateBrightness(-10);
              });
            Text(`${this.config.brightness}%`)
              .fontSize(16)
              .margin({ left: 20, right: 20 })
              .fontColor(this.themeConfig.textColor);
            Button('+')
              .width(50)
              .height(36)
              .onClick(() => {
                this.updateBrightness(10);
              });
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ top: 10 });

          Divider()
            .width('90%')
            .margin({ top: 20 });

          Text('主题')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 20, top: 20, bottom: 10 })
            .fontColor(this.themeConfig.titleColor);
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

          Divider()
            .width('90%')
            .margin({ top: 20 });

          Text('翻页模式')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 20, top: 20, bottom: 10 })
            .fontColor(this.themeConfig.titleColor);
          Row() {
            Button('滑动')
              .width(60)
              .height(36)
              .margin({ left: 10 })
              .onClick(() => {
                this.changePageTurnMode('slide');
              });
            Button('翻页')
              .width(60)
              .height(36)
              .margin({ left: 10 })
              .onClick(() => {
                this.changePageTurnMode('flip');
              });
            Button('滚动')
              .width(60)
              .height(36)
              .margin({ left: 10 })
              .onClick(() => {
                this.changePageTurnMode('scroll');
              });
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ top: 10 });

          Divider()
            .width('90%')
            .margin({ top: 20 });

          Text('其他设置')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 20, top: 20, bottom: 10 })
            .fontColor(this.themeConfig.titleColor);

          Row() {
            Text('保持屏幕常亮')
              .fontSize(16)
              .margin({ left: 20 })
              .fontColor(this.themeConfig.textColor);
            Blank();
            Button(this.config.keepScreenOn ? '开' : '关')
              .width(60)
              .height(36)
              .margin({ right: 20 })
              .onClick(() => {
                this.toggleKeepScreenOn();
              });
          }
          .width('100%')
          .padding({ top: 10, bottom: 10 });

          Row() {
            Text('朗读功能')
              .fontSize(16)
              .margin({ left: 20 })
              .fontColor(this.themeConfig.textColor);
            Blank();
            Button(this.config.textToSpeechEnabled ? '开' : '关')
              .width(60)
              .height(36)
              .margin({ right: 20 })
              .onClick(() => {
                this.toggleTextToSpeech();
              });
          }
          .width('100%')
          .padding({ top: 10, bottom: 10 });

          Row() {
            Text('云同步')
              .fontSize(16)
              .margin({ left: 20 })
              .fontColor(this.themeConfig.textColor);
            Blank();
            Column() {
              Button(this.cloudSyncEnabled ? '开' : '关')
                .width(60)
                .height(36)
                .onClick(() => {
                  this.toggleCloudSync();
                });
              Text(this.cloudSyncStatus)
                .fontSize(12)
                .fontColor('#999999')
                .margin({ top: 4 });
            }
            .margin({ right: 20 });
          }
          .width('100%')
          .padding({ top: 10, bottom: 10 });

          Divider()
            .width('90%')
            .margin({ top: 20 });

          Button('恢复默认设置')
            .width('80%')
            .height(44)
            .margin({ top: 20 })
            .onClick(() => {
              this.resetToDefault();
            });

          Button('退出登录')
            .width('80%')
            .height(44)
            .margin({ top: 20 })
            .backgroundColor('#FF6B6B')
            .fontColor('#FFFFFF')
            .onClick(() => {
              if (this.onLogout) {
                this.onLogout();
              }
            });

          Text('版本号 1.0.0')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 30 })
            .alignSelf(ItemAlign.Center);
        }
        .width('100%');
      }
      .width('100%')
      .height('90%');
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeConfig.backgroundColor);
  }
}