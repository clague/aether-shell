// Pins the two decisions the Qt platform theme makes without a UI: how scheme.json maps onto a
// QPalette, and which widget style it hands Qt. A wrong role shows up as "Dolphin looks odd" three
// processes away; a wrong style shows up as "my widgets are the wrong shape" with no error at all.
//
// QPalette's default constructor reads the application palette, so the test needs a
// QGuiApplication even though it never shows a window.
#include <qcolor.h>
#include <qguiapplication.h>
#include <qpalette.h>

#include <cstdio>

#include "Aether/QtTheme/aetherpalette.hpp"
#include "Aether/QtTheme/aetherstyle.hpp"

using aether::theme::iniValue;
using aether::theme::kdeColorScheme;
using aether::theme::kvantumThemeName;
using aether::theme::schemeFromJson;
using aether::theme::shellQtStyle;

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

    // KDE applications paint from this file, not from the palette above, so it has to carry the
    // same colours in the format KColorScheme reads.
    if (dark) {
        const QByteArray kde = kdeColorScheme(dark->colours, "Aether");
        check(kde.contains("[Colors:View]"), "kde scheme has a View section");
        check(kde.contains("[Colors:Selection]"), "kde scheme has a Selection section");
        check(kde.contains("ForegroundNormal=#f7e2d3"), "view text is onSurface");
        check(kde.contains("BackgroundNormal=#f2bc90"), "selection background is primary");
        check(kde.contains("ColorScheme=Aether"), "the scheme names itself");
    }

    const auto light = schemeFromJson(scheme("light"));
    check(light.has_value() && light->light, "mode light is reported as light");

    check(!schemeFromJson(QByteArray("not json")).has_value(), "garbage is rejected");
    check(!schemeFromJson(QByteArray("{}")).has_value(), "an object without colours is rejected");
    check(!schemeFromJson(QByteArray("{\"colours\":{}}")).has_value(), "colours without a background are rejected");

    // One parser reads both files: kdeglobals is sectioned, kvantum.kvconfig is not.
    check(iniValue("[Icons]\nTheme=kora\n[General]\nfont=x\n", "Icons", "Theme") == "kora", "section scoping");
    check(iniValue("[Icons]\nTheme=kora\n", "General", "Theme").isEmpty(), "key from another section");
    check(iniValue("[General]\nfont=Sans Serif,13\n", "General", "font") == "Sans Serif,13", "value with commas");

    // kvantummanager writes [General] and nothing else. QSettings reads a bare [General] as the
    // root, which is why this is parsed by hand -- and why the section must not throw it off.
    check(kvantumThemeName("[General]\ntheme=Gradient-Dark-Kvantum\n") == "Gradient-Dark-Kvantum",
        "theme under [General]");
    check(kvantumThemeName("theme=Breeze\n") == "Breeze", "theme without a section");
    check(kvantumThemeName("[General]\ntheme=  \"Quoted Name\"  \n") == "Quoted Name", "quoted theme");
    check(kvantumThemeName("[General]\n#theme=Commented\n") == "", "commented key is ignored");
    check(kvantumThemeName("[General]\ntheme=First\ntheme=Second\n") == "First", "the first theme wins");
    check(kvantumThemeName("[General]\ncolors=#fff\n").isEmpty(), "no theme key");
    check(kvantumThemeName(QByteArray()).isEmpty(), "empty file");

    // The shell's own config decides the style when it says something other than "auto"; that key
    // has to be readable straight out of shell.json, which the CLI never rewrites.
    check(shellQtStyle(R"({"appearance":{"qtStyle":"kvantum"}})") == "kvantum", "style from shell.json");
    check(shellQtStyle(R"({"appearance":{"qtStyle":"auto"}})") == "auto", "auto is passed through");
    check(shellQtStyle(R"({"appearance":{}})").isEmpty(), "missing key");
    check(shellQtStyle(R"({"general":{"qtStyle":"fusion"}})").isEmpty(), "key in the wrong node");
    check(shellQtStyle(R"({"appearance":{"qtStyle":5}})").isEmpty(), "non-string value");
    check(shellQtStyle("not json").isEmpty(), "garbage shell config");

    if (failures == 0)
        std::printf("PASS: 0 failure(s)\n");
    return failures == 0 ? 0 : 1;
}
