import { hilog } from '@kit.PerformanceAnalysisKit';

export class Log {
  private static readonly DOMAIN: number = 0x1200;

  static info(area: string, message: string): void {
    hilog.info(Log.DOMAIN, 'Echo.' + area, '%{public}s', message);
  }

  static warning(area: string, message: string): void {
    hilog.warn(Log.DOMAIN, 'Echo.' + area, '%{public}s', message);
  }

  static error(area: string, message: string): void {
    hilog.error(Log.DOMAIN, 'Echo.' + area, '%{public}s', message);
  }
}