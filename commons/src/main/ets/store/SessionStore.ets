import { Session } from '../model/User';

@ObservedV2
export class SessionStore {
  @Trace current: Session | undefined = undefined;
  @Trace ready: boolean = false;
  @Trace notice: string = '';
}
