import { ApiConfig, HttpService } from '@cloudmusic/commons';
import { SearchResultPage } from '../model/SearchResult';
import { OfflineCatalog } from './OfflineCatalog';
import { isPlaylistSummary, isSongSummary } from './CatalogValidation';

export class SearchService {
  static async query(keyword: string, page: number, pageSize: number, offline: boolean): Promise<SearchResultPage> {
    if (offline) {
      return OfflineCatalog.search(keyword, page, pageSize);
    }
    const path = ApiConfig.searchPath;
    if (!path) {
      throw new Error('课程搜索接口尚未配置。');
    }
    const separator = path.includes('?') ? '&' : '?';
    const result = await HttpService.get<SearchResultPage>(path + separator + 'keyword=' + encodeURIComponent(keyword) +
      '&page=' + page.toString() + '&pageSize=' + pageSize.toString());
    if (!result || !Array.isArray(result.list) || !result.list.every(isSongSummary) ||
      typeof result.hasMore !== 'boolean' ||
      (result.playlists !== undefined && (!Array.isArray(result.playlists) || !result.playlists.every(isPlaylistSummary)))) {
      throw new Error('搜索结果格式有误，请稍后重试。');
    }
    return result;
  }
}
