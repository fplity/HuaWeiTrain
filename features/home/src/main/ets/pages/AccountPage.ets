import { AppContext, MiniPlayer, MusicIcon, MusicPageHeader, PlayerStore, SessionStore, Song,
  SignOutButton } from '@cloudmusic/commons';
import { OfflineMusic } from '../service/OfflineMusic';
import { CatalogListCell } from '../view/CatalogListCell';
import { FeedArtwork } from '../view/FeedArtwork';
import { HomeTheme } from '../view/HomeTheme';
import { LibraryPath, ListenerLibrary, PersonalPlaylist } from '../viewmodel/ListenerLibrary';

@ComponentV2
export struct AccountPage {
  @Require @Param onBack: () => void;
  @Require @Param onLocal: () => void;
  @Require @Param onAlbums: () => void;
  @Require @Param onLibrary: (path: LibraryPath) => void;
  @Require @Param onSong: (song: Song) => void;
  @Require @Param onStop: () => void;
  @Require @Param onOpenPlayer: () => void;
  @Require @Param onToggle: () => void;
  @Require @Param player: PlayerStore;
  @Require @Param library: ListenerLibrary;
  @Local session: SessionStore = AppContext.session;
  @Local creating: boolean = false;
  @Local draft: string = '';

  private createPlaylist(): void {
    const name = this.draft.trim();
    if (!name) {
      return;
    }
    const playlist = this.library.addPlaylist(name);
    this.creating = false;
    this.draft = '';
    this.onLibrary({ section: 'playlist', playlistId: playlist.id });
  }

  private shortcutCount(section: 'recent' | 'local' | 'albums'): string {
    if (section === 'recent') {
      return this.library.recent.length.toString() + ' 首';
    }
    return section === 'local' ? OfflineMusic.songs.length.toString() + ' 首' :
      OfflineMusic.albums.length.toString() + ' 张';
  }

  @Builder
  quickLink(title: string, section: 'recent' | 'local' | 'albums', icon: string, action: () => void) {
    Button({ type: ButtonType.Normal }) {
      Column({ space: 6 }) {
        MusicIcon({ name: icon, iconSize: 19, tint: HomeTheme.playerAccent })
        Text(title)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(HomeTheme.playerText)
          .maxLines(1)
        Text(this.shortcutCount(section))
          .fontSize(11)
          .fontColor('#E9CFD8')
          .maxLines(1)
      }
      .width('100%')
      .padding({ top: 11, bottom: 10 })
    }
    .height(80)
    .layoutWeight(1)
    .borderRadius(12)
    .backgroundColor('#3AFFFFFF')
    .accessibilityText(title + '，' + this.shortcutCount(section))
    .onClick(action)
  }

  @Builder
  profile() {
    Stack({ alignContent: Alignment.TopStart }) {
      FeedArtwork({ src: 'rawfile:echo-playlist-midnight.jpg', artworkId: 10, wide: true })
      Row()
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Right,
          colors: [['#FF32192D', 0], ['#F332192D', 0.47], ['#9532192D', 1]]
        })
      Column({ space: 17 }) {
        Row({ space: 13 }) {
          Stack({ alignContent: Alignment.Center }) {
            MusicIcon({ name: 'person', iconSize: 28, tint: '#FFE7ED' })
          }
          .width(55)
          .height(55)
          .backgroundColor('#8E3757')
          .border({ width: 1, color: '#A0FDC5D5' })
          .borderRadius(28)
          Column({ space: 4 }) {
            Text(this.session.current?.user.nickname || '听众')
              .fontSize(23)
              .fontWeight(FontWeight.Bold)
              .fontColor(HomeTheme.playerText)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.session.current?.offline ? '离线听众 · 本机资料' : '听众 · 本机资料')
              .fontSize(12)
              .fontColor('#F1CAD9')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')

        Row({ space: 8 }) {
          this.quickLink('最近播放', 'recent', 'play',
            () => { this.onLibrary({ section: 'recent' }); })
          this.quickLink('本地曲库', 'local', 'music', this.onLocal)
          this.quickLink('专辑', 'albums', 'albums', this.onAlbums)
        }
        .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding(15)
    }
    .width('100%')
    .height(184)
    .borderRadius(20)
    .clip(true)
  }

  @Builder
  libraryRow(title: string, subtitle: string, favorite: boolean, action: () => void) {
    Row({ space: 11 }) {
      Stack({ alignContent: Alignment.Center }) {
        if (favorite) {
          Text('♡').fontSize(26).fontColor(HomeTheme.accent)
        } else {
          MusicIcon({ name: 'music', iconSize: 19, tint: HomeTheme.accent })
        }
      }
      .width(42)
      .height(42)
      .backgroundColor(HomeTheme.accentSurface)
      .borderRadius(10)
      Column({ space: 4 }) {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(HomeTheme.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(favorite ? this.library.favorites.length.toString() + ' 首' : subtitle)
          .fontSize(12)
          .fontColor(HomeTheme.textSecondary)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      MusicIcon({ name: 'right', iconSize: 16, tint: HomeTheme.textSecondary })
    }
    .width('100%')
    .constraintSize({ minHeight: 58 })
    .padding({ left: 11, right: 11 })
    .accessibilityText(title + '，' + (favorite ? this.library.favorites.length.toString() + ' 首' : subtitle))
    .focusable(true)
    .onClick(action)
  }

  @Builder
  collection() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Text('我的收藏').fontSize(20).fontWeight(FontWeight.Bold).fontColor(HomeTheme.textPrimary)
        Blank()
        Button(this.creating ? '取消' : '+ 新建歌单')
          .height(38)
          .fontSize(13)
          .backgroundColor(HomeTheme.accentSurface)
          .fontColor(HomeTheme.accent)
          .onClick(() => {
            this.creating = !this.creating;
            this.draft = '';
          })
      }
      .width('100%')

      if (this.creating) {
        Row({ space: 8 }) {
          TextInput({ text: this.draft, placeholder: '输入歌单名称' })
            .id('personal-playlist-name')
            .height(42)
            .maxLength(30)
            .fontSize(14)
            .fontColor(HomeTheme.textPrimary)
            .backgroundColor(HomeTheme.surfaceAlt)
            .layoutWeight(1)
            .onChange((value: string) => { this.draft = value; })
            .onSubmit(() => { this.createPlaylist(); })
          Button('创建')
            .height(42)
            .backgroundColor(HomeTheme.accent)
            .fontColor(HomeTheme.onAccent)
            .enabled(!!this.draft.trim())
            .onClick(() => { this.createPlaylist(); })
        }
        .width('100%')
      }

      this.libraryRow('我喜欢的音乐', '', true,
        () => { this.onLibrary({ section: 'favorites' }); })
      ForEach(this.library.playlists, (playlist: PersonalPlaylist) => {
        Divider().color(HomeTheme.border)
        this.libraryRow(playlist.name, playlist.songIds.length.toString() + ' 首', false,
          () => { this.onLibrary({ section: 'playlist', playlistId: playlist.id }); })
      }, (playlist: PersonalPlaylist) => playlist.id.toString() + ':' + playlist.songIds.length.toString())

      if (this.library.notice) {
        Text(this.library.notice).fontSize(12).fontColor(HomeTheme.error)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(12)
    .backgroundColor(HomeTheme.surface)
    .border({ width: 1, color: HomeTheme.border })
    .borderRadius(17)
  }

  @Builder
  recentPreview() {
    Column({ space: 8 }) {
      Row() {
        Text('最近收听').fontSize(19).fontWeight(FontWeight.Bold).fontColor(HomeTheme.textPrimary)
        Blank()
        if (this.library.recent.length > 0) {
          Button('查看全部')
            .height(38)
            .fontSize(13)
            .backgroundColor(HomeTheme.accentSurface)
            .fontColor(HomeTheme.accent)
            .onClick(() => { this.onLibrary({ section: 'recent' }); })
        }
      }
      .width('100%')

      if (this.library.recent.length > 0) {
        ForEach(OfflineMusic.resolveSongs(this.library.recent.slice(0, 3)), (song: Song) => {
          Column() {
            CatalogListCell({
              title: song.title,
              subtitle: song.artist,
              coverUrl: song.coverUrl,
              artworkId: song.id,
              isSong: true,
              active: this.player.current?.id === song.id
            })
          }
          .width('100%')
          .focusable(true)
          .onClick(() => { this.onSong(song); })
        }, (song: Song) => song.id.toString())
      } else {
        Row({ space: 12 }) {
          Text('播放过的歌曲会出现在这里')
            .fontSize(13)
            .fontColor(HomeTheme.textSecondary)
            .layoutWeight(1)
          Button('去发现')
            .height(38)
            .fontSize(13)
            .backgroundColor(HomeTheme.accentSurface)
            .fontColor(HomeTheme.accent)
            .onClick(this.onBack)
        }
        .width('100%')
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(12)
    .backgroundColor(HomeTheme.surface)
    .border({ width: 1, color: HomeTheme.border })
    .borderRadius(17)
  }

  build() {
    NavDestination() {
      Column() {
        MusicPageHeader({ title: '我的', onBack: this.onBack, maxWidth: 840 })
        Scroll() {
          Column({ space: 16 }) {
            this.profile()
            this.collection()
            this.recentPreview()
            SignOutButton()
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 3, bottom: 16 })
        }
        .width('100%')
        .constraintSize({ maxWidth: 840 })
        .layoutWeight(1)
        .align(Alignment.Top)
        .scrollBar(BarState.Off)
        if (this.player.current) {
          Column() {
            MiniPlayer({ player: this.player, onStop: this.onStop, onOpen: this.onOpenPlayer, onToggle: this.onToggle })
          }
          .width('100%')
          .constraintSize({ maxWidth: 840 })
          .padding({ left: 14, right: 14, top: 7, bottom: 9 })
        }
      }
      .height('100%')
      .width('100%')
      .backgroundColor(HomeTheme.background)
    }
    .hideTitleBar(true)
  }
}
