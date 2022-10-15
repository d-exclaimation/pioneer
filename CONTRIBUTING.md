# Contributing to Pioneer

First off, thanks for taking the time to contribute! 

All types of contributions are encouraged and valued. 

## Table of Contents

- [I Have a Question](#i-have-a-question)
- [I Want To Contribute](#i-want-to-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Enhancements](#suggesting-enhancements)
  - [Code Contribution](#code-contribution)
  - [Improving The Documentation](#improving-the-documentation)
- [Styleguides](#styleguides)
  - [Commit Messages](#commit-messages)
- [Join The Project Team](#join-the-project-team)



## I Have a Question

> If you want to ask a question, we assume that you have read the available [Documentation](https://pioneer-graphql.netlify.app).
>
> We do not discourage asking questions even if it might not be related. Although, we might refer to better sources that are more suitable for the questions.

Before you ask a question, it is best to search for existing [Issues](https://github.com/d-exclaimation/pioneer/issues) that might help you. In case you have found a suitable issue and still need clarification, you can write your question in this issue.

If you then still feel the need to ask a question and need clarification, we recommend the following:

- Open an [Issue](https://github.com/d-exclaimation/pioneer/issues/new).
- Provide as much context as you can about what you're running into, depending on what seems relevant.
- Add the `question` label to the [Issue](https://github.com/d-exclaimation/pioneer/issues).

We will then take care of the issue as soon as possible. 

## I Want To Contribute

> ### Legal Notice
> When contributing to this project, you must agree that you have authored 100% of the content, that you have the necessary rights to the content and that the content you contribute may be provided under the project license.

### Reporting Bugs

#### Before Submitting a Bug Report

We ask you to investigate carefully, collect information and describe the issue in detail in your report. Please complete the following steps in advance to help us fix any potential bug as fast as possible.

- Make sure that you are using the latest version.
- Determine if your bug is really a bug and not an error on your side e.g. using incompatible environment components/versions (Make sure that you have read the [documentation](https://pioneer-graphql.netlify.app). If you are looking for support, you might want to check [this section](#i-have-a-question)).
- To see if other users have experienced (and potentially already solved) the same issue you are having, check if there is not already a bug report existing for your bug or error in the [bug tracker](https://github.com/d-exclaimation/pioneer/issues?q=label%3Abug).
- Collect information about the bug:
  - Stack trace (Traceback)
  - OS, Platform and Version (Windows, Linux, macOS, x86, ARM)
  - Version of Swift, Pioneer, Vapor, and any other libraries you are using.
  - Possibly your input and the output
  - Can you reliably reproduce the issue?

#### How Do I Submit a Good Bug Report?

> You must never report security related issues, vulnerabilities or bugs including sensitive information to the issue tracker, or elsewhere in public. Instead sensitive bugs must be sent by email to <thisoneis4business@gmail.com>.

We use GitHub issues to track bugs and errors. If you run into an issue with the project:

- Open an [Issue](https://github.com/d-exclaimation/pioneer/issues/new). (Since we can't be sure at this point whether it is a bug or not, we ask you not to talk about a bug yet and not to label the issue.)
- Explain the behavior you would expect and the actual behavior.
- Please provide as much context as possible and describe the *reproduction steps* that someone else can follow to recreate the issue on their own. This usually includes your code. For good bug reports you should isolate the problem and create a reduced test case.
- Provide the information you collected in the previous section.

Once it's filed:

- We will label the issue accordingly.
- A maintainer will try to reproduce the issue with your provided steps. If there are no reproduction steps or no obvious way to reproduce the issue, the team will ask you for those steps which will not be fully addressed until it can be reproduced.
- If the team is able to reproduce the issue, it will be worked on or the issue will be left to be [implemented by someone](#your-first-code-contribution).


### Suggesting Enhancements

This section guides you through submitting an enhancement suggestion for Pioneer, **including completely new features and minor improvements to existing functionality**. Following these guidelines will help maintainers and the community to understand your suggestion and find related suggestions.

#### Before Submitting an Enhancement

- Make sure that you are using the latest version.
- Read the [documentation](https://pioneer-graphql.netlify.app) carefully and find out if the functionality is already covered, maybe by an individual configuration.
- Perform a [search](https://github.com/d-exclaimation/pioneer/issues) to see if the enhancement has already been suggested. If it has, add a comment to the existing issue instead of opening a new one.
- Find out whether your idea fits with the scope and aims of the project. It's up to you to make a strong case to convince the project's developers of the merits of this feature. 
- If the feature span across not just this library but others, mention it.

#### How Do I Submit a Good Enhancement Suggestion?

Enhancement suggestions are tracked as [GitHub issues](https://github.com/d-exclaimation/pioneer/issues).

- Use a **clear and descriptive title** for the issue to identify the suggestion.
- Provide a **description of the suggested enhancement** in as many details as possible.
- **Explain why this enhancement would be useful**. Feel free to point out the other projects that solved it better and which could serve as inspiration.

### Code Contribution

This section guides you through contributing to Pioneer.

#### Contributing Documentation

Code documentation (`///`) has a special convention: the first paragraph is considered to be a short summary, followed by details such as parameters, returned value, etc.

For functions say what it will do. For example write something like:
```swift
/// Common Handler for GraphQL through HTTP
/// - Parameter req: The HTTP request being made
/// - Returns: A response from the GraphQL operation execution properly formatted
public func httpHandler(req: Request) async throws -> Response 
```

For structs, classes, protocols, and actors say what it is. For example write something like:
```swift
/// An actor to broadcast messages to multiple downstream from a single upstream
public actor Broadcast<MessageType: Sendable> 
```

For lines of code try to say what it is for and why it is there. For example write something like:
```swift
// Fatal error is an event trigger when message given in unacceptable by protocol standard
// This message if processed any further will cause securities vulnerabilities, thus connection should be closed
case .fatal(message: let message):
```

Try to keep unnecessary details out of the code documentation, it's only there to give a user a quick idea of what the documented "thing" does/is. 

#### Pull Requests

Good pull request are always welcome. However, they should remain focused in scope and avoid containing unrelated commits.

> **Important**
>
> By submitting a patch, you agree that your work will be licensed under the license used by the project

Please adhere to the coding conventions in the project (indentation, accurate comments, etc.) and don't forget to add your own tests and documentation. When working with git, we recommend the following process in order to craft an excellent pull request:

- Fork the project, clone your fork locally, and configure remotes:
```sh
# Clone your fork of the repo into the current directory
git clone https://github.com/<your-username>/pioneer

# Navigate to the newly cloned directory
cd pioneer

# Assign the original repo to a remote called "upstream"
git remote add upstream https://github.com/d-exclaimation/pioneer
```

- If you cloned a while ago, get the latest changes from upstream, and update your fork:

```sh
git checkout master
git pull upstream master
git push
```

- Create a new topic branch (off of `main`) to contain your feature, change, or fix. **Avoid** making changes in the `main` branch.

```sh
git checkout -b <branch-name>
```

- Commit your changes in logical chunks. Keep the commit message organised and readable. We encourage usage of prefixes such as `feat:`, `fix:`, etc.

```sh
git commit -m 'fix: made httpHandler response with proper status codes'
```

- Make sure all the tests are still passing. If you are implementing a new feature, add some test cases as well.

```sh
swift test
```

- Push your topic branch up to your fork

```sh
git push origin <branch-name>
```

- [Open a Pull Request](https://github.com/d-exclaimation/pioneer/compare) with a clear title and description.

Thank you for your contributions!

#### Improving The Documentation

Updating documentation should go through similar process with any [pull request](#pull-requests). However, passing test is not a requirement (If tests somehow failed, open an [issue](#how-do-i-submit-a-good-bug-report)).

The documentation is built with [Retype](https://retype.com). All you need to see the documentation are:

- Install `retype` CLI
- Go to the documentation directory
- Run `retype watch`
- Run `retype build` to check for compilation errors

## Styleguides

Refer to the [Swift API Guidelines](https://www.swift.org/documentation/api-design-guidelines/).

## Attribution
This guide is based on the [contributing-gen](https://generator.contributing.md/).
