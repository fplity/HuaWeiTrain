import { Playlist, Song } from '@cloudmusic/commons';
import { BannerItem, HomeData } from '../model/HomeData';
import { PlaylistDetails } from '../model/PlaylistDetails';
import { SearchResultPage } from '../model/SearchResult';
import { OfflineFeed, OfflinePlaylist } from './OfflineFeed';
import { OfflineMusic } from './OfflineMusic';

export class OfflineCatalog {
  static home(): HomeData {
    const playlists = OfflineFeed.playlists.slice();
    return {
      banners: playlists.slice(0, 3).map((playlist: Playlist): BannerItem => ({
        id: playlist.id,
        imageUrl: playlist.coverUrl ?? '',
        targetId: playlist.id,
        title: playlist.name
      })),
      daily: OfflineMusic.songs,
      playlists: playlists
    };
  }

  static search(keyword: string, page: number, pageSize: number): SearchResultPage {
    const query = keyword.toLowerCase();
    const songs = OfflineMusic.songs.filter((song: Song) =>
      song.title.toLowerCase().includes(query) || song.artist.toLowerCase().includes(query));
    const shortcuts: Playlist[] = OfflineFeed.sunny ? [OfflineFeed.sunny] : [];
    const playlists = shortcuts.concat(OfflineMusic.albums, OfflineFeed.playlists)
      .filter((playlist: Playlist) => playlist.name.toLowerCase().includes(query));
    const start = (page - 1) * pageSize;
    const end = start + pageSize;
    return {
      list: songs.slice(Math.max(0, start - playlists.length), Math.max(0, end - playlists.length)),
      playlists: playlists.slice(start, end),
      hasMore: end < playlists.length + songs.length
    };
  }

  static playlist(id: number): PlaylistDetails | undefined {
    const album = OfflineMusic.albums.find((item: PlaylistDetails) => item.id === id);
    if (album) {
      return album;
    }
    const playlist = id === OfflineFeed.sunny?.id ? OfflineFeed.sunny :
      OfflineFeed.playlists.find((item: OfflinePlaylist) => item.id === id);
    if (!playlist) {
      return undefined;
    }

    const songs: Song[] = [];
    if (playlist.trackIds === undefined) {
      songs.push(...OfflineMusic.songs);
    } else {
      for (const trackId of playlist.trackIds) {
        const song = OfflineMusic.songs.find((item: Song) => item.id === trackId);
        if (song) {
          songs.push(song);
        }
      }
    }
    return {
      id: playlist.id,
      name: playlist.name,
      coverUrl: playlist.coverUrl,
      playCount: playlist.playCount,
      songs: songs
    };
  }
}
