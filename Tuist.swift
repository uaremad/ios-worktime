//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

@preconcurrency import ProjectDescription

// Configures the generation options for the project description.
let config = Config(
    generationOptions: .options(resolveDependenciesWithSystemScm: false)
)
