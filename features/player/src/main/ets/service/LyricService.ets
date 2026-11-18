import { util } from '@kit.ArkTS';
import { resourceManager } from '@kit.LocalizationKit';
import { LyricLine, parseLrc } from '@cloudmusic/commons';

export class LyricService {
  static async load(manager: resourceManager.ResourceManager | undefined, url: string): Promise<LyricLine[]> {
    const match = url.match(/^rawfile:(lyric-\d+\.lrc)$/);
    if (!manager || !match) {
      return [];
    }
    const bytes = await manager.getRawFileContent(match[1]);
    return parseLrc(util.TextDecoder.create('utf-8').decodeToString(bytes));
  }
}
