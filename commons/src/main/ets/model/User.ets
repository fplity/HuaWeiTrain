export type Role = 'listener' | 'operator';

export interface User {
  id: number;
  nickname: string;
  avatarUrl: string;
  role: Role;
  vipLevel: number;
}

export interface LoginResp {
  token: string;
  user: User;
}

export interface Session extends LoginResp {
  offline: boolean;
}

export function isValidUser(user: User): boolean {
  return !!user && Number.isInteger(user.id) && user.id > 0 && typeof user.nickname === 'string' &&
    typeof user.avatarUrl === 'string' && (user.role === 'listener' || user.role === 'operator') &&
    Number.isInteger(user.vipLevel);
}
