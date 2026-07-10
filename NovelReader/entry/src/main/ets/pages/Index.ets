import { Book } from '../model/Book';
import { BookShelf } from '../components/BookShelf';
import { ReaderPage } from './ReaderPage';
import { SettingsPage } from './SettingsPage';
import { LoginPage } from './LoginPage';
import { RegisterPage } from './RegisterPage';
import { AuthService } from '../service/AuthService';

@Entry
@Component
struct Index {
  @State currentPage: string = 'home';
  @State selectedBookId: string = '';
  @State isLoggedIn: boolean = false;
  @State showLogin: boolean = true;
  @State refreshBooks: number = 0;

  private authService: AuthService = AuthService.getInstance();

  aboutToAppear(): void {
    this.forceLogout();
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
        Navigation() {
          if (this.currentPage === 'home') {
            NavDestination() {
              BookShelf({
                onBookClick: (book: Book) => {
                  this.selectedBookId = book.id;
                  this.currentPage = 'reader';
                },
                onSettingsClick: () => {
                  this.currentPage = 'settings';
                }
              });
            }
            .title('书架');
          }

          if (this.currentPage === 'reader') {
            NavDestination() {
              ReaderPage({
                bookId: this.selectedBookId,
                onBack: () => {
                  this.currentPage = 'home';
                }
              });
            }
            .title('阅读器');
          }

          if (this.currentPage === 'settings') {
            NavDestination() {
              SettingsPage({
                onBack: () => {
                  this.currentPage = 'home';
                },
                onLogout: () => {
                  this.logout();
                }
              });
            }
            .title('设置');
          }
        }
        .width('100%')
        .height('100%');
      }
    }
    .width('100%')
    .height('100%');
  }

  async logout(): Promise<void> {
    await this.authService.logout();
    this.isLoggedIn = false;
    this.showLogin = true;
    this.currentPage = 'home';
  }
}