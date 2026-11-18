import { Song } from '@cloudmusic/commons';
import { SongDataSource } from '../viewmodel/SongDataSource';
import { HomeTheme } from './HomeTheme';
import { SongListCell } from './SongListCell';

@ComponentV2
export struct DailyRow {
  @Require @Param songs: SongDataSource;
  @Require @Param onSong: (song: Song) => void;

  build() {
    List({ space: HomeTheme.md }) {
      LazyForEach(this.songs, (song: Song) => {
        ListItem() {
          SongListCell({ song: song })
        }
        .focusable(true)
        .onClick(() => { this.onSong(song); })
      }, (song: Song) => song.id.toString() + '|' + song.title + '|' + song.artist + '|' + (song.coverUrl ?? ''))
    }
    .listDirection(Axis.Horizontal)
    .scrollBar(BarState.Off)
    .cachedCount(2)
    .width('100%')
    .height(151)
    .alignListItem(ListItemAlign.Start)
  }
}
