# Home Assistant MCP Server (Docker Edition)

A Model Context Protocol (MCP) server for controlling Home Assistant, designed to run in Docker containers.

## Features

- **MCP Protocol Support**: Full integration with Claude and other MCP-compatible clients
- **Device Control**: Control lights, switches, climate systems, covers, and more
- **Automation Management**: Trigger and manage Home Assistant automations
- **Scene Activation**: Activate predefined scenes
- **History Access**: Query historical state data for entities
- **Notifications**: Send notifications through Home Assistant services
- **RESTful API**: HTTP endpoints for direct access
- **Docker Ready**: Optimized multi-stage Docker build
- **Health Checks**: Built-in health monitoring
- **Security**: Rate limiting, helmet.js security headers, and non-root user

## Quick Start with Docker Compose

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd HassioMcp
   ```

2. **Configure environment**:
   ```bash
   cp .env.example .env
   # Edit .env and set your Home Assistant credentials
   ```

3. **Start the server**:
   ```bash
   docker-compose up -d
   ```

4. **Check health**:
   ```bash
   curl http://localhost:3000/health
   ```

## Configuration

### Environment Variables

Create a `.env` file with the following variables:

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `HASS_HOST` | Yes | - | Home Assistant URL (e.g., `http://homeassistant.local:8123`) |
| `HASS_TOKEN` | Yes | - | Long-lived access token from Home Assistant |
| `PORT` | No | 3000 | Server port |
| `NODE_ENV` | No | production | Environment (development, production, test) |
| `LOG_LEVEL` | No | info | Logging level (debug, info, warn, error) |

### Getting a Home Assistant Access Token

1. Log into your Home Assistant instance
2. Click on your profile (bottom left)
3. Scroll down to "Long-Lived Access Tokens"
4. Click "Create Token"
5. Give it a name (e.g., "MCP Server")
6. Copy the token and add it to your `.env` file

## Docker Deployment

### Using Docker Compose (Recommended)

```bash
# Build and start
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down

# Rebuild after changes
docker-compose up -d --build
```

### Using Docker CLI

```bash
# Build the image
docker build -t homeassistant-mcp .

# Run the container
docker run -d \
  --name homeassistant-mcp \
  -p 3000:3000 \
  -e HASS_HOST=http://homeassistant.local:8123 \
  -e HASS_TOKEN=your_token_here \
  homeassistant-mcp

# View logs
docker logs -f homeassistant-mcp

# Stop and remove
docker stop homeassistant-mcp
docker rm homeassistant-mcp
```

## Available MCP Tools

### 1. list_devices
List all available Home Assistant devices and entities.

**Parameters**:
- `domain` (optional): Filter by domain (light, switch, climate, etc.)

**Example**:
```json
{
  "domain": "light"
}
```

### 2. control
Control Home Assistant devices.

**Parameters**:
- `entity_id` (required): Entity ID to control
- `command` (required): Command to execute (turn_on, turn_off, toggle, etc.)
- `brightness` (optional): Brightness level (0-255) for lights
- `temperature` (optional): Temperature for climate devices
- `position` (optional): Position (0-100) for covers
- `hvac_mode` (optional): HVAC mode for climate devices
- `rgb_color` (optional): RGB color as [r, g, b] array

**Example**:
```json
{
  "entity_id": "light.living_room",
  "command": "turn_on",
  "brightness": 200,
  "rgb_color": [255, 0, 0]
}
```

### 3. get_history
Retrieve historical state data for entities.

**Parameters**:
- `entity_id` (required): Entity to get history for
- `start_time` (optional): Start time in ISO format
- `end_time` (optional): End time in ISO format

**Example**:
```json
{
  "entity_id": "sensor.temperature",
  "start_time": "2024-01-01T00:00:00Z"
}
```

### 4. automation
Control Home Assistant automations.

**Parameters**:
- `automation_id` (required): Automation entity ID
- `action` (required): Action to perform (trigger, toggle, turn_on, turn_off)

**Example**:
```json
{
  "automation_id": "automation.morning_routine",
  "action": "trigger"
}
```

### 5. activate_scene
Activate a Home Assistant scene.

**Parameters**:
- `scene_id` (required): Scene entity ID to activate

**Example**:
```json
{
  "scene_id": "scene.movie_time"
}
```

### 6. notify
Send notifications through Home Assistant.

**Parameters**:
- `message` (required): Notification message
- `title` (optional): Notification title
- `target` (optional): Notification target/device

**Example**:
```json
{
  "message": "Front door opened",
  "title": "Security Alert",
  "target": "mobile_app_my_phone"
}
```

## HTTP API Endpoints

The server also exposes HTTP endpoints:

- `GET /health` - Health check endpoint
- `GET /list_devices` - List all devices (no authentication required for demo)

## Development

### Local Development (without Docker)

1. **Install dependencies**:
   ```bash
   npm install
   ```

2. **Set up environment**:
   ```bash
   cp .env.example .env
   # Edit .env with your settings
   ```

3. **Run in development mode**:
   ```bash
   npm run dev
   ```

4. **Build TypeScript**:
   ```bash
   npm run build
   ```

5. **Run production build**:
   ```bash
   npm start
   ```

### Running Tests

```bash
npm test
npm run test:coverage
```

### Linting

```bash
npm run lint
```

## Architecture

### Components

- **MCP Server**: Handles Model Context Protocol communication via stdio
- **Express Server**: Provides HTTP/REST endpoints for direct API access
- **Home Assistant Client**: Communicates with Home Assistant REST API
- **Security Layer**: Helmet.js, rate limiting, and input validation
- **Health Monitoring**: Built-in health checks for Docker orchestration

### Tech Stack

- **Runtime**: Node.js 20
- **Language**: TypeScript
- **MCP Framework**: litemcp
- **HTTP Framework**: Express.js
- **Validation**: Zod
- **Security**: Helmet.js, express-rate-limit
- **Container**: Docker with multi-stage builds

## Troubleshooting

### Connection Issues

1. **Cannot connect to Home Assistant**:
   - Verify `HASS_HOST` is correct and accessible from the container
   - Check that Home Assistant is running
   - Ensure network connectivity between containers

2. **Authentication errors**:
   - Verify your `HASS_TOKEN` is valid
   - Check token hasn't expired
   - Ensure token has necessary permissions

3. **Docker networking**:
   - If Home Assistant is also in Docker, ensure both containers are on the same network
   - Use Docker service names instead of `localhost`

### Viewing Logs

```bash
# Docker Compose
docker-compose logs -f homeassistant-mcp

# Docker CLI
docker logs -f homeassistant-mcp
```

### Health Check

```bash
# Check if server is healthy
curl http://localhost:3000/health

# Expected response
{
  "status": "healthy",
  "service": "homeassistant-mcp",
  "version": "0.1.0",
  "timestamp": "2024-01-05T12:00:00.000Z"
}
```

## Security Considerations

- The server runs as a non-root user (UID 1001)
- Rate limiting is enabled (100 requests per 15 minutes per IP)
- Security headers are applied via Helmet.js
- Environment variables are used for sensitive configuration
- Health checks don't expose sensitive information

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

MIT License - See LICENSE file for details

## Credits

Based on the [homeassistant-mcp](https://github.com/tevonsb/homeassistant-mcp) project by Jango Blockchained.

## Support

For issues and questions:
- Open an issue on GitHub
- Check Home Assistant documentation
- Review MCP protocol documentation
