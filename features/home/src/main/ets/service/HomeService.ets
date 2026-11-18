import { HttpService, Playlist, Song } from '@cloudmusic/commons';
import { BannerItem, HomeData } from '../model/HomeData';
import { OfflineCatalog } from './OfflineCatalog';

interface FeedItem {
  id: number;
}

function uniqueById<T extends FeedItem>(items: T[], isValid: (item: T) => boolean): T[] {
  const ids = new Set<number>();
  return items.filter((item: T) => {
    if (!item || !Number.isInteger(item.id) || item.id <= 0 || !isValid(item)) {
      throw new Error('推荐数据格式有误，请稍后重试。');
    }
    if (ids.has(item.id)) {
      return false;
    }
    ids.add(item.id);
    return true;
  });
}

export class HomeService {
  static async load(offline: boolean): Promise<HomeData> {
    if (offline) {
      return OfflineCatalog.home();
    }
    const data = await HttpService.get<HomeData>('/home/feed');
    if (!data || !Array.isArray(data.banners) || !Array.isArray(data.daily) || !Array.isArray(data.playlists)) {
      throw new Error('推荐数据格式有误，请稍后重试。');
    }
    return {
      banners: uniqueById(data.banners, (item: BannerItem) => typeof item.imageUrl === 'string'),
      daily: uniqueById(data.daily, (song: Song) => typeof song.title === 'string' && typeof song.artist === 'string'),
      playlists: uniqueById(data.playlists, (playlist: Playlist) => typeof playlist.name === 'string' &&
        Number.isFinite(playlist.playCount) && playlist.playCount >= 0)
    };
  }
}
