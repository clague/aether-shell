pragma Singleton

import Aether.Plugins

PluginsBase {
    function entryPoints(type: int): list<pluginEntryPoint> {
        // Reading the revision is what makes the returned list reactive to plugins appearing,
        // disappearing or changing their entry points.
        entryPointsRevision; // qmllint disable confusing-expression-statement
        return entryPointsForType(type);
    }
}
