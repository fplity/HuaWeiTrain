import { common } from '@kit.AbilityKit';
import { settings } from '@kit.BasicServicesKit';

export function allowsPlayerMotion(context: common.Context | undefined): boolean {
  if (context) {
    try {
      return Number(settings.getValueSync(context, settings.display.ANIMATOR_DURATION_SCALE, '1')) !== 0;
    } catch (_) {
      // A platform without this setting keeps its default animation behavior.
    }
  }
  return true;
}
