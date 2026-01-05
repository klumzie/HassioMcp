/**
 * Zod schemas for request/response validation
 */
import { z } from 'zod';

export const DomainSchema = z.enum([
  'light',
  'climate',
  'alarm_control_panel',
  'cover',
  'switch',
  'contact',
  'media_player',
  'fan',
  'lock',
  'vacuum',
  'scene',
  'script',
  'camera',
]);

export const ControlCommandSchema = z.enum([
  'turn_on',
  'turn_off',
  'toggle',
  'set_position',
  'open_cover',
  'close_cover',
  'set_temperature',
]);

export const ControlSchema = z.object({
  entity_id: z.string().describe('The entity ID to control (e.g., light.living_room)'),
  command: ControlCommandSchema.describe('The command to execute'),
  brightness: z.number().min(0).max(255).optional().describe('Brightness level (0-255) for lights'),
  temperature: z.number().optional().describe('Temperature setting for climate devices'),
  position: z.number().min(0).max(100).optional().describe('Position percentage (0-100) for covers'),
  hvac_mode: z.string().optional().describe('HVAC mode for climate devices'),
  rgb_color: z.array(z.number()).length(3).optional().describe('RGB color as [r, g, b] array'),
});

export const ListDevicesSchema = z.object({
  domain: DomainSchema.optional().describe('Filter by specific domain (e.g., light, switch)'),
});

export const GetHistorySchema = z.object({
  entity_id: z.string().describe('Entity ID to get history for'),
  start_time: z.string().optional().describe('Start time in ISO format'),
  end_time: z.string().optional().describe('End time in ISO format'),
});

export const AutomationSchema = z.object({
  automation_id: z.string().describe('Automation entity ID'),
  action: z.enum(['trigger', 'toggle', 'turn_on', 'turn_off']).describe('Action to perform'),
});

export const SceneSchema = z.object({
  scene_id: z.string().describe('Scene entity ID to activate'),
});

export const NotifySchema = z.object({
  message: z.string().describe('Notification message'),
  title: z.string().optional().describe('Notification title'),
  target: z.string().optional().describe('Notification target/device'),
});

export type ControlParams = z.infer<typeof ControlSchema>;
export type ListDevicesParams = z.infer<typeof ListDevicesSchema>;
export type GetHistoryParams = z.infer<typeof GetHistorySchema>;
export type AutomationParams = z.infer<typeof AutomationSchema>;
export type SceneParams = z.infer<typeof SceneSchema>;
export type NotifyParams = z.infer<typeof NotifySchema>;
