export interface SongFavorites {
  isFavorite(songId: number): boolean;
  toggleFavorite(songId: number): void;
}

export interface Song {
  id: number;
  title: string;
  artist: string;
  album?: string;
  albumArtist?: string;
  albumId?: number;
  trackNumber?: number;
  discNumber?: number;
  coverUrl: string;
  playUrl: string;
  sourcePageUrl?: string;
  lyricsPageUrl?: string;
  lyricUrl?: string;
  duration: number; // Milliseconds.
}
