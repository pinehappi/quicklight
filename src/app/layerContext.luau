local vide = require(script.Parent.Parent.Packages.vide)
return vide.context() :: (
    (() -> LayerCollector)
    & (<T>(LayerCollector, () -> T) -> T)
)