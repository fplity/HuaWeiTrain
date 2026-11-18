import { ApiConfig, HttpService } from '@cloudmusic/commons';
import { PlaylistDetails } from '../model/PlaylistDetails';
import { isPlaylistSummary, isPositiveId, isSongSummary } from './CatalogValidation';
import { OfflineCatalog } from './OfflineCatalog';

export class PlaylistService {
  static async load(id: number, offline: boolean): Promise<PlaylistDetails> {
    if (!isPositiveId(id)) {
      throw new Error('无效的歌单编号。');
    }
    if (offline) {
      const details = OfflineCatalog.playlist(id);
      if (!details) {
        throw new Error('找不到这个离线歌单。');
      }
      return details;
    }
    const path = ApiConfig.playlistDetailPath;
    if (!path || !path.includes('{id}')) {
      throw new Error('课程歌单详情接口尚未配置。');
    }
    const details = await HttpService.get<PlaylistDetails>(path.replace('{id}', id.toString()));
    if (!isPlaylistSummary(details) || details.id !== id || !Array.isArray(details.songs) ||
      !details.songs.every(isSongSummary) ||
      (details.description !== undefined && typeof details.description !== 'string')) {
      throw new Error('歌单数据格式有误，请稍后重试。');
    }
    return details;
  }
}
