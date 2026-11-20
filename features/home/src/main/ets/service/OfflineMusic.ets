import { resourceManager } from '@kit.LocalizationKit';
import { util } from '@kit.ArkTS';
import { Log, Song } from '@cloudmusic/commons';
import { PlaylistDetails } from '../model/PlaylistDetails';
import { OfflineFeed } from './OfflineFeed';

interface CatalogSource {
  lyricsPageUrl?: string;
  playbackPageUrl?: string;
}

interface CatalogRecord extends Song {
  source?: CatalogSource;
}

export class OfflineMusic {
  static songs: Song[] = [];
  static albums: PlaylistDetails[] = [];
  private static ready: boolean = false;

  static resolveSongs(ids: number[]): Song[] {
    const songs: Song[] = [];
    for (const id of ids) {
      const song = OfflineMusic.songs.find((item: Song) => item.id === id);
      if (song) {
        songs.push(song);
      }
    }
    return songs;
  }

  static load(manager: resourceManager.ResourceManager): void {
    if (OfflineMusic.ready) {
      return;
    }
    try {
      OfflineFeed.load(manager);
      const bytes = manager.getRawFileContentSync('catalog-seed.json');
      const records = JSON.parse(util.TextDecoder.create('utf-8').decodeToString(bytes)) as CatalogRecord[];
      const songs = records.map((record: CatalogRecord): Song => ({
        id: record.id,
        title: record.title,
        artist: record.artist,
        album: record.album,
        albumArtist: record.albumArtist,
        albumId: record.albumId,
        trackNumber: record.trackNumber,
        discNumber: record.discNumber,
        coverUrl: record.coverUrl,
        playUrl: record.playUrl,
        duration: record.duration,
        lyricUrl: record.lyricUrl,
        sourcePageUrl: record.source?.playbackPageUrl ?? record.source?.lyricsPageUrl,
        lyricsPageUrl: record.source?.lyricsPageUrl
      }));
      const byId = new Map<number, PlaylistDetails>();
      songs.forEach((song: Song) => {
        if (song.albumId === undefined || !song.album) {
          return;
        }
        const album = byId.get(song.albumId);
        if (album) {
          album.songs.push(song);
        } else {
          byId.set(song.albumId, {
            id: song.albumId,
            name: song.album,
            coverUrl: song.coverUrl,
            playCount: 0,
            albumArtist: song.albumArtist ?? song.artist,
            songs: [song]
          });
        }
      });
      const albums = Array.from(byId.values());
      albums.forEach((album: PlaylistDetails) => {
        album.songs.sort((left: Song, right: Song) =>
          (left.discNumber ?? 1) - (right.discNumber ?? 1) ||
          (left.trackNumber ?? 0) - (right.trackNumber ?? 0));
      });
      OfflineMusic.songs = songs;
      OfflineMusic.albums = albums;
      OfflineMusic.ready = true;
    } catch (_) {
      Log.error('Catalog', 'Unable to load the bundled music catalog');
    }
  }
}
