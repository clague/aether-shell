// Pins the scheme.json -> QPalette mapping. The whole platform theme is only as good as this
// one function, and it has no UI of its own: a wrong role here shows up as "Dolphin looks odd",
// three processes away. Feeding it a synthetic scheme makes each role assertable.
//
// QPalette's default constructor reads the application palette, so the test needs a
// QGuiApplication even though it never shows a window.
#include <qcolor.h>
#include <qguiapplication.h>
#include <qpalette.h>

#include <cstdio>

#include "Aether/QtTheme/aetherpalette.hpp"

using aether::theme::schemeFromJson;

namespace {

int failures = 0;

void check(bool ok, const char* what) {
    if (!ok) {
        std::printf("  FAIL: %s\n", what);
        ++failures;
    }
}

QByteArray scheme(const char* mode) {
    return QByteArray("{\"name\":\"test\",\"flavour\":\"default\",\"mode\":\"") + mode +
           "\",\"variant\":\"tonalspot\",\"colours\":{"
           "\"background\":\"130d09\",\"onBackground\":\"f7e2d3\","
           "\"surface\":\"130d09\",\"surfaceDim\":\"130d09\",\"surfaceBright\":\"362a20\","
           "\"surfaceContainerLow\":\"19120c\",\"surfaceContainer\":\"211811\","
           "\"surfaceContainerHigh\":\"271e16\",\"surfaceContainerHighest\":\"2f241a\","
           "\"onSurface\":\"f7e2d3\",\"onSurfaceVariant\":\"baa89b\","
           "\"primary\":\"f2bc90\",\"primaryDim\":\"e3ae83\",\"onPrimary\":\"5c3816\","
           "\"klink\":\"bf6ba0\",\"kvisited\":\"cc6234\",\"onError\":\"450900\"}}";
}

} // namespace

int main(int argc, char** argv) {
    QGuiApplication app(argc, argv);

    const auto dark = schemeFromJson(scheme("dark"));
    check(dark.has_value(), "a complete scheme parses");
    if (dark) {
        const QPalette& pal = dark->palette;
        check(!dark->light, "mode drives the light flag");
        check(pal.color(QPalette::Active, QPalette::Window) == QColor("#130d09"), "Window is the background");
        check(pal.color(QPalette::Active, QPalette::WindowText) == QColor("#f7e2d3"), "WindowText is onBackground");
        check(pal.color(QPalette::Active, QPalette::Text) == QColor("#f7e2d3"), "Text is onSurface");
        check(pal.color(QPalette::Active, QPalette::Base) == QColor("#19120c"), "Base is a container, not the window");
        check(pal.color(QPalette::Active, QPalette::Button) == QColor("#211811"), "Button is surfaceContainer");
        check(pal.color(QPalette::Active, QPalette::Highlight) == QColor("#f2bc90"), "Highlight is primary");
        check(pal.color(QPalette::Active, QPalette::HighlightedText) == QColor("#5c3816"),
            "HighlightedText is onPrimary");
        check(pal.color(QPalette::Active, QPalette::Link) == QColor("#bf6ba0"), "Link uses the scheme's link colour");
        check(pal.color(QPalette::Active, QPalette::PlaceholderText) == QColor("#baa89b"),
            "PlaceholderText is onSurfaceVariant");

        // Unfocused windows must not look as active as focused ones, and disabled text must not
        // read as live text: both are the difference between a working dialog and a confusing one.
        check(pal.color(QPalette::Inactive, QPalette::Highlight) == QColor("#e3ae83"),
            "Inactive Highlight is primaryDim");
        check(pal.color(QPalette::Disabled, QPalette::WindowText).alpha() < 255, "Disabled text is translucent");
        check(pal.color(QPalette::Disabled, QPalette::Highlight) != QColor("#f2bc90"), "Disabled Highlight is muted");
    }

    const auto light = schemeFromJson(scheme("light"));
    check(light.has_value() && light->light, "mode light is reported as light");

    check(!schemeFromJson(QByteArray("not json")).has_value(), "garbage is rejected");
    check(!schemeFromJson(QByteArray("{}")).has_value(), "an object without colours is rejected");
    check(!schemeFromJson(QByteArray("{\"colours\":{}}")).has_value(), "colours without a background are rejected");

    if (failures == 0)
        std::printf("PASS: 0 failure(s)\n");
    return failures == 0 ? 0 : 1;
}
