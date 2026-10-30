qml_module(aether-components
    URI Aether.Components
    SOURCES
        animatedrepeater.cpp
        lazylistview.cpp
        wavyline.cpp
        buttonrow.cpp
        circularindicatormanager.cpp
        linearindicatormanager.cpp
        sparklineitem.cpp
        visualiserbars.cpp
        roundedmask.cpp
    LIBRARIES
        Qt::Gui
        Qt::Quick
        aether-core
    DEPENDENCIES
        Aether
)

qt_add_shaders(aether-components "components_shaders"
    BATCHABLE OPTIMIZED NOHLSL NOMSL
    GLSL "300es,330"
    PREFIX "/"
    FILES
        shaders/roundedmask.frag
        shaders/roundedmask.vert
        shaders/visualiser.frag
)
