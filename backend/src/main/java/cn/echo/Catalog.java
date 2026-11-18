package cn.echo;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
class Catalog {
    record Playlist(int id, String name, String coverUrl, int playCount, List<Integer> trackIds) {}
    record Banner(int id, String imageUrl, int targetId, String title) {}
    record Feed(List<Banner> banners, List<JsonNode> daily, List<Playlist> playlists) {}
    record Detail(int id, String name, String coverUrl, int playCount, List<JsonNode> songs) {}
    record Search(List<JsonNode> list, List<Playlist> playlists, boolean hasMore) {}

    private final List<JsonNode> songs;
    private final Map<Integer, JsonNode> songsById = new LinkedHashMap<>();
    private final Map<Integer, Playlist> byId = new LinkedHashMap<>();
    private final List<Playlist> home;

    Catalog(ObjectMapper mapper, @Value("${echo.catalog-directory}") String directory) throws IOException {
        Path root = Path.of(directory);
        songs = List.copyOf(mapper.readValue(root.resolve("catalog-seed.json").toFile(), new TypeReference<List<JsonNode>>() {}));
        Map<Integer, List<JsonNode>> albums = new LinkedHashMap<>();
        for (JsonNode song : songs) {
            songsById.put(song.path("id").asInt(), song);
            if (song.hasNonNull("albumId") && song.hasNonNull("album")) {
                albums.computeIfAbsent(song.path("albumId").asInt(), id -> new ArrayList<>()).add(song);
            }
        }
        List<Playlist> seed = mapper.readValue(root.resolve("playlist-seed.json").toFile(),
            new TypeReference<List<Playlist>>() {});
        seed.forEach(item -> byId.put(item.id(), item));
        home = seed.stream().filter(item -> item.id() != 201).toList();
        albums.forEach((id, tracks) -> {
            tracks.sort(Comparator.comparingInt((JsonNode item) -> item.path("discNumber").asInt(1))
                .thenComparingInt(item -> item.path("trackNumber").asInt()));
            JsonNode first = tracks.get(0);
            byId.put(id, new Playlist(id, first.path("album").asText(), first.path("coverUrl").asText(), 0,
                tracks.stream().map(item -> item.path("id").asInt()).toList()));
        });
    }

    boolean hasSong(int id) {
        return songsById.containsKey(id);
    }

    Feed feed() {
        return new Feed(home.stream().limit(3)
            .map(item -> new Banner(item.id(), item.coverUrl(), item.id(), item.name())).toList(), songs, home);
    }

    Detail playlist(int id) {
        Playlist item = byId.get(id);
        if (item == null) {
            return null;
        }
        List<JsonNode> selected = item.trackIds() == null ? songs :
            item.trackIds().stream().map(songsById::get).filter(java.util.Objects::nonNull).toList();
        return new Detail(item.id(), item.name(), item.coverUrl(), item.playCount(), selected);
    }

    Search search(String keyword, int page, int size) {
        String query = keyword.strip().toLowerCase(Locale.ROOT);
        if (query.isEmpty()) {
            return new Search(List.of(), List.of(), false);
        }
        List<Playlist> lists = byId.values().stream().filter(item -> matches(item.name(), query)).toList();
        List<JsonNode> results = songs.stream().filter(song ->
            matches(song.path("title").asText(), query) || matches(song.path("artist").asText(), query)).toList();
        long start = (long) (page - 1) * size;
        long end = start + size;
        return new Search(slice(results, start - lists.size(), end - lists.size()), slice(lists, start, end),
            end < (long) results.size() + lists.size());
    }

    private static boolean matches(String value, String query) {
        return value.toLowerCase(Locale.ROOT).contains(query);
    }

    private static <T> List<T> slice(List<T> values, long start, long end) {
        return values.subList((int) Math.max(0, Math.min(start, values.size())), (int) Math.max(0, Math.min(end, values.size())));
    }
}