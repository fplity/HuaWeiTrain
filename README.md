# 回声音乐实训工程

手机和平板使用同一套 ArkUI 页面与 AVPlayer 状态管理。当前曲库随 HAP 分发。Java 服务提供 HTTPS 登录、首页、搜索、歌单详情与 WSS 歌曲评论。在线和离线模式共用曲库与歌单数据。

## 在本机运行

1. 安装 JDK 17 或以上及 Maven 3.6.3 或以上。将 JDK 的 bin 加入 PATH，或配置 JAVA_HOME。
2. 在 PowerShell 从工程根目录执行 `./backend/Start-Local.ps1`。首次启动生成本机 TLS 证书，启动脚本会为新密钥库生成由当前 Windows 用户加密保存的口令，并交互读取两个实训账号的密码。听众账号是 `listener`，运营账号是 `operator`。生产服务应使用自己的账号体系和可信证书。
3. 保持 Java 服务运行，在 DevEco Studio 从无中文字符的路径打开工程，执行 Sync，并重新构建手机和平板 HAP。脚本生成的公开证书应在构建前存在于两个产品的 rawfile 目录。首次只生成证书时可用 `./backend/Start-Local.ps1 -PrepareOnly`。
4. 对每一台已连接的测试设备分别执行 `hdc -t <设备标识> rport tcp:8443 tcp:8443`，然后安装该设备对应的 HAP。设备通过自己的回环地址访问本机 Java 服务。真实设备安装请使用为该设备配置签名的 HAP。
5. 在线验证使用上述两个账号。应用也提供听众和运营的离线演示。实时评论需要在线听众会话。数据库未作为本地实训的启动依赖，令牌和最近 100 条每歌曲评论保存在内存中，重启服务后重新登录。

## 本地曲库资源

公开仓库提供客户端、后端和歌单配置。项目本机使用的原曲、LRC、原版专辑图片由使用者自行提供。根据曲库清单 `features/home/src/main/resources/rawfile/catalog-seed.json` 的文件名放入对应目录，再重新构建 HAP：

- MP3 与 LRC 放在 `features/player/src/main/resources/rawfile/`。
- 专辑封面放在 `features/home/src/main/resources/rawfile/`。

缺少这些资源时可以编译工程、启动 Java 服务和浏览曲目元数据。原曲播放和对应歌词需要上述文件。

## 连接和测试

`backend/Verify-Local.py` 使用 Python 的 websocket-client 包，运行前在当前进程配置 `ECHO_LISTENER_PASSWORD` 和 `ECHO_OPERATOR_PASSWORD`。脚本读取本机证书做 TLS 校验，验证角色、401、重复请求、搜索分页、播放顺序、心跳、歌曲隔离、推送延迟和重新订阅。支持在两个独立设备上用同一听众账号分别登录，测试跨设备消息。

- `POST /auth/login` 与 `POST /auth/logout`
- `GET /home/feed`、`GET /search` 与 `GET /playlist/{id}`
- `GET /song/{id}/comments` 和 `POST /song/{id}/comments`
- `WSS /ws`，使用 Authorization 请求头，连接后发送 `subscribe` 与 `songId`，心跳事件为 `ping` 与 `pong`。

升级至指导书所需的 DevEco Studio 6.0.2 和 API 22 时，使用华为匹配的 SDK 重新编译，并核对编译、目标和兼容 SDK 配置。使用 Project Structure 的 Signing Configs 完成正式签名后再生成 APP 整包。