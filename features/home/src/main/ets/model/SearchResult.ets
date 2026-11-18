import { Playlist, Song } from '@cloudmusic/commons';

export interface SearchResultPage {
  list: Song[];
  playlists?: Playlist[];
  hasMore: boolean;
}

export interface SearchResult {
  key: string;
  title: string;
  subtitle: string;
  coverUrl: string;
  artworkId: number;
  playlistId?: number;
  song?: Song;
}
