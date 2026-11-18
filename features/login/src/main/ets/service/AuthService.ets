import { ApiConfig, AppContext, HttpService, LoginResp, Role, Session, isValidUser } from '@cloudmusic/commons';

interface Credentials {
  account: string;
  password: string;
}

export class AuthService {
  static async login(account: string, password: string): Promise<void> {
    if (!ApiConfig.loginReady) {
      throw new Error('课程服务尚未配置。');
    }
    const credentials: Credentials = { account: account.trim(), password: password };
    if (!credentials.account || !credentials.password) {
      throw new Error('请输入账号和密码。');
    }
    const response = await HttpService.post<LoginResp>(ApiConfig.loginPath, credentials, false);
    if (!response || typeof response.token !== 'string' || !response.token.trim() || !isValidUser(response.user)) {
      throw new Error('登录响应缺少有效的令牌或用户信息。');
    }
    await AppContext.setSession({ token: response.token, user: response.user, offline: false });
  }

  static enterOffline(role: Role): Promise<void> {
    const session: Session = {
      token: '',
      offline: true,
      user: {
        id: role === 'listener' ? 1 : 2,
        nickname: role === 'listener' ? '演示听众' : '演示运营',
        role: role,
        avatarUrl: '',
        vipLevel: 0
      }
    };
    return AppContext.setSession(session);
  }
}
