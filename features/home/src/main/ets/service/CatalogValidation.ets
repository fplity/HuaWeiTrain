import { Playlist, Song } from '@cloudmusic/commons';

export function isPositiveId(id: number): boolean {
  return Number.isSafeInteger(id) && id > 0;
}

export function isSongSummary(song: Song): boolean {
  return !!song && isPositiveId(song.id) && typeof song.title === 'string' &&
    typeof song.artist === 'string' && (song.coverUrl === undefined || typeof song.coverUrl === 'string') &&
    (song.playUrl === undefined || typeof song.playUrl === 'string');
}

export function isPlaylistSummary(playlist: Playlist): boolean {
  return !!playlist && isPositiveId(playlist.id) && typeof playlist.name === 'string' &&
    Number.isFinite(playlist.playCount) && playlist.playCount >= 0 &&
    (playlist.coverUrl === undefined || typeof playlist.coverUrl === 'string');
}
