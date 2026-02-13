//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Danger

let danger = Danger()

// MARK: - Big PR Check

let bigPRThreshold = 1000
if let additions = danger.github.pullRequest.additions, let deletions = danger.github.pullRequest.deletions, additions + deletions > bigPRThreshold {
    warn("Pull Request size seems relatively large.\nPlease try to split this PR to support faster and easier reviews.")
}

// MARK: - Missing PR description

if var body = danger.github.pullRequest.body {
    body = body.removeComments().removeWhitespaces()

    if body.count < 40 {
        fail("Please provide a proper Pull Request description.")
    }
}

// MARK: - Ensure a clean commits history

if danger.git.commits.contains(where: { $0.message.starts(with: "Merge branch ") }) {
    fail("Please rebase to get rid of the merge commits in this PR")
}

// MARK: - Untracked files and file changes

let gitStatus = danger.utils.exec("git status --porcelain")

if !gitStatus.isEmpty {
    fail("""
    The Git Index contains the following untracked changes:

    \(gitStatus)

    Please commit and push all changes.
    """)
}

if gitStatus.contains("Podfile.lock") {
    message("Run `bundle exec pod install` and push the modified `Podfile.lock`.")
}

// MARK: - SwiftLint

// SwiftLint.lint(inline: true) // needs to be fixed first to re-enable it

// MARK: - Extensions

private extension String {
    func removeComments() -> String {
        replacingOccurrences(of: "<!--[^>]*-->", with: "", options: .regularExpression)
    }

    func removeWhitespaces() -> String {
        replacingOccurrences(of: "[\\s\n]*", with: "", options: .regularExpression)
    }
}

// - Overview of detected lints (SwiftFormat?)
// - Code Coverage
// - Xcode Summary (warnings, errors, etc.)
