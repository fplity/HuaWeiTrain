import { resourceManager } from '@kit.LocalizationKit';
import { util } from '@kit.ArkTS';
import { Playlist } from '@cloudmusic/commons';

export interface OfflinePlaylist extends Playlist {
  trackIds?: number[];
}

export class OfflineFeed {
  static playlists: OfflinePlaylist[] = [];
  static sunny: OfflinePlaylist | undefined;

  static load(manager: resourceManager.ResourceManager): void {
    const bytes = manager.getRawFileContentSync('playlist-seed.json');
    const items = JSON.parse(util.TextDecoder.create('utf-8').decodeToString(bytes)) as OfflinePlaylist[];
    OfflineFeed.playlists = items.filter((item: OfflinePlaylist) => item.id !== 201);
    OfflineFeed.sunny = items.find((item: OfflinePlaylist) => item.id === 201);
  }
}