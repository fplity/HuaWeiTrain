import { AppContext, PlayerStore, Song, SongFavorites } from '@cloudmusic/commons';
import { OfflineMusic } from '../service/OfflineMusic';
import { LibraryPath, ListenerLibrary } from '../viewmodel/ListenerLibrary';
import { PlaylistPath } from '../model/PlaylistDetails';
import { AccountPage } from './AccountPage';
import { AlbumsPage } from './AlbumsPage';
import { HomePage } from './HomePage';
import { LibraryPage } from './LibraryPage';
import { PlaylistDetail } from './PlaylistDetail';
import { SearchPage } from './SearchPage';
import { TrackSourcePage } from './TrackSourcePage';

const ACCOUNT_ROUTE: string = 'account';
const LIBRARY_ROUTE: string = 'library';
const ALBUMS_ROUTE: string = 'albums';
const SEARCH_ROUTE: string = 'search';
const PLAYLIST_ROUTE: string = 'playlist';
const PLAYER_ROUTE: string = 'player';
const TRACK_SOURCE_ROUTE: string = 'trackSource';

@ComponentV2
export struct ListenerNavigation {
  @Require @Param player: PlayerStore;
  @BuilderParam playerPage: (favorites: SongFavorites) => void;
  @Require @Param onPlaySongs: (songs: Song[]) => Promise<void>;
  @Require @Param onStop: () => void;
  @Require @Param onToggle: () => void;
  @Local library: ListenerLibrary = new ListenerLibrary();
  private readonly routes: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    const context = this.getUIContext().getHostContext();
    const session = AppContext.session.current;
    if (context) {
      OfflineMusic.load(context.resourceManager);
      if (session) {
        this.library.load(context, session);
      }
    }
  }

  aboutToDisappear(): void {
    this.onStop();
  }

  @Monitor('player.status', 'player.currentIndex', 'player.queue')
  onPlaybackChange(): void {
    const song = this.player.current;
    if (song && this.player.status === 'playing') {
      this.library.record(song.id);
    }
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
        onAlbums: () => { this.routes.pushPathByName(ALBUMS_ROUTE, undefined); },
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
      AccountPage({
        onBack: () => { this.routes.pop(); },
        onLocal: () => { this.openPlaylist(1); },
        onSong: (song: Song) => { this.openSong(song); },
        onAlbums: () => { this.routes.pushPathByName(ALBUMS_ROUTE, undefined); },
        onLibrary: (path: LibraryPath) => { this.routes.pushPathByName(LIBRARY_ROUTE, path); },
        onOpenPlayer: () => { this.routes.pushPathByName(PLAYER_ROUTE, undefined); },
        onToggle: this.onToggle,
        onStop: this.onStop,
        player: this.player,
        library: this.library
      })
    } else if (name === LIBRARY_ROUTE) {
      LibraryPage({
        path: params as LibraryPath,
        onBack: () => { this.routes.pop(); },
        onSong: (song: Song) => { this.openSong(song); },
        onOpenPlayer: () => { this.routes.pushPathByName(PLAYER_ROUTE, undefined); },
        onToggle: this.onToggle,
        onStop: this.onStop,
        player: this.player,
        library: this.library
      })
    } else if (name === TRACK_SOURCE_ROUTE) {
      TrackSourcePage({ song: params as Song })
    } else if (name === PLAYER_ROUTE) {
      this.playerPage(this.library)
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
