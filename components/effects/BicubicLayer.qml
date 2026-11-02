import QtQuick
import Aether.Shaders // qmllint disable unused-imports

// Resamples a layer texture with a Catmull-Rom bicubic filter instead of the default bilinear
// one. Animated panels move by fractions of a pixel, where bilinear softens the whole texture;
// the bicubic kernel keeps edges closer to the original rasterisation. At whole-pixel alignment
// it is the identity, so a panel at rest is untouched. See T67.
//
// The Aether.Shaders import is what makes `qrc:/shaders/bicubic.frag.qsb` resolvable -- the
// .qsb is compiled into that module's resources, so nothing else would load it.
ShaderEffect {
    property variant source

    fragmentShader: "qrc:/shaders/bicubic.frag.qsb"
}
