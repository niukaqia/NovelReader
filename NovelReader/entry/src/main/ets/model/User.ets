export interface User {
  id: string;
  username: string;
  password: string;
  email?: string;
  phone?: string;
  avatar?: string;
  createTime: number;
  lastLoginTime: number;
}

export interface LoginResult {
  success: boolean;
  message: string;
  user?: User;
}

export interface RegisterResult {
  success: boolean;
  message: string;
}