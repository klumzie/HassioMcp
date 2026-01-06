#!/usr/bin/env node

/**
 * Home Assistant MCP Server - Stdio Only
 * Entry point for Claude Desktop and other stdio MCP clients
 * This version only runs the MCP server without the Express HTTP server
 */

import 'dotenv/config';
import { LiteMCP } from 'litemcp';
import { validateEnv, makeHassRequest, groupByDomain, formatToolCall } from './helpers.js';
import {
  ControlSchema,
  ListDevicesSchema,
  GetHistorySchema,
  AutomationSchema,
  SceneSchema,
  NotifySchema,
  type ControlParams,
  type ListDevicesParams,
  type GetHistoryParams,
  type AutomationParams,
  type SceneParams,
  type NotifyParams,
} from './schemas.js';

// Validate environment variables
validateEnv();

const HASS_HOST = process.env.HASS_HOST!;
const HASS_TOKEN = process.env.HASS_TOKEN!;

// Initialize MCP Server
const server = new LiteMCP('homeassistant-mcp', '0.1.0');

/**
 * Tool: List Devices
 * Lists all available Home Assistant entities, optionally filtered by domain
 */
server.addTool({
  name: 'list_devices',
  description: 'List all available Home Assistant devices and entities, optionally filtered by domain (light, switch, climate, etc.)',
  parameters: ListDevicesSchema,
  execute: async (params: ListDevicesParams) => {
    try {
      const entities = await makeHassRequest('/api/states', HASS_HOST, HASS_TOKEN);

      let filteredEntities = entities;
      if (params.domain) {
        filteredEntities = entities.filter((e: any) =>
          e.entity_id.startsWith(`${params.domain}.`)
        );
      }

      const grouped = groupByDomain(filteredEntities);

      return formatToolCall({
        success: true,
        data: {
          total: filteredEntities.length,
          by_domain: grouped,
        },
      });
    } catch (error: any) {
      return formatToolCall({
        success: false,
        error: error.message,
      }, true);
    }
  },
});

/**
 * Tool: Control Device
 * Execute commands on Home Assistant devices
 */
server.addTool({
  name: 'control',
  description: 'Control Home Assistant devices - turn on/off, set brightness, temperature, position, etc.',
  parameters: ControlSchema,
  execute: async (params: ControlParams) => {
    try {
      const domain = params.entity_id.split('.')[0];
      let service = params.command;

      // Map commands to services
      const serviceData: any = {
        entity_id: params.entity_id,
      };

      // Add optional parameters based on command and domain
      if (params.brightness !== undefined && domain === 'light') {
        serviceData.brightness = params.brightness;
      }
      if (params.temperature !== undefined && domain === 'climate') {
        serviceData.temperature = params.temperature;
      }
      if (params.position !== undefined && domain === 'cover') {
        serviceData.position = params.position;
      }
      if (params.hvac_mode && domain === 'climate') {
        serviceData.hvac_mode = params.hvac_mode;
      }
      if (params.rgb_color && domain === 'light') {
        serviceData.rgb_color = params.rgb_color;
      }

      const result = await makeHassRequest(
        `/api/services/${domain}/${service}`,
        HASS_HOST,
        HASS_TOKEN,
        {
          method: 'POST',
          body: JSON.stringify(serviceData),
        }
      );

      return formatToolCall({
        success: true,
        data: result,
      });
    } catch (error: any) {
      return formatToolCall({
        success: false,
        error: error.message,
      }, true);
    }
  },
});

/**
 * Tool: Get History
 * Retrieve historical state data for entities
 */
server.addTool({
  name: 'get_history',
  description: 'Get historical state data for a Home Assistant entity',
  parameters: GetHistorySchema,
  execute: async (params: GetHistoryParams) => {
    try {
      let endpoint = `/api/history/period`;
      if (params.start_time) {
        endpoint += `/${params.start_time}`;
      }
      endpoint += `?filter_entity_id=${params.entity_id}`;
      if (params.end_time) {
        endpoint += `&end_time=${params.end_time}`;
      }

      const history = await makeHassRequest(endpoint, HASS_HOST, HASS_TOKEN);

      return formatToolCall({
        success: true,
        data: history,
      });
    } catch (error: any) {
      return formatToolCall({
        success: false,
        error: error.message,
      }, true);
    }
  },
});

/**
 * Tool: Automation Control
 * Control Home Assistant automations
 */
server.addTool({
  name: 'automation',
  description: 'Control Home Assistant automations - trigger, toggle, turn on/off',
  parameters: AutomationSchema,
  execute: async (params: AutomationParams) => {
    try {
      const result = await makeHassRequest(
        `/api/services/automation/${params.action}`,
        HASS_HOST,
        HASS_TOKEN,
        {
          method: 'POST',
          body: JSON.stringify({ entity_id: params.automation_id }),
        }
      );

      return formatToolCall({
        success: true,
        data: result,
      });
    } catch (error: any) {
      return formatToolCall({
        success: false,
        error: error.message,
      }, true);
    }
  },
});

/**
 * Tool: Scene Activation
 * Activate Home Assistant scenes
 */
server.addTool({
  name: 'activate_scene',
  description: 'Activate a Home Assistant scene',
  parameters: SceneSchema,
  execute: async (params: SceneParams) => {
    try {
      const result = await makeHassRequest(
        `/api/services/scene/turn_on`,
        HASS_HOST,
        HASS_TOKEN,
        {
          method: 'POST',
          body: JSON.stringify({ entity_id: params.scene_id }),
        }
      );

      return formatToolCall({
        success: true,
        data: result,
      });
    } catch (error: any) {
      return formatToolCall({
        success: false,
        error: error.message,
      }, true);
    }
  },
});

/**
 * Tool: Send Notification
 * Send notifications through Home Assistant
 */
server.addTool({
  name: 'notify',
  description: 'Send notifications through Home Assistant notification services',
  parameters: NotifySchema,
  execute: async (params: NotifyParams) => {
    try {
      const serviceData: any = {
        message: params.message,
      };
      if (params.title) {
        serviceData.title = params.title;
      }
      if (params.target) {
        serviceData.target = params.target;
      }

      const result = await makeHassRequest(
        `/api/services/notify/notify`,
        HASS_HOST,
        HASS_TOKEN,
        {
          method: 'POST',
          body: JSON.stringify(serviceData),
        }
      );

      return formatToolCall({
        success: true,
        data: result,
      });
    } catch (error: any) {
      return formatToolCall({
        success: false,
        error: error.message,
      }, true);
    }
  },
});

// Start the MCP server on stdio only (no HTTP server)
console.error(`Home Assistant MCP Server (stdio-only) starting...`);
console.error(`Connected to Home Assistant at ${HASS_HOST}`);

// Add process event handlers for debugging
process.on('exit', (code) => {
  console.error(`Process exiting with code: ${code}`);
});

process.on('SIGTERM', () => {
  console.error('Received SIGTERM');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.error('Received SIGINT');
  process.exit(0);
});

// Don't exit on stdin end - let litemcp handle it
process.stdin.on('end', () => {
  console.error('stdin ended (but not exiting)');
});

process.stdin.on('error', (err) => {
  console.error('stdin error:', err);
});

// Keep process alive even if stdin closes
process.stdin.resume();

server.start();
