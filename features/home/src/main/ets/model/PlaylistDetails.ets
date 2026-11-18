import { Playlist, Song } from '@cloudmusic/commons';

export interface PlaylistDetails extends Playlist {
  description?: string;
  songs: Song[];
}

export interface PlaylistPath {
  playlistId: number;
}
