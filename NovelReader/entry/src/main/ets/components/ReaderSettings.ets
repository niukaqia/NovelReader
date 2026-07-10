import { ReaderConfig, ThemeConfig } from '../model/Book';
import { ReaderConfigService } from '../service/ReaderConfigService';

@Component
export struct ReaderSettings {
  @Prop config: ReaderConfig;
  @Prop themeConfig: ThemeConfig;
  @Prop showSettings: boolean = false;
  private readerConfigService: ReaderConfigService = ReaderConfigService.getInstance();

  private updateFontSize(delta: number): void {
    this.config.fontSize = Math.max(12, Math.min(32, this.config.fontSize + delta));
    this.readerConfigService.saveConfig(this.config);
  }

  private updateLineSpacing(delta: number): void {
    this.config.lineSpacing = Math.max(1.0, Math.min(3.0, this.config.lineSpacing + delta));
    this.readerConfigService.saveConfig(this.config);
  }

  private changeTheme(theme: 'light' | 'dark' | 'sepia' | 'green'): void {
    this.config.theme = theme;
    this.readerConfigService.saveConfig(this.config);
    const config: ThemeConfig = this.readerConfigService.getThemeConfig(theme);
    this.themeConfig.backgroundColor = config.backgroundColor;
    this.themeConfig.textColor = config.textColor;
    this.themeConfig.titleColor = config.titleColor;
  }

  private changePageTurnMode(mode: 'slide' | 'flip' | 'scroll'): void {
    this.config.pageTurnMode = mode;
    this.readerConfigService.saveConfig(this.config);
  }

  build() {
    Column() {
      if (this.showSettings) {
        Text('阅读设置')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 20 })
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

        Button('关闭')
          .width('80%')
          .height(36)
          .margin({ top: 30 })
          .onClick(() => {
          });
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.config.theme === 'dark' ? '#222222' : '#FFFFFF');
  }
}