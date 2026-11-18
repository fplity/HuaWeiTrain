import { http } from '@kit.NetworkKit';
import { ApiConfig } from '../config/ApiConfig';
import { Session } from '../model/User';
import { Log } from './Log';
import { AppContext } from './AppContext';

interface Result<T> {
  code: number;
  msg: string;
  data: T;
}

export class HttpService {
  static get<T>(path: string): Promise<T> {
    return HttpService.request<T>(http.RequestMethod.GET, path);
  }

  static post<T>(path: string, body?: object, authenticated: boolean = true): Promise<T> {
    return HttpService.request<T>(http.RequestMethod.POST, path, body, authenticated);
  }

  private static async request<T>(method: http.RequestMethod, path: string, body?: object,
    authenticated: boolean = true): Promise<T> {
    const base = ApiConfig.baseUrl.replace(/\/+$/, '');
    if (!ApiConfig.loginReady || !path.startsWith('/') || path.startsWith('//')) {
      throw new Error('请先配置本地 Java 服务的 HTTPS 地址。');
    }
    const session = authenticated ? AppContext.session.current : undefined;
    if (authenticated && (!session || session.offline)) {
      throw new Error('请使用课程账号登录后访问服务器。');
    }

    const headers: Record<string, string> = {
      'Accept': 'application/json'
    };
    if (session) {
      headers['Authorization'] = 'Bearer ' + session.token;
    }
    if (body) {
      headers['Content-Type'] = 'application/json';
    }
    const options: http.HttpRequestOptions = {
      method: method,
      header: headers,
      extraData: body ? JSON.stringify(body) : undefined,
      expectDataType: http.HttpDataType.STRING,
      usingCache: false,
      connectTimeout: 8000,
      readTimeout: 15000
    };
    if (ApiConfig.caPath) {
      options.caPath = ApiConfig.caPath;
    }
    const route = path.split('?')[0];
    const req = http.createHttp();
    try {
      let response: http.HttpResponse;
      try {
        response = await req.request(base + path, options);
      } catch (_) {
        Log.error('HTTP', method + ' ' + route + ' transport failure');
        throw new Error('暂时无法连接服务器，请检查网络后重试。');
      }
      if (response.responseCode >= 400) {
        Log.warning('HTTP', method + ' ' + route + ' status ' + response.responseCode.toString());
      }
      if (response.responseCode === 401) {
        return await HttpService.unauthorized(session);
      }
      const success = response.responseCode >= 200 && response.responseCode < 300;
      let result: Result<T>;
      try {
        result = JSON.parse(response.result as string) as Result<T>;
      } catch (_) {
        throw new Error(success ? '服务器返回的格式有误。' : '请求失败，HTTP ' + response.responseCode + '。');
      }
      if (result?.code === 401) {
        Log.warning('HTTP', method + ' ' + route + ' business code 401');
        return await HttpService.unauthorized(session);
      }
      if (!success || !result || typeof result.code !== 'number') {
        throw new Error('请求失败，HTTP ' + response.responseCode + '。');
      }
      if (result.code !== 0) {
        Log.warning('HTTP', method + ' ' + route + ' business code ' + result.code.toString());
        throw new Error(typeof result.msg === 'string' && result.msg ? result.msg : '请求失败。');
      }
      return result.data;
    } finally {
      req.destroy();
    }
  }

  private static async unauthorized(session?: Session): Promise<never> {
    if (session) {
      await AppContext.expire(session);
      throw new Error('登录已过期，请重新登录。');
    }
    throw new Error('账号或密码有误。');
  }
}
