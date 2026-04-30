# Menu 11 Next — Plugin API

Drop `.js` files into this folder to register plugins at menu open.

Each file is loaded via `Qt.include()` and must call `PluginSystem.register({…})`.

---

## Plugin Contract

```js
PluginSystem.register({
    // Required
    name: "My Plugin",        // display name
    icon: "icon-name",        // freedesktop icon name

    // Optional — command palette entries
    commands: [
        {
            name: "My command",
            icon: "icon-name",
            desc: "Short description",
            cmd:  "shell command or JS function"
        }
    ],

    // Optional — command palette override (handles /prefix queries)
    // Return { result, icon } to show an inline card, or null to pass through
    handleQuery: function(query) {
        if (!query.startsWith("/myplugin ")) return null;
        return { result: "Output text", icon: "dialog-information" };
    },

    // Optional — inject results into the search page
    // Return array of result objects, or []
    searchResults: function(query) {
        if (!query || query.length < 2) return [];
        return [
            {
                icon:     "icon-name",
                title:    "Result title",
                subtitle: "Secondary text",
                // action: shell command string OR a JS function
                action:   "xdg-open 'https://example.com'"
            }
        ];
    },

    // Optional — contribute a named section to the home page
    // Must be a QML Component (created via Qt.createComponent or inline)
    uiSection: null
});
```

---

## Example: Web Bookmark plugin

Save as `plugins/bookmarks.js`:

```js
PluginSystem.register({
    name: "Bookmarks",
    icon: "bookmarks",
    searchResults: function(q) {
        var bookmarks = [
            { title: "GitHub", url: "https://github.com", icon: "github" },
            { title: "KDE",    url: "https://kde.org",    icon: "kde" }
        ];
        var lower = q.toLowerCase();
        var results = [];
        for (var i = 0; i < bookmarks.length; i++) {
            if (bookmarks[i].title.toLowerCase().indexOf(lower) >= 0) {
                results.push({
                    icon:     bookmarks[i].icon,
                    title:    bookmarks[i].title,
                    subtitle: bookmarks[i].url,
                    action:   "xdg-open '" + bookmarks[i].url + "'"
                });
            }
        }
        return results;
    }
});
```

---

## Notes

- Plugins are loaded once per menu session (on first open).
- Errors in a single plugin are caught and isolated — other plugins still load.
- The `PluginSystem` object is always available; no import is needed in plugin files.
- Plugin folder: `~/.local/share/plasma/plasmoids/menu.11.next/plugins/`
