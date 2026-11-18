import { PlayerStore, Song } from '@cloudmusic/commons';
import { OfflineMusic } from '../service/OfflineMusic';
import { PlaylistPath } from '../model/PlaylistDetails';
import { AccountPage } from './AccountPage';
import { AlbumsPage } from './AlbumsPage';
import { HomePage } from './HomePage';
import { PlaylistDetail } from './PlaylistDetail';
import { SearchPage } from './SearchPage';
import { TrackSourcePage } from './TrackSourcePage';

const ACCOUNT_ROUTE: string = 'account';
const ALBUMS_ROUTE: string = 'albums';
const SEARCH_ROUTE: string = 'search';
const PLAYLIST_ROUTE: string = 'playlist';
const PLAYER_ROUTE: string = 'player';
const TRACK_SOURCE_ROUTE: string = 'trackSource';

@ComponentV2
export struct ListenerNavigation {
  @Require @Param player: PlayerStore;
  @BuilderParam playerPage: () => void;
  @Require @Param onPlaySongs: (songs: Song[]) => Promise<void>;
  @Require @Param onStop: () => void;
  @Require @Param onToggle: () => void;
  private readonly routes: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    const manager = this.getUIContext().getHostContext()?.resourceManager;
    if (manager) {
      OfflineMusic.load(manager);
    }
  }

  aboutToDisappear(): void {
    this.onStop();
  }

  private openPlaylist(id: number): void {
    const params: PlaylistPath = { playlistId: id };
    this.routes.pushPathByName(PLAYLIST_ROUTE, params);
  }

  private openSong(song: Song): void {
    if (!song.playUrl && song.sourcePageUrl) {
      this.routes.pushPathByName(TRACK_SOURCE_ROUTE, song);
      return;
    }
    this.onPlaySongs([song]).catch(() => {});
  }

  @Builder
  destination(name: string, params: Object) {
    if (name === SEARCH_ROUTE) {
      SearchPage({
        onBack: () => { this.routes.pop(); },
        onPlaylist: (id: number) => { this.openPlaylist(id); },
        onOpenPlayer: () => { this.routes.pushPathByName(PLAYER_ROUTE, undefined); },
        onToggle: this.onToggle,
        onSong: (song: Song) => { this.openSong(song); },
        onStop: this.onStop,
        player: this.player
      })
    } else if (name === ALBUMS_ROUTE) {
      AlbumsPage({
        onBack: () => { this.routes.pop(); },
        onAlbum: (id: number) => { this.openPlaylist(id); },
        onOpenPlayer: () => { this.routes.pushPathByName(PLAYER_ROUTE, undefined); },
        onToggle: this.onToggle,
        onStop: this.onStop,
        player: this.player
      })
    } else if (name === PLAYLIST_ROUTE) {
      PlaylistDetail({
        onBack: () => { this.routes.pop(); },
        onSong: (song: Song) => { this.openSong(song); },
        onOpenPlayer: () => { this.routes.pushPathByName(PLAYER_ROUTE, undefined); },
        onToggle: this.onToggle,
        onPlaySongs: this.onPlaySongs,
        onStop: this.onStop,
        player: this.player
      })
    } else if (name === ACCOUNT_ROUTE) {
      AccountPage({ onBack: () => { this.routes.pop(); } })
    } else if (name === TRACK_SOURCE_ROUTE) {
      TrackSourcePage({ song: params as Song })
    } else if (name === PLAYER_ROUTE) {
      this.playerPage()
    }
  }

  build() {
    Navigation(this.routes) {
      HomePage({
        player: this.player,
        onOpenPlayer: () => { this.routes.pushPathByName(PLAYER_ROUTE, undefined); },
        onToggle: this.onToggle,
        onStop: this.onStop,
        onSearch: () => { this.routes.pushPathByName(SEARCH_ROUTE, undefined); },
        onAccount: () => { this.routes.pushPathByName(ACCOUNT_ROUTE, undefined); },
        onAlbums: () => { this.routes.pushPathByName(ALBUMS_ROUTE, undefined); },
        onSong: (song: Song) => { this.openSong(song); },
        onPlaylist: (id: number) => { this.openPlaylist(id); }
      })
    }
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .navDestination(this.destination)
    .width('100%')
    .height('100%')
  }
}
