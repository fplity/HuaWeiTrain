import { AppContext, Playlist, Session, Song } from '@cloudmusic/commons';
import { SearchResult } from '../model/SearchResult';
import { SearchService } from '../service/SearchService';
import { ListDataSource } from './ListDataSource';

@ObservedV2
export class SearchState {
  @Trace keyword: string = '';
  @Trace waiting: boolean = false;
  @Trace loading: boolean = false;
  @Trace count: number = 0;
  @Trace hasMore: boolean = false;
  @Trace error: string = '';

  readonly results: ListDataSource<SearchResult> = new ListDataSource<SearchResult>();
  private keys: Set<string> = new Set<string>();
  private query: string = '';
  private timer: number = -1;
  private revision: number = 0;
  private loadedPage: number = 0;

  setKeyword(value: string): void {
    this.keyword = value;
    const query = value.trim();
    if (query === this.query) {
      return;
    }
    this.cancel();
    this.query = query;
    this.loadedPage = 0;
    this.count = 0;
    this.hasMore = false;
    this.error = '';
    this.keys.clear();
    this.results.reset([]);
    if (query) {
      const revision = this.revision;
      this.waiting = true;
      this.timer = setTimeout(() => {
        this.timer = -1;
        this.waiting = false;
        this.loadPage(revision, 1);
      }, 300);
    }
  }

  loadMore(): void {
    if (this.loadedPage > 0 && this.hasMore && !this.loading && !this.error) {
      this.loadPage(this.revision, this.loadedPage + 1);
    }
  }

  retry(): void {
    if (this.error && !this.loading && this.query) {
      this.loadPage(this.revision, this.loadedPage + 1);
    }
  }

  cancel(): void {
    if (this.timer !== -1) {
      clearTimeout(this.timer);
      this.timer = -1;
    }
    this.revision++;
    this.waiting = false;
    this.loading = false;
  }

  private isCurrent(revision: number, session: Session): boolean {
    return revision === this.revision && AppContext.session.current === session;
  }

  private async loadPage(revision: number, page: number): Promise<void> {
    const session = AppContext.session.current;
    if (!session || session.user.role !== 'listener' || this.loading || revision !== this.revision) {
      return;
    }
    this.loading = true;
    this.error = '';
    try {
      const result = await SearchService.query(this.query, page, 20, session.offline);
      if (!this.isCurrent(revision, session)) {
        return;
      }
      const rows = this.toRows(result.playlists ?? [], result.list);
      this.loadedPage = page;
      // Stop auto-loading if an inconsistent backend repeats a page without providing any new rows.
      this.hasMore = result.hasMore && rows.length > 0;
      if (page === 1) {
        this.results.reset(rows);
      } else {
        this.results.append(rows);
      }
      this.count = this.results.totalCount();
    } catch (error) {
      if (this.isCurrent(revision, session)) {
        this.error = (error as Error).message || '暂时无法搜索。';
      }
    } finally {
      if (this.isCurrent(revision, session)) {
        this.loading = false;
      }
    }
  }

  private toRows(playlists: Playlist[], songs: Song[]): SearchResult[] {
    const rows: SearchResult[] = [];
    playlists.forEach((playlist: Playlist) => {
      const key = 'playlist:' + playlist.id.toString();
      if (!this.keys.has(key)) {
        this.keys.add(key);
        rows.push({
          key: key,
          title: playlist.name,
          subtitle: playlist.albumArtist ? '专辑 · ' + playlist.albumArtist :
            '歌单 · ' + playlist.playCount.toString() + ' 次播放',
          coverUrl: playlist.coverUrl ?? '',
          artworkId: playlist.id,
          playlistId: playlist.id
        });
      }
    });
    songs.forEach((song: Song) => {
      const key = 'song:' + song.id.toString();
      if (!this.keys.has(key)) {
        this.keys.add(key);
        rows.push({
          key: key,
          title: song.title,
          subtitle: song.artist,
          coverUrl: song.coverUrl ?? '',
          artworkId: song.id,
          song: song
        });
      }
    });
    return rows;
  }
}
