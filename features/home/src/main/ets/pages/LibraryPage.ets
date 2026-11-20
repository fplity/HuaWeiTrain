import { MiniPlayer, MusicPageHeader, PlayerStore, Song } from '@cloudmusic/commons';
import { OfflineMusic } from '../service/OfflineMusic';
import { CatalogListCell } from '../view/CatalogListCell';
import { HomeTheme } from '../view/HomeTheme';
import { LibraryPath, ListenerLibrary } from '../viewmodel/ListenerLibrary';

@ComponentV2
export struct LibraryPage {
  @Require @Param path: LibraryPath;
  @Require @Param library: ListenerLibrary;
  @Require @Param player: PlayerStore;
  @Require @Param onBack: () => void;
  @Require @Param onSong: (song: Song) => void;
  @Require @Param onStop: () => void;
  @Require @Param onOpenPlayer: () => void;
  @Require @Param onToggle: () => void;
  @Local editing: boolean = false;

  private get songs(): Song[] {
    return OfflineMusic.resolveSongs(this.library.songIds(this.path));
  }

  private get title(): string {
    if (this.path.section === 'recent') {
      return '最近播放';
    }
    return this.path.section === 'favorites' ? '我喜欢的音乐' : this.library.playlist(this.path)?.name ?? '我的歌单';
  }

  private confirmDelete(): void {
    const playlist = this.library.playlist(this.path);
    if (!playlist) {
      return;
    }
    this.getUIContext().showAlertDialog({
      title: '删除歌单？',
      message: '将从你的收藏中移除「' + playlist.name + '」。',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: {
        value: '删除',
        action: () => {
          this.library.deletePlaylist(playlist.id);
          this.onBack();
        }
      }
    });
  }

  @Builder
  track(song: Song) {
    Row({ space: 8 }) {
      Column() {
        CatalogListCell({
          title: song.title,
          subtitle: song.artist,
          coverUrl: song.coverUrl ?? '',
          artworkId: song.id,
          active: song.id === this.player.current?.id,
          isSong: true
        })
      }
      .layoutWeight(1)
      .focusable(true)
      .onClick(() => { this.onSong(song); })
      if (this.editing) {
        Button(this.library.songIds(this.path).includes(song.id) ? '移除' : '添加')
          .width(58)
          .height(42)
          .fontSize(12)
          .backgroundColor(HomeTheme.accentSurface)
          .fontColor(HomeTheme.accent)
          .accessibilityText((this.library.songIds(this.path).includes(song.id) ? '移除' : '添加') + song.title)
          .onClick(() => { this.library.toggleSong(this.path, song.id); })
      }
    }
    .width('100%')
  }

  build() {
    NavDestination() {
      Column() {
        MusicPageHeader({ title: this.title, onBack: this.onBack, maxWidth: 840 })
        Column({ space: 10 }) {
          Row({ space: 8 }) {
            Text(this.editing ? '从本地曲库选歌' : this.songs.length.toString() + ' 首歌曲')
              .fontSize(14)
              .fontColor(HomeTheme.textSecondary)
            Blank()
            if (this.path.section === 'playlist' && !this.editing) {
              Button('删除')
                .height(40)
                .fontSize(13)
                .backgroundColor(HomeTheme.surfaceAlt)
                .fontColor(HomeTheme.textSecondary)
                .onClick(() => { this.confirmDelete(); })
            }
            if (this.path.section !== 'recent') {
              Button(this.editing ? '完成' : '添加歌曲')
                .height(40)
                .fontSize(13)
                .backgroundColor(HomeTheme.accent)
                .fontColor(HomeTheme.onAccent)
                .onClick(() => { this.editing = !this.editing; })
            }
          }
          .width('100%')
          if (this.library.notice) {
            Text(this.library.notice).fontSize(12).fontColor(HomeTheme.error)
          }
          if (!this.editing && this.songs.length === 0) {
            Text(this.path.section === 'recent' ? '播放过的歌曲会显示在这里' : '添加喜欢的歌曲，随时回来听')
              .fontSize(14)
              .fontColor(HomeTheme.textSecondary)
              .padding({ top: 20, bottom: 12 })
          }
          List() {
            ForEach(this.editing ? OfflineMusic.songs : this.songs, (song: Song) => {
              ListItem() {
                this.track(song)
              }
            }, (song: Song) => song.id.toString())
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Off)
          MiniPlayer({ player: this.player, onStop: this.onStop, onOpen: this.onOpenPlayer, onToggle: this.onToggle })
        }
        .width('100%')
        .constraintSize({ maxWidth: 840 })
        .layoutWeight(1)
        .padding({ left: 20, right: 20, bottom: 10 })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(HomeTheme.background)
    }
    .hideTitleBar(true)
  }
}
