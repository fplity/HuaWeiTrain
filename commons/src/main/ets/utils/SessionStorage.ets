import { asset } from '@kit.AssetStoreKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { Session, isValidUser } from '../model/User';

export class SessionStorage {
  private static readonly alias: Uint8Array = new util.TextEncoder().encodeInto('cloudmusic.auth.session.v1');
  private static pending: Promise<void> = Promise.resolve();

  static async read(): Promise<Session | undefined> {
    const query: asset.AssetMap = new Map();
    query.set(asset.Tag.ALIAS, SessionStorage.alias);
    query.set(asset.Tag.RETURN_TYPE, asset.ReturnType.ALL);

    let records: asset.AssetMap[];
    try {
      records = await asset.query(query);
    } catch (error) {
      if ((error as BusinessError).code === asset.ErrorCode.NOT_FOUND) {
        return undefined;
      }
      throw new Error('无法读取本机登录状态，请重新登录。');
    }

    const bytes = records[0]?.get(asset.Tag.SECRET);
    if (!(bytes instanceof Uint8Array)) {
      return undefined;
    }
    try {
      const session = JSON.parse(util.TextDecoder.create('utf-8').decodeToString(bytes)) as Session;
      if (session && isValidUser(session.user) && typeof session.offline === 'boolean' &&
        typeof session.token === 'string' && (session.offline ? session.token === '' : session.token.trim().length > 0)) {
        return session;
      }
    } catch (_) {
      // Malformed records are removed below.
    }
    await SessionStorage.write();
    return undefined;
  }

  static write(session?: Session): Promise<void> {
    const operation = SessionStorage.pending.then(async () => {
      const attributes: asset.AssetMap = new Map();
      attributes.set(asset.Tag.ALIAS, SessionStorage.alias);
      if (session) {
        const secret = new util.TextEncoder().encodeInto(JSON.stringify(session));
        if (secret.length > 1024) {
          throw new Error('登录数据超过安全存储容量，请联系接口提供方。');
        }
        attributes.set(asset.Tag.SECRET, secret);
        attributes.set(asset.Tag.CONFLICT_RESOLUTION, asset.ConflictResolution.OVERWRITE);
        try {
          await asset.add(attributes);
        } catch (_) {
          throw new Error('无法保存登录状态，请重试。');
        }
      } else {
        try {
          await asset.remove(attributes);
        } catch (error) {
          if ((error as BusinessError).code !== asset.ErrorCode.NOT_FOUND) {
            throw new Error('无法清除本机登录状态，请重试。');
          }
        }
      }
    });
    SessionStorage.pending = operation.catch(() => {});
    return operation;
  }
}
