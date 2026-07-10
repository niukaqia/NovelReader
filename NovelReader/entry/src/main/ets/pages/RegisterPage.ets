import { AuthService } from '../service/AuthService';
import { RegisterResult } from '../model/User';

@Component
export struct RegisterPage {
  @State username: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';
  @State errorMessage: string = '';
  @State isLoading: boolean = false;

  private authService: AuthService = AuthService.getInstance();

  build() {
    Column() {
      Text('小说阅读器')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 80, bottom: 60 });

      Text('创建账号')
        .fontSize(24)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 30 });

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

        TextInput({ placeholder: '请确认密码' })
          .width('80%')
          .height(48)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .padding({ left: 15, right: 15 })
          .type(InputType.Password)
          .margin({ top: 15 })
          .onChange((value: string) => {
            this.confirmPassword = value;
            this.errorMessage = '';
          });

        if (this.errorMessage) {
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor('#FF6B6B')
            .margin({ top: 10 });
        }

        Button(this.isLoading ? '注册中...' : '注册')
          .width('80%')
          .height(48)
          .backgroundColor('#4A90D9')
          .fontColor('#FFFFFF')
          .fontSize(18)
          .borderRadius(8)
          .margin({ top: 30 })
          .onClick(() => {
            this.register();
          });

        Row() {
          Text('已有账号？')
            .fontSize(14)
            .fontColor('#999999');
          Text('立即登录')
            .fontSize(14)
            .fontColor('#4A90D9')
            .margin({ left: 5 })
            .onClick(() => {
              if (this.onLoginClick) {
                this.onLoginClick();
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

  async register(): Promise<void> {
    if (!this.username.trim()) {
      this.errorMessage = '请输入用户名';
      return;
    }

    if (this.username.length < 3) {
      this.errorMessage = '用户名至少需要3个字符';
      return;
    }

    if (!this.password.trim()) {
      this.errorMessage = '请输入密码';
      return;
    }

    if (this.password.length < 6) {
      this.errorMessage = '密码至少需要6个字符';
      return;
    }

    if (this.password !== this.confirmPassword) {
      this.errorMessage = '两次输入的密码不一致';
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';

    try {
      const result: RegisterResult = await this.authService.register(this.username, this.password);
      if (result.success) {
        if (this.onRegisterSuccess) {
          this.onRegisterSuccess();
        }
      } else {
        this.errorMessage = result.message;
      }
    } catch (err) {
      this.errorMessage = '注册失败，请重试';
    } finally {
      this.isLoading = false;
    }
  }

  onRegisterSuccess?: () => void;
  onLoginClick?: () => void;
}