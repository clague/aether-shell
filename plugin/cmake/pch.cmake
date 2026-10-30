add_library(aether-pch INTERFACE)
target_precompile_headers(aether-pch INTERFACE
    <qobject.h>
    <qqmlintegration.h>
    <qstring.h>
    <qqmlengine.h>
    <qloggingcategory.h>
    <qvariant.h>
    <qtimer.h>
    <qdir.h>
    <qlist.h>
    <qstringlist.h>
    <qpointer.h>
)
