# Contributing to the iOS Brief-App

## Code of Conduct

### Our Standards

Examples of behavior that contributes to creating a positive environment include:

- We use welcoming and inclusive language
- We are respectful of adiffering viewpoints and experiences
- We gracefully accept constructive criticism
- We focus on what is best for the company
- We show empathy towards other colleagues
- We allow anyone to speak freely with freedom of speech in mind
- We value the opinions of all team members
- We communicate transparently
- We value our time in meetings with punctuality
- We dedicate our time to the product and team. 
- We learn the pronunciation of our team members' names & respect their choice or denial of names.

Examples of unacceptable behavior by participants include:

- The use of sexualized language or imagery and unwelcome sexual attention or advances
- Trolling, insulting/derogatory comments, and personal or political attacks
- Public or private harassment
- Publishing other's private information, such as a physical or electronic address, without explicit permission
- Other conduct which could reasonably be considered inappropriate in a professional setting
- Finger-pointing is unacceptable

### Responsibilities

We are responsible for our own actions, and we take consequences.

We say no if it will violate our own standards, ethics and the health of our company. 

## Adopting the Definition of Done

If you create a PR in the design system, this list of requirements should be respected:

- The public API is fully documented; if the code is already self-explanatory, please add `///` above to make it clear you intentionally did not add documentation and did not forget about it.

```swift
///
public enum AppStatus {
    ///
    case on
    ///
    case off
}
```

- The new component should be available in the Network System Catalog
- The component has unit and if possible snapshot tests
- The component is used in the `NetworkSystemCatalog`

## New contributor guide

### Installations needed

#### SwiftFormat

```bash
brew install swiftformat
```

#### SwfiftLint

```bash
brew install swiftlint
```

#### Tuist

```bash
curl -Ls https://install.tuist.io | bash
```

#### SwiftGen

```bash
brew install swiftgen
```

### Useful commands

#### Open the project

```bash
make open
```

#### Edit the tuist project

```bash
make edit
```

## Pull Requests

Fill in the template, delete parts that are not relevant. For visual changes, add screenshots.

### Merging strategy into main

Use squash commit while merging and name your commit `Feature name [Ticket-number]`. 

You can rebase but all your commits should be functional and follow the same naming.

### Codeowners

The code owners are defined in the [CODEOWNERS](.github/CODEOWNERS) file.

Do not hesitate to contact any of them! They are there to help you. 

### Code review

To merge a pull request 2 reviewers are needed, one of whom should be a code owner.

A discussion should be resolved by the person opening it.
