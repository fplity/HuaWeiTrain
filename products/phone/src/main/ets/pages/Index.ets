import { SessionGate, Song } from '@cloudmusic/commons';
import { LoginPage } from '@cloudmusic/login';
import { ListenerNavigation, OperatorHome } from '@cloudmusic/home';
import { PlayerPage, PlayerService } from '@cloudmusic/player';

@Entry
@ComponentV2
struct Index {
  @Builder
  login() {
    LoginPage()
  }

  @Builder
  playerPage() {
    PlayerPage({
      player: PlayerService.store,
      onToggle: () => { PlayerService.togglePlayPause().catch(() => {}); },
      onStop: () => { PlayerService.clear(); },
      onPrevious: () => { PlayerService.skip(-1).catch(() => {}); },
      onNext: () => { PlayerService.skip(1).catch(() => {}); },
      onSeek: (position: number) => PlayerService.seekTo(position)
    })
  }

  @Builder
  listenerHome() {
    ListenerNavigation({
      player: PlayerService.store,
      playerPage: (): void => { this.playerPage() },
      onPlaySongs: (songs: Song[]) => PlayerService.playAll(songs),
      onToggle: () => { PlayerService.togglePlayPause().catch(() => {}); },
      onStop: () => { PlayerService.clear(); }
    })
  }

  @Builder
  operatorHome() {
    OperatorHome()
  }

  build() {
    Column() {
      SessionGate({
        login: (): void => { this.login() },
        listenerHome: (): void => { this.listenerHome() },
        operatorHome: (): void => { this.operatorHome() }
      })
    }
    .width('100%')
    .height('100%')
  }
}
