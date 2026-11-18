import { Session } from '../model/User';
import { SessionStore } from '../store/SessionStore';
import { SessionStorage } from './SessionStorage';

export class AppContext {
  static readonly session: SessionStore = new SessionStore();

  static async restore(): Promise<void> {
    if (AppContext.session.ready) {
      return;
    }
    try {
      AppContext.session.current = await SessionStorage.read();
    } catch (error) {
      AppContext.session.notice = (error as Error).message;
    } finally {
      AppContext.session.ready = true;
    }
  }

  static async setSession(session: Session): Promise<void> {
    await SessionStorage.write(session);
    AppContext.session.notice = '';
    AppContext.session.current = session;
  }

  static async clear(): Promise<void> {
    await SessionStorage.write();
    AppContext.session.current = undefined;
    AppContext.session.notice = '';
  }

  static async expire(expected: Session): Promise<void> {
    // A delayed 401 from a previous sign-in must not clear a newer session.
    if (AppContext.session.current !== expected) {
      return;
    }
    const clearing = SessionStorage.write();
    AppContext.session.current = undefined;
    AppContext.session.notice = '登录已过期，请重新登录。';
    try {
      await clearing;
    } catch (_) {
      if (!AppContext.session.current) {
        AppContext.session.notice = '登录已过期，本机登录记录清理失败。请重新登录。';
      }
    }
  }
}
