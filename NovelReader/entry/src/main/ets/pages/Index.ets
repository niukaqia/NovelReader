import { Book } from '../model/Book';
import { BookShelf } from '../components/BookShelf';
import { ReaderPage } from './ReaderPage';
import { SettingsPage } from './SettingsPage';
import { LoginPage } from './LoginPage';
import { RegisterPage } from './RegisterPage';
import { AuthService } from '../service/AuthService';
import { ReaderConfigService } from '../service/ReaderConfigService';
import { ThemeConfig } from '../model/Book';

@Entry
@Component
struct Index {
  @State currentPage: string = 'home';
  @State selectedBookId: string = '';
  @State isLoggedIn: boolean = false;
  @State showLogin: boolean = true;
  @State refreshBooks: number = 0;
  @State refreshTheme: number = 0;
  @State themeConfig: ThemeConfig = {
    backgroundColor: '#FFFFFF',
    textColor: '#333333',
    titleColor: '#000000'
  };

  private authService: AuthService = AuthService.getInstance();
  private readerConfigService: ReaderConfigService = ReaderConfigService.getInstance();

  aboutToAppear(): void {
    this.loadThemeConfig();
    this.forceLogout();
  }

  private loadThemeConfig(): void {
    const config = this.readerConfigService.loadConfig();
    this.themeConfig = this.readerConfigService.getThemeConfig(config.theme);
  }

  async forceLogout(): Promise<void> {
    await this.authService.logout();
    this.isLoggedIn = false;
    this.showLogin = true;
  }

  build() {
    Column() {
      if (!this.isLoggedIn) {
        if (this.showLogin) {
          LoginPage({
            onLoginSuccess: () => {
              this.isLoggedIn = true;
              this.showLogin = false;
              this.currentPage = 'home';
            },
            onRegisterClick: () => {
              this.showLogin = false;
            }
          });
        } else {
          RegisterPage({
            onRegisterSuccess: () => {
              this.showLogin = true;
            },
            onLoginClick: () => {
              this.showLogin = true;
            }
          });
        }
      } else {
        Column() {
          Row() {
            Text(this.currentPage === 'home' ? '鸿蒙书阁' : this.currentPage === 'reader' ? '阅读器' : '设置')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.themeConfig.titleColor);
            if (this.currentPage === 'home') {
              Blank();
              Button('设置')
                .width(60)
                .height(36)
                .margin({ right: 10 })
                .onClick(() => {
                  this.currentPage = 'settings';
                });
              Button('+ 扫描')
                .width(80)
                .height(36)
                .margin({ right: 20 })
                .onClick(() => {
                  this.refreshBooks++;
                });
            }
          }
          .width('100%')
          .height(50)
          .justifyContent(FlexAlign.Center)
          .backgroundColor(this.themeConfig.backgroundColor);

          if (this.currentPage === 'home') {
            BookShelf({
              refreshTheme: this.refreshTheme,
              refreshBooks: this.refreshBooks,
              onBookClick: (book: Book) => {
                this.selectedBookId = book.id;
                this.currentPage = 'reader';
              }
            })
            .layoutWeight(1);
          }

          if (this.currentPage === 'reader') {
            ReaderPage({
              bookId: this.selectedBookId,
              onBack: () => {
                this.currentPage = 'home';
              }
            });
          }

          if (this.currentPage === 'settings') {
            SettingsPage({
              onBack: () => {
                this.refreshTheme++;
                this.loadThemeConfig();
                this.currentPage = 'home';
              },
              onLogout: () => {
                this.logout();
              }
            });
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor(this.themeConfig.backgroundColor);
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeConfig.backgroundColor);
  }

  async logout(): Promise<void> {
    await this.authService.logout();
    this.isLoggedIn = false;
    this.showLogin = true;
    this.currentPage = 'home';
  }
}