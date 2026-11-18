import { AppContext } from '@cloudmusic/commons';
import { HomeData } from '../model/HomeData';
import { HomeService } from '../service/HomeService';
import { PlaylistDataSource } from './PlaylistDataSource';
import { SongDataSource } from './SongDataSource';

@ObservedV2
export class HomeFeedState {
  @Trace data: HomeData | undefined = undefined;
  @Trace loading: boolean = false;
  @Trace refreshing: boolean = false;
  @Trace error: string = '';

  readonly songs: SongDataSource = new SongDataSource();
  readonly playlists: PlaylistDataSource = new PlaylistDataSource();

  async load(fromPull: boolean = false): Promise<void> {
    const session = AppContext.session.current;
    if (!session || session.user.role !== 'listener') {
      return;
    }
    if (this.loading) {
      // A pull during the initial load shares that load's completion.
      this.refreshing = this.refreshing || fromPull;
      return;
    }
    this.loading = true;
    this.refreshing = fromPull;
    this.error = '';
    try {
      const data = await HomeService.load(session.offline);
      if (AppContext.session.current === session) {
        this.songs.reset(data.daily);
        this.playlists.reset(data.playlists);
        this.data = data;
      }
    } catch (error) {
      if (AppContext.session.current === session) {
        this.error = (error as Error).message || '暂时无法加载推荐。';
      }
    } finally {
      this.loading = false;
      this.refreshing = false;
    }
  }
}
