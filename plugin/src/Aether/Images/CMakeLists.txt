qml_module(aether-images
    URI Aether.Images
    SOURCES
        cachingimageprovider.cpp
        imagecacher.cpp
        imagecacher.hpp
        imageanalyser.cpp
        iutils.cpp
    LIBRARIES
        Qt::Gui
        Qt::Quick
        Qt::Concurrent
)
