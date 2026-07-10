import preferences from '@ohos.data.preferences';
import { BusinessError } from '@kit.BasicServicesKit';
import { User, LoginResult, RegisterResult } from '../model/User';

const TAG: string = 'AuthService';
const PREFERENCES_NAME: string = 'user_preferences';
const CURRENT_USER_KEY: string = 'current_user';
const USERS_KEY: string = 'users';

export class AuthService {
  private static instance: AuthService;
  private preferences: preferences.Preferences | null = null;

  private constructor() {}

  public static getInstance(): AuthService {
    if (!AuthService.instance) {
      AuthService.instance = new AuthService();
    }
    return AuthService.instance;
  }

  private async initPreferences(): Promise<void> {
    if (!this.preferences) {
      try {
        this.preferences = await preferences.getPreferences(getContext(), PREFERENCES_NAME);
      } catch (err) {
        console.error(TAG, `Failed to get preferences: ${(err as BusinessError).message}`);
      }
    }
  }

  private generateId(): string {
    return Date.now().toString(36) + Math.random().toString(36).substr(2);
  }

  private async getUsers(): Promise<User[]> {
    await this.initPreferences();
    try {
      const usersStr: string = await this.preferences!.get(USERS_KEY, '[]') as string;
      return JSON.parse(usersStr) as User[];
    } catch (err) {
      console.error(TAG, `Failed to get users: ${(err as BusinessError).message}`);
      return [];
    }
  }

  private async saveUsers(users: User[]): Promise<void> {
    await this.initPreferences();
    try {
      await this.preferences!.put(USERS_KEY, JSON.stringify(users));
      await this.preferences!.flush();
    } catch (err) {
      console.error(TAG, `Failed to save users: ${(err as BusinessError).message}`);
    }
  }

  async register(username: string, password: string): Promise<RegisterResult> {
    const users: User[] = await this.getUsers();

    const existingUser: User | undefined = users.find((u: User) => u.username === username);
    if (existingUser) {
      return { success: false, message: '用户名已存在' };
    }

    const newUser: User = {
      id: this.generateId(),
      username: username,
      password: password,
      createTime: Date.now(),
      lastLoginTime: Date.now()
    };

    users.push(newUser);
    await this.saveUsers(users);

    return { success: true, message: '注册成功' };
  }

  async login(username: string, password: string): Promise<LoginResult> {
    const users: User[] = await this.getUsers();

    const user: User | undefined = users.find((u: User) => u.username === username);
    if (!user) {
      return { success: false, message: '用户名不存在' };
    }

    if (user.password !== password) {
      return { success: false, message: '密码错误' };
    }

    user.lastLoginTime = Date.now();
    await this.saveUsers(users);

    await this.setCurrentUser(user);

    return { success: true, message: '登录成功', user: user };
  }

  async logout(): Promise<void> {
    await this.initPreferences();
    try {
      await this.preferences!.delete(CURRENT_USER_KEY);
      await this.preferences!.flush();
    } catch (err) {
      console.error(TAG, `Failed to logout: ${(err as BusinessError).message}`);
    }
  }

  private async setCurrentUser(user: User): Promise<void> {
    await this.initPreferences();
    try {
      await this.preferences!.put(CURRENT_USER_KEY, JSON.stringify(user));
      await this.preferences!.flush();
    } catch (err) {
      console.error(TAG, `Failed to set current user: ${(err as BusinessError).message}`);
    }
  }

  async getCurrentUser(): Promise<User | null> {
    await this.initPreferences();
    try {
      const userStr: string = await this.preferences!.get(CURRENT_USER_KEY, '') as string;
      if (!userStr) {
        return null;
      }
      return JSON.parse(userStr) as User;
    } catch (err) {
      console.error(TAG, `Failed to get current user: ${(err as BusinessError).message}`);
      return null;
    }
  }

  async isLoggedIn(): Promise<boolean> {
    const user: User | null = await this.getCurrentUser();
    return user !== null;
  }
}