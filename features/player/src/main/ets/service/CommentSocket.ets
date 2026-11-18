import { webSocket } from '@kit.NetworkKit';
import { ApiConfig, AppContext, Log, Session, SongComment } from '@cloudmusic/commons';

interface SocketRequest {
  type: string;
  songId?: number;
}

interface SocketEvent {
  type: string;
  songId: number;
  comment?: SongComment;
}

export type CommentConnection = 'connecting' | 'connected' | 'reconnecting';

export class CommentSocket {
  private socket: webSocket.WebSocket | undefined;
  private retry: number = -1;
  private heartbeat: number = -1;
  private deadline: number = -1;
  private attempts: number = 0;
  private active: boolean = false;
  private disconnecting: Promise<void> = Promise.resolve();
  private generation: number = 0;

  private readonly songId: number;
  private readonly session: Session;
  private readonly onComment: (comment: SongComment) => void;
  private readonly onState: (state: CommentConnection) => void;

  constructor(songId: number, session: Session, onComment: (comment: SongComment) => void,
    onState: (state: CommentConnection) => void) {
    this.songId = songId;
    this.session = session;
    this.onComment = onComment;
    this.onState = onState;
  }

  start(): void {
    if (!this.active) {
      this.active = true;
      this.connect();
    }
  }

  stop(): Promise<void> {
    this.active = false;
    this.generation++;
    clearTimeout(this.retry);
    return this.close();
  }

  private connect(): void {
    if (!this.active || AppContext.session.current !== this.session) {
      return;
    }
    const revision = ++this.generation;
    const socket = webSocket.createWebSocket();
    this.socket = socket;
    const current = (): boolean => this.active && this.generation === revision && socket === this.socket;
    const retry = (): void => {
      if (!current()) {
        return;
      }
      const delay = Math.min(8000, 500 * Math.pow(2, Math.min(this.attempts++, 4)));
      this.onState('reconnecting');
      Log.warning('Comments', 'Realtime connection interrupted');
      this.close().finally(() => {
        if (this.active && this.generation === revision) {
          this.retry = setTimeout(() => { this.connect(); }, delay);
        }
      });
    };

    socket.on('open', (error) => {
      if (!current()) {
        return;
      }
      if (error) {
        retry();
        return;
      }
      const request: SocketRequest = { type: 'subscribe', songId: this.songId };
      socket.send(JSON.stringify(request)).catch(retry);
    });
    socket.on('message', (error, data) => {
      if (!current() || error || typeof data !== 'string') {
        return;
      }
      let event: SocketEvent;
      try {
        event = JSON.parse(data) as SocketEvent;
      } catch (_) {
        return;
      }
      if (event.songId !== this.songId) {
        return;
      }
      if (event.type === 'subscribed') {
        clearTimeout(this.deadline);
        clearInterval(this.heartbeat);
        this.attempts = 0;
        this.onState('connected');
        this.heartbeat = setInterval(() => {
          const ping: SocketRequest = { type: 'ping' };
          clearTimeout(this.deadline);
          this.deadline = setTimeout(retry, 4000);
          socket.send(JSON.stringify(ping)).catch(retry);
        }, 7000);
      } else if (event.type === 'pong') {
        clearTimeout(this.deadline);
      } else if (event.type === 'comment' && event.comment?.songId === this.songId) {
        this.onComment(event.comment);
      }
    });
    socket.on('close', (error, result) => {
      if (current() && !error && result?.code === 1008) {
        AppContext.expire(this.session).catch(() => {});
      }
      retry();
    });
    socket.on('error', retry);
    this.deadline = setTimeout(retry, 7000);
    socket.connect(ApiConfig.socketUrl, {
      header: { 'Authorization': 'Bearer ' + this.session.token },
      caPath: ApiConfig.caPath
    }).catch(retry);
  }

  private close(): Promise<void> {
    const socket = this.socket;
    this.socket = undefined;
    clearTimeout(this.deadline);
    clearInterval(this.heartbeat);
    if (socket) {
      socket.off('open');
      socket.off('message');
      socket.off('close');
      socket.off('error');
      this.disconnecting = new Promise<void>((resolve) => {
        const timeout = setTimeout(() => { resolve(); }, 1000);
        const finish = (): void => { clearTimeout(timeout); resolve(); };
        socket.close().then(finish, finish);
      });
    }
    return this.disconnecting;
  }
}