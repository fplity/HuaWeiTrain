import { HttpService, SongComment } from '@cloudmusic/commons';

interface CommentDraft {
  text: string;
}

export class CommentService {
  static list(songId: number): Promise<SongComment[]> {
    return HttpService.get<SongComment[]>(CommentService.path(songId));
  }

  static post(songId: number, text: string): Promise<SongComment> {
    const draft: CommentDraft = { text: text };
    return HttpService.post<SongComment>(CommentService.path(songId), draft);
  }

  private static path(songId: number): string {
    return '/song/' + songId.toString() + '/comments';
  }
}