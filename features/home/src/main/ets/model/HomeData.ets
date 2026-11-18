import { Playlist, Song } from '@cloudmusic/commons';

export interface BannerItem {
  id: number;
  imageUrl: string;
  targetId: number;
  title?: string;
}

export interface HomeData {
  banners: BannerItem[];
  daily: Song[];
  playlists: Playlist[];
}
