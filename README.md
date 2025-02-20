# Simple PureScript Application

## Development

**Enter the development environment**
```bash
nix develop
```

**Development Commands**

- `watch-project` - Build the project, start the development server, and watch for changes
  - This is the main development command you'll use
  - Automatically rebuilds when files change
  - Shows server URLs when started
  - Access the application at http://localhost:8080

**Alternative Commands**

- `build-project` - Build and bundle the application without serving
- `serve-project` - Build and serve the application without watching for changes
- `spago build` - Build the project (PureScript compilation only)
- `spago test` - Run tests
- `spago repl` - Start a PureScript REPL session 