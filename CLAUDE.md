# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Home Assistant MCP Server is a Model Context Protocol (MCP) server that provides AI assistants (like Claude) with the ability to control Home Assistant smart home devices. The server exposes MCP tools for device control and also runs an Express HTTP server for health checks and direct API access.

## Development Commands

### Local Development
```bash
npm install              # Install dependencies
npm run dev              # Run in development mode with hot reload (uses tsx watch)
npm run build            # Compile TypeScript to dist/
npm start                # Run production build from dist/
npm run clean            # Remove dist/ directory
```

### Docker Development
```bash
make up                  # Build and start containers (docker-compose up -d)
make down                # Stop containers (docker-compose down)
make logs                # Follow container logs
make restart             # Restart containers
make health              # Check health endpoint (curl http://localhost:3000/health)
make status              # Show container status
make clean               # Remove containers, volumes, and node_modules
```

### Testing & Quality
```bash
npm test                 # Run Jest tests
npm run test:coverage    # Run tests with coverage report
npm run lint             # Run ESLint on src/**/*.ts
```

**Note**: Currently no test files exist (*.test.ts or *.spec.ts), but Jest is configured with ts-jest and requires 80% coverage thresholds.

## Architecture

### Dual-Server Design

This application runs **two servers simultaneously**:

1. **MCP Server** (stdio): Handles Model Context Protocol communication via stdio for AI assistant integration
2. **Express HTTP Server** (port 3000): Provides REST endpoints for health checks and direct API access

Both servers are started in `src/index.ts` and share the same Home Assistant connection.

### Core Components

**`src/index.ts`** - Main entry point that:
- Validates environment variables on startup
- Initializes the MCP server with 6 tools (list_devices, control, get_history, automation, activate_scene, notify)
- Sets up Express with security middleware (helmet, rate limiting)
- Registers HTTP endpoints (/health, /list_devices)
- Starts both servers simultaneously

**`src/schemas.ts`** - Zod validation schemas:
- Defines all MCP tool parameter schemas (ControlSchema, ListDevicesSchema, etc.)
- Exports TypeScript types inferred from schemas
- Contains domain and command enums for Home Assistant entities

**`src/helpers.ts`** - Shared utilities:
- `makeHassRequest()`: Wrapper for Home Assistant REST API calls with Bearer token auth
- `groupByDomain()`: Groups entities by their domain (light, switch, climate, etc.)
- `formatToolCall()`: Formats MCP tool responses with proper structure
- `validateEnv()`: Ensures required environment variables are present

### MCP Tools Architecture

Each tool follows this pattern:
```typescript
server.addTool({
  name: 'tool_name',
  description: 'Description for AI',
  parameters: ZodSchema,
  execute: async (params: TypedParams) => {
    try {
      const result = await makeHassRequest(...);
      return formatToolCall({ success: true, data: result });
    } catch (error: any) {
      return formatToolCall({ success: false, error: error.message }, true);
    }
  }
});
```

All tools:
- Use Zod schemas for parameter validation
- Call Home Assistant REST API via `makeHassRequest()`
- Return JSON responses wrapped by `formatToolCall()`
- Handle errors consistently with success/error format

### Home Assistant Integration

Communication with Home Assistant uses REST API endpoints:
- `/api/states` - List all entities
- `/api/services/{domain}/{service}` - Execute service calls
- `/api/history/period` - Query historical data
- Authentication via Bearer token in Authorization header

## Configuration

### Required Environment Variables

- `HASS_HOST`: Home Assistant URL (e.g., `http://homeassistant.local:8123`)
- `HASS_TOKEN`: Long-lived access token from Home Assistant

### Optional Environment Variables

- `PORT`: HTTP server port (default: 3000)
- `NODE_ENV`: Environment mode (default: production)
- `LOG_LEVEL`: Logging level (default: info)

Environment variables are loaded via `dotenv/config` at the top of index.ts. Use `.env.example` as a template.

## Docker Configuration

### Multi-Stage Build (Dockerfile)

1. **Builder stage**: Installs all dependencies, compiles TypeScript
2. **Production stage**: Copies compiled code, installs production dependencies only, runs as non-root user (UID 1001)

### Security Features

- Non-root user (hassio:node, UID 1001)
- Helmet.js security headers on Express
- Rate limiting (100 requests per 15 minutes per IP)
- Health checks every 30s
- Production dependencies only in final image

### Docker Compose

The `docker-compose.yml` file:
- Uses multi-stage build from Dockerfile
- Exposes port 3000 (configurable via PORT env var)
- Includes health check using /health endpoint
- Sets up bridge network named "homeassistant"
- Configures log rotation (10MB max, 3 files)

## Package Manager

This project uses **Yarn** as specified in `package.json` (`"packageManager": "yarn@1.22.22"`), but npm commands work as well. The project is configured as an ES module (`"type": "module"`).

## TypeScript Configuration

- ES modules with `.js` extensions in imports
- Strict mode disabled
- Target: ES2022
- Output directory: `dist/`
- Source maps enabled for debugging

## Key Dependencies

- **litemcp**: MCP protocol implementation
- **express**: HTTP server framework
- **helmet**: Security headers middleware
- **express-rate-limit**: Rate limiting
- **zod**: Runtime type validation and schema generation
- **@digital-alchemy/hass**: Home Assistant integration library (installed but not directly used in current implementation)

## Development Patterns

### Adding New MCP Tools

1. Define parameter schema in `src/schemas.ts` with Zod
2. Export TypeScript type using `z.infer<>`
3. Add tool in `src/index.ts` using `server.addTool()`
4. Use `makeHassRequest()` to call Home Assistant API
5. Return formatted responses with `formatToolCall()`

### Modifying Home Assistant API Calls

All Home Assistant API interactions go through `makeHassRequest()` in `src/helpers.ts`. This function:
- Constructs full URL from `HASS_HOST` + endpoint
- Adds Bearer token authentication
- Handles JSON parsing
- Throws errors with descriptive messages

### Express Endpoint Patterns

HTTP endpoints in index.ts should:
- Use try/catch for error handling
- Return JSON with `{ success: boolean, data?: any, error?: string }` structure
- Apply security middleware (already configured globally)

## Known Limitations

- No WebSocket support (REST API only)
- No authentication on HTTP endpoints (rate limiting only)
- Test files don't exist yet despite Jest configuration
- MCP server uses stdio only (no TCP transport option)
