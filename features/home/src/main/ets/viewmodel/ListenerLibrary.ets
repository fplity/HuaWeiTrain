import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { Log, Session, SongFavorites } from '@cloudmusic/commons';

export type LibrarySection = 'recent' | 'favorites' | 'playlist';

export interface LibraryPath {
  section: LibrarySection;
  playlistId?: number;
}

export interface PersonalPlaylist {
  id: number;
  name: string;
  songIds: number[];
}

interface LibraryData {
  recent: number[];
  favorites: number[];
  playlists: PersonalPlaylist[];
}

const DATA_KEY: string = 'data';
const RECENT_LIMIT: number = 50;

@ObservedV2
export class ListenerLibrary implements SongFavorites {
  @Trace recent: number[] = [];
  @Trace favorites: number[] = [];
  @Trace playlists: PersonalPlaylist[] = [];
  @Trace notice: string = '';
  private storage: preferences.Preferences | undefined;
  private pendingWrite: Promise<void> = Promise.resolve();

  load(context: common.Context, session: Session): void {
    try {
      const mode = session.offline ? 'offline' : 'online';
      this.storage = preferences.getPreferencesSync(context, {
        name: 'echo_library_' + mode + '_' + session.user.id.toString()
      });
      const stored = this.storage.getSync(DATA_KEY, '') as string;
      if (stored) {
        const data = JSON.parse(stored) as LibraryData;
        this.recent = Array.isArray(data.recent) ? data.recent : [];
        this.favorites = Array.isArray(data.favorites) ? data.favorites : [];
        this.playlists = Array.isArray(data.playlists) ? data.playlists : [];
      }
    } catch (_) {
      this.notice = '暂时无法读取本机收藏';
      this.storage = undefined;
      Log.warning('Library', 'Unable to load listener library');
    }
  }

  record(songId: number): void {
    if (this.recent[0] === songId) {
      return;
    }
    this.recent = [songId, ...this.recent.filter((id: number) => id !== songId)].slice(0, RECENT_LIMIT);
    this.save();
  }

  addPlaylist(name: string): PersonalPlaylist {
    const id = Math.max(Date.now(), (this.playlists[0]?.id ?? 0) + 1);
    const playlist: PersonalPlaylist = { id: id, name: name, songIds: [] };
    this.playlists = [playlist, ...this.playlists];
    this.save();
    return playlist;
  }

  deletePlaylist(id: number): void {
    this.playlists = this.playlists.filter((entry: PersonalPlaylist) => entry.id !== id);
    this.save();
  }

  playlist(path: LibraryPath): PersonalPlaylist | undefined {
    return this.playlists.find((entry: PersonalPlaylist) => entry.id === path.playlistId);
  }

  songIds(path: LibraryPath): number[] {
    if (path.section === 'recent') {
      return this.recent;
    }
    return path.section === 'favorites' ? this.favorites : this.playlist(path)?.songIds ?? [];
  }

  isFavorite(songId: number): boolean {
    return this.favorites.includes(songId);
  }

  toggleFavorite(songId: number): void {
    this.favorites = this.toggledIds(this.favorites, songId);
    this.save();
  }

  toggleSong(path: LibraryPath, songId: number): void {
    if (path.section === 'favorites') {
      this.toggleFavorite(songId);
    } else if (path.section === 'playlist') {
      const playlist = this.playlist(path);
      if (playlist) {
        const songIds = this.toggledIds(playlist.songIds, songId);
        this.playlists = this.playlists.map((entry: PersonalPlaylist): PersonalPlaylist =>
          entry.id === playlist.id ? { id: entry.id, name: entry.name, songIds: songIds } : entry);
        this.save();
      }
    }
  }

  private toggledIds(ids: number[], songId: number): number[] {
    return ids.includes(songId) ? ids.filter((id: number) => id !== songId) : [...ids, songId];
  }

  private save(): void {
    const storage = this.storage;
    if (!storage) {
      this.notice = '当前变更只保存在本次会话';
      return;
    }
    const data: LibraryData = { recent: this.recent, favorites: this.favorites, playlists: this.playlists };
    try {
      storage.putSync(DATA_KEY, JSON.stringify(data));
    } catch (_) {
      this.notice = '保存到本机失败';
      Log.warning('Library', 'Unable to update listener library');
      return;
    }
    this.pendingWrite = this.pendingWrite.then(async () => {
      await storage.flush();
      this.notice = '';
    }).catch(() => {
      this.notice = '保存到本机失败';
      Log.warning('Library', 'Unable to save listener library');
    });
  }
}
