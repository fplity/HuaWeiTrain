package cn.echo;

import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
class Api {
    record Response<T>(int code, String msg, T data) {}
    record Credentials(String account, String password) {}
    record Draft(String text) {}

    private final Sessions sessions;
    private final Catalog catalog;
    private final Comments comments;

    Api(Sessions sessions, Catalog catalog, Comments comments) {
        this.sessions = sessions;
        this.catalog = catalog;
        this.comments = comments;
    }

    @GetMapping("/health")
    ResponseEntity<Response<?>> health() {
        return ok("ready");
    }

    @PostMapping("/auth/login")
    ResponseEntity<Response<?>> login(@RequestBody Credentials credentials) {
        Sessions.Login result = sessions.login(credentials.account(), credentials.password());
        return result == null ? fail(401, "账号或密码有误。") : ok(result);
    }

    @PostMapping("/auth/logout")
    ResponseEntity<Response<?>> logout(@RequestHeader(value = HttpHeaders.AUTHORIZATION, required = false) String auth) {
        sessions.revoke(auth);
        return ok(true);
    }

    @GetMapping("/home/feed")
    ResponseEntity<Response<?>> feed(@RequestHeader(value = HttpHeaders.AUTHORIZATION, required = false) String auth) {
        return sessions.user(auth) == null ? expired() : ok(catalog.feed());
    }

    @GetMapping("/search")
    ResponseEntity<Response<?>> search(
            @RequestHeader(value = HttpHeaders.AUTHORIZATION, required = false) String auth,
            @RequestParam(defaultValue = "") String keyword, @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize) {
        if (sessions.user(auth) == null) {
            return expired();
        }
        if (page < 1 || pageSize < 1 || pageSize > 50 || keyword.length() > 128) {
            return fail(400, "搜索参数有误。");
        }
        return ok(catalog.search(keyword, page, pageSize));
    }

    @GetMapping("/playlist/{id}")
    ResponseEntity<Response<?>> playlist(
            @RequestHeader(value = HttpHeaders.AUTHORIZATION, required = false) String auth, @PathVariable int id) {
        if (sessions.user(auth) == null) {
            return expired();
        }
        Catalog.Detail detail = catalog.playlist(id);
        return detail == null ? fail(404, "找不到歌单。") : ok(detail);
    }

    @GetMapping("/song/{id}/comments")
    ResponseEntity<Response<?>> listComments(
            @RequestHeader(value = HttpHeaders.AUTHORIZATION, required = false) String auth, @PathVariable int id) {
        Sessions.User user = sessions.user(auth);
        if (user == null) {
            return expired();
        }
        if (!user.role().equals("listener")) {
            return fail(403, "请使用听众账号。");
        }
        return catalog.hasSong(id) ? ok(comments.history(id)) : fail(404, "找不到歌曲。");
    }

    @PostMapping("/song/{id}/comments")
    ResponseEntity<Response<?>> postComment(
            @RequestHeader(value = HttpHeaders.AUTHORIZATION, required = false) String auth, @PathVariable int id,
            @RequestBody Draft draft) {
        Sessions.User user = sessions.user(auth);
        if (user == null) {
            return expired();
        }
        if (!user.role().equals("listener")) {
            return fail(403, "请使用听众账号。");
        }
        if (!catalog.hasSong(id)) {
            return fail(404, "找不到歌曲。");
        }
        String text = draft.text() == null ? "" : draft.text().strip();
        if (text.isEmpty() || text.codePointCount(0, text.length()) > 200) {
            return fail(400, "请输入 1 到 200 字的评论。");
        }
        return ok(comments.publish(id, user, text));
    }

    private static ResponseEntity<Response<?>> ok(Object data) {
        return ResponseEntity.ok(new Response<>(0, "", data));
    }

    private static ResponseEntity<Response<?>> expired() {
        return fail(401, "登录已过期，请重新登录。");
    }

    private static ResponseEntity<Response<?>> fail(int status, String message) {
        return ResponseEntity.status(status).body(new Response<>(status, message, null));
    }
}