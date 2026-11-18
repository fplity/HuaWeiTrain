import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { Log } from '../utils/Log';

export class ApiConfig {
  static readonly baseUrl: string = 'https://127.0.0.1:8443';
  static readonly loginPath: string = '/auth/login';
  static readonly searchPath: string = '/search';
  static readonly playlistDetailPath: string = '/playlist/{id}';
  static caPath: string | undefined;

  static get socketUrl(): string {
    return 'wss://' + ApiConfig.baseUrl.substring('https://'.length) + '/ws';
  }

  static get loginReady(): boolean {
    return ApiConfig.baseUrl.startsWith('https://') &&
      (!ApiConfig.baseUrl.startsWith('https://127.0.0.1:') || !!ApiConfig.caPath);
  }

  static loadDevelopmentCertificate(context: common.UIAbilityContext): void {
    if (!ApiConfig.baseUrl.startsWith('https://127.0.0.1:')) {
      return;
    }
    try {
      const bytes = context.resourceManager.getRawFileContentSync('echo-dev-ca.pem');
      const path = context.cacheDir + '/echo-dev-ca.pem';
      const file = fileIo.openSync(path, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
      try {
        fileIo.writeSync(file.fd, bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength));
        ApiConfig.caPath = path;
      } finally {
        fileIo.closeSync(file);
      }
    } catch (_) {
      ApiConfig.caPath = undefined;
      Log.info('Config', 'Local TLS certificate unavailable');
    }
  }
}