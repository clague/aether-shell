// Pure-function checks for modules/sidebar/aiendpoints.js.
// Run by tools/verify.sh: QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qml tests/ai-endpoints.qml
import QtQuick
import "../modules/sidebar/aiendpoints.js" as AiEndpoints

Item {
    id: root

    property bool failed: false

    function cfg(overrides) {
        var base = {
            "ollamaUrl": "",
            "openRouterUrl": "",
            "openRouterApiKey": "",
            "openClawUrl": "",
            "openClawToken": "",
            "customUrl": "",
            "customApiKey": ""
        };
        for (var key in overrides)
            base[key] = overrides[key];
        return base;
    }

    function check(name, got, want) {
        if (JSON.stringify(got) !== JSON.stringify(want)) {
            console.error("ai-endpoints: " + name + " got " + JSON.stringify(got) + ", want " + JSON.stringify(want));
            root.failed = true;
        }
    }

    Component.onCompleted: {
        check("default ollama models", AiEndpoints.modelsUrl("ollama", cfg({})), "http://localhost:11434/api/tags");
        check("default openrouter models", AiEndpoints.modelsUrl("openrouter", cfg({})), "https://openrouter.ai/api/v1/models");
        check("openclaw models", AiEndpoints.modelsUrl("openclaw", cfg({
            "openClawUrl": "http://127.0.0.1:9000"
        })), "http://127.0.0.1:9000/v1/models");
        check("custom trailing slash", AiEndpoints.modelsUrl("custom", cfg({
            "customUrl": "https://api.example.com/v1/"
        })), "https://api.example.com/v1/models");
        check("custom unset", AiEndpoints.modelsUrl("custom", cfg({})), "");

        check("ollama chat", AiEndpoints.chatUrl("ollama", cfg({
            "ollamaUrl": "http://localhost:11434/"
        })), "http://localhost:11434/api/chat");
        check("openrouter chat", AiEndpoints.chatUrl("openrouter", cfg({})), "https://openrouter.ai/api/v1/chat/completions");
        check("openclaw chat", AiEndpoints.chatUrl("openclaw", cfg({})), "http://127.0.0.1:18789/v1/chat/completions");
        check("custom chat", AiEndpoints.chatUrl("custom", cfg({
            "customUrl": "https://api.example.com/v1"
        })), "https://api.example.com/v1/chat/completions");

        check("no key, no headers", AiEndpoints.authHeaders("custom", cfg({})), {});
        check("custom key", AiEndpoints.authHeaders("custom", cfg({
            "customApiKey": "sk-test"
        })), {
            "Authorization": "Bearer sk-test"
        });
        check("openclaw token", AiEndpoints.authHeaders("openclaw", cfg({
            "openClawToken": "t"
        })), {
            "Authorization": "Bearer t"
        });
        check("openrouter headers", AiEndpoints.authHeaders("openrouter", cfg({
            "openRouterApiKey": "k"
        })), {
            "Authorization": "Bearer k",
            "HTTP-Referer": "https://github.com/clague/aether-shell",
            "X-Title": "aether"
        });
        check("ollama has no auth", AiEndpoints.authHeaders("ollama", cfg({})), {});

        var one = cfg({
            "customUrl": "https://api.example.com/v1",
            "customApiKey": "a"
        });
        var two = cfg({
            "customUrl": "https://api.example.com/v1",
            "customApiKey": "b"
        });
        check("same signature", AiEndpoints.signature("custom", one) === AiEndpoints.signature("custom", one), true);
        check("key changes signature", AiEndpoints.signature("custom", one) === AiEndpoints.signature("custom", two), false);

        check("ollama models", AiEndpoints.parseModels("ollama", "{\"models\":[{\"name\":\"llama3\"},{\"name\":\"phi3\"}]}"), ["llama3", "phi3"]);
        check("openai models sorted", AiEndpoints.parseModels("custom", "{\"data\":[{\"id\":\"z\"},{\"id\":\"a\"}]}"), ["a", "z"]);
        check("empty list", AiEndpoints.parseModels("custom", "{\"data\":[]}"), []);

        check("https is secure", AiEndpoints.isInsecure("https://api.example.com/v1"), false);
        check("http remote is insecure", AiEndpoints.isInsecure("http://api.example.com/v1"), true);
        check("http localhost is local", AiEndpoints.isInsecure("http://localhost:8080/v1"), false);
        check("http 127.0.0.1 is local", AiEndpoints.isInsecure("http://127.0.0.1:8080/v1"), false);
        check("http [::1] is local", AiEndpoints.isInsecure("http://[::1]:8080/v1"), false);
        check("localhost lookalike is insecure", AiEndpoints.isInsecure("http://localhost.example.com"), true);

        console.log(root.failed ? "ai-endpoints: FAILED" : "ai-endpoints: PASS");
        Qt.exit(root.failed ? 1 : 0);
    }
}
