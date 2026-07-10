import { AuthService } from '../service/AuthService';
import { LoginResult } from '../model/User';

@Component
export struct LoginPage {
  @State username: string = '';
  @State password: string = '';
  @State errorMessage: string = '';
  @State isLoading: boolean = false;

  private authService: AuthService = AuthService.getInstance();

  build() {
    Column() {
      Text('小说阅读器')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 100, bottom: 80 });

      Text('欢迎回来')
        .fontSize(24)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 40 });

      Column() {
        TextInput({ placeholder: '请输入用户名' })
          .width('80%')
          .height(48)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .padding({ left: 15, right: 15 })
          .onChange((value: string) => {
            this.username = value;
            this.errorMessage = '';
          });

        TextInput({ placeholder: '请输入密码' })
          .width('80%')
          .height(48)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .padding({ left: 15, right: 15 })
          .type(InputType.Password)
          .margin({ top: 15 })
          .onChange((value: string) => {
            this.password = value;
            this.errorMessage = '';
          });

        if (this.errorMessage) {
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor('#FF6B6B')
            .margin({ top: 10 });
        }

        Button(this.isLoading ? '登录中...' : '登录')
          .width('80%')
          .height(48)
          .backgroundColor('#4A90D9')
          .fontColor('#FFFFFF')
          .fontSize(18)
          .borderRadius(8)
          .margin({ top: 30 })
          .onClick(() => {
            this.login();
          });

        Row() {
          Text('还没有账号？')
            .fontSize(14)
            .fontColor('#999999');
          Text('立即注册')
            .fontSize(14)
            .fontColor('#4A90D9')
            .margin({ left: 5 })
            .onClick(() => {
              if (this.onRegisterClick) {
                this.onRegisterClick();
              }
            });
        }
        .margin({ top: 20 });
      }
      .width('100%');
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .padding({ left: 30, right: 30 });
  }

  async login(): Promise<void> {
    if (!this.username.trim()) {
      this.errorMessage = '请输入用户名';
      return;
    }

    if (!this.password.trim()) {
      this.errorMessage = '请输入密码';
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';

    try {
      const result: LoginResult = await this.authService.login(this.username, this.password);
      if (result.success) {
        if (this.onLoginSuccess) {
          this.onLoginSuccess();
        }
      } else {
        this.errorMessage = result.message;
      }
    } catch (err) {
      this.errorMessage = '登录失败，请重试';
    } finally {
      this.isLoading = false;
    }
  }

  onLoginSuccess?: () => void;
  onRegisterClick?: () => void;
}