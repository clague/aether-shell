.pragma library

// Pure URL, header and response rules for the four AI providers, kept out of AiAssistant.qml so
// tests/ai-endpoints.qml can exercise them without a running shell.

var DEFAULTS = {
    "openrouter": "https://openrouter.ai/api/v1",
    "openclaw": "http://127.0.0.1:18789",
    "ollama": "http://localhost:11434",
    "custom": ""
};

function baseUrl(provider, cfg) {
    var url = provider === "openrouter" ? cfg.openRouterUrl : provider === "openclaw" ? cfg.openClawUrl : provider === "custom" ? cfg.customUrl : cfg.ollamaUrl;
    return String(url || DEFAULTS[provider] || "").replace(/\/+$/, "");
}

function modelsUrl(provider, cfg) {
    var base = baseUrl(provider, cfg);
    if (!base)
        return "";
    if (provider === "ollama")
        return base + "/api/tags";
    if (provider === "openclaw")
        return base + "/v1/models";
    return base + "/models";
}

function chatUrl(provider, cfg) {
    var base = baseUrl(provider, cfg);
    if (!base)
        return "";
    if (provider === "ollama")
        return base + "/api/chat";
    if (provider === "openclaw")
        return base + "/v1/chat/completions";
    return base + "/chat/completions";
}

function authHeaders(provider, cfg) {
    if (provider === "openrouter") {
        if (!cfg.openRouterApiKey)
            return {};
        return {
            "Authorization": "Bearer " + cfg.openRouterApiKey,
            "HTTP-Referer": "https://github.com/dim-ghub/midnight-shell",
            "X-Title": "midnight-shell"
        };
    }
    if (provider === "openclaw")
        return cfg.openClawToken ? {
            "Authorization": "Bearer " + cfg.openClawToken
        } : {};
    if (provider === "custom")
        return cfg.customApiKey ? {
            "Authorization": "Bearer " + cfg.customApiKey
        } : {};
    return {};
}

// What a model list depends on: the endpoint and the key. Change either and a cached list is
// stale; change neither and asking again cannot return anything new.
function signature(provider, cfg) {
    var key = provider === "openrouter" ? cfg.openRouterApiKey : provider === "openclaw" ? cfg.openClawToken : provider === "custom" ? cfg.customApiKey : "";
    return modelsUrl(provider, cfg) + "\n" + (key || "");
}

function parseModels(provider, text) {
    var response = JSON.parse(text);
    var list = [];
    if (provider === "ollama") {
        var models = response.models || [];
        for (var i = 0; i < models.length; i++) {
            if (models[i].name)
                list.push(models[i].name);
        }
    } else {
        var data = response.data || [];
        for (var j = 0; j < data.length; j++) {
            if (data[j].id)
                list.push(data[j].id);
        }
        list.sort();
    }
    return list;
}

// A key sent over plain HTTP leaves the machine readable. Localhost never leaves it.
function isInsecure(url) {
    var u = String(url || "");
    if (!/^http:\/\//i.test(u))
        return false;
    return !/^http:\/\/(localhost|127\.0\.0\.1|\[::1\])(?::\d+)?(?:\/|$)/i.test(u);
}
