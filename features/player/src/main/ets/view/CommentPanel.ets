import { AppContext, MusicTheme, SongComment } from '@cloudmusic/commons';
import { CommentService } from '../service/CommentService';
import { CommentConnection, CommentSocket } from '../service/CommentSocket';

@ComponentV2
export struct CommentPanel {
  @Require @Param songId: number;
  @Local comments: SongComment[] = [];
  @Local draft: string = '';
  @Local sending: boolean = false;
  @Local status: CommentConnection = 'connecting';
  @Local error: string = '';
  private socket: CommentSocket | undefined;
  private revision: number = 0;
  private shutdown: Promise<void> = Promise.resolve();

  aboutToAppear(): void {
    this.subscribe();
  }

  aboutToDisappear(): void {
    this.revision++;
    this.close();
  }

  @Monitor('songId')
  songChanged(): void {
    this.subscribe();
  }

  private close(): Promise<void> {
    if (this.socket) {
      this.shutdown = this.socket.stop();
      this.socket = undefined;
    }
    return this.shutdown;
  }

  private async subscribe(): Promise<void> {
    const revision = ++this.revision;
    this.comments = [];
    this.draft = '';
    this.sending = false;
    this.error = '';
    this.status = 'connecting';
    await this.close();
    const session = AppContext.session.current;
    if (revision !== this.revision || !session || session.offline || session.user.role !== 'listener') {
      return;
    }
    const songId = this.songId;
    this.socket = new CommentSocket(songId, session, (comment: SongComment) => {
      if (revision === this.revision) {
        this.merge([comment]);
      }
    }, (state: CommentConnection) => {
      if (revision === this.revision) {
        this.status = state;
        if (state === 'connected') {
          this.load(songId, revision);
        }
      }
    });
    this.socket.start();
    await this.load(songId, revision);
  }

  private async load(songId: number, revision: number): Promise<void> {
    try {
      const history = await CommentService.list(songId);
      if (revision === this.revision) {
        this.merge(history);
        this.error = '';
      }
    } catch (error) {
      if (revision === this.revision) {
        this.error = (error as Error).message;
      }
    }
  }

  private merge(items: SongComment[]): void {
    const byId = new Map<number, SongComment>();
    this.comments.concat(items).forEach((item: SongComment) => {
      if (item.songId === this.songId) {
        byId.set(item.id, item);
      }
    });
    this.comments = Array.from(byId.values()).sort((a: SongComment, b: SongComment) => b.id - a.id).slice(0, 100);
  }

  private async send(): Promise<void> {
    const draft = this.draft.trim();
    if (!draft || this.sending) {
      return;
    }
    const revision = this.revision;
    this.error = '';
    this.sending = true;
    try {
      const comment = await CommentService.post(this.songId, draft);
      if (revision === this.revision) {
        this.merge([comment]);
        this.draft = '';
      }
    } catch (error) {
      if (revision === this.revision) {
        this.error = (error as Error).message;
      }
    } finally {
      if (revision === this.revision) {
        this.sending = false;
      }
    }
  }

  build() {
    Column({ space: 8 }) {
      Row() {
        Text('歌曲评论').fontColor(MusicTheme.playerText).fontWeight(FontWeight.Bold).fontSize(14)
        Blank()
        Text(this.status === 'connected' ? '实时' : this.status === 'connecting' ? '连接中' : '重连中')
          .id('comments-status')
          .fontColor(MusicTheme.playerMuted)
          .fontSize(11)
      }
      .width('100%')
      if (this.comments.length === 0) {
        Text(this.status === 'connected' ? '还没有评论' : '正在连接评论服务')
          .fontColor(MusicTheme.playerMuted)
          .fontSize(13)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .align(Alignment.Center)
      } else {
        List({ space: 8 }) {
          ForEach(this.comments, (comment: SongComment) => {
            ListItem() {
              Column({ space: 4 }) {
                Text(comment.nickname).fontColor(MusicTheme.playerAccent).fontSize(11)
                Text(comment.text).fontColor(MusicTheme.playerText).fontSize(13)
              }
              .alignItems(HorizontalAlign.Start)
              .width('100%')
            }
          }, (comment: SongComment) => comment.id.toString())
        }
        .layoutWeight(1)
        .width('100%')
        .nestedScroll({ scrollForward: NestedScrollMode.SELF_FIRST, scrollBackward: NestedScrollMode.SELF_FIRST })
      }
      if (this.error) {
        Text(this.error).fontColor('#FFC1BD').fontSize(12).maxLines(2)
      }
      Row({ space: 6 }) {
        TextInput({ text: this.draft, placeholder: '写评论' })
          .id('comment-input')
          .maxLength(200)
          .layoutWeight(1)
          .height(38)
          .backgroundColor('#FFF5F1')
          .onChange((value: string) => { this.draft = value; })
          .onSubmit(() => { this.send(); })
          .enabled(!this.sending)
        Button('发送')
          .id('comment-submit')
          .height(38)
          .padding({ left: 12, right: 12 })
          .backgroundColor(MusicTheme.playerAccent)
          .fontColor(MusicTheme.ink)
          .enabled(!this.sending && !!this.draft.trim())
          .onClick(() => { this.send(); })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding(12)
    .backgroundColor('#24FFFFFF')
    .borderRadius(16)
  }
}