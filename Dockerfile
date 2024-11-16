# Get the latest tag for Swift on Linux (non-slim one)
FROM swift:5.10 AS latest

WORKDIR /latest

COPY Package.swift ./
COPY Package.resolved ./

# Get dependencies
RUN swift package resolve

# Get source and test code
COPY . ./

# Build package
RUN swift build

# Test package
RUN swift test

# Run all test on Linux machine
CMD ["echo", "'swift test' ran successfully on Linux"]
