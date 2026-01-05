/**
 * Helper functions for the Home Assistant MCP Server
 */

export const formatToolCall = (obj: any, isError: boolean = false) => {
  return {
    content: [{ type: "text", text: JSON.stringify(obj, null, 2), isError }],
  };
};

/**
 * Make API request to Home Assistant
 */
export async function makeHassRequest(
  endpoint: string,
  hassHost: string,
  hassToken: string,
  options: RequestInit = {}
): Promise<any> {
  const url = `${hassHost}${endpoint}`;

  const headers = {
    'Authorization': `Bearer ${hassToken}`,
    'Content-Type': 'application/json',
    ...options.headers,
  };

  const response = await fetch(url, {
    ...options,
    headers,
  });

  if (!response.ok) {
    throw new Error(`Home Assistant API error: ${response.status} ${response.statusText}`);
  }

  return response.json();
}

/**
 * Group entities by domain
 */
export function groupByDomain(entities: any[]): Record<string, any[]> {
  const grouped: Record<string, any[]> = {};

  for (const entity of entities) {
    const domain = entity.entity_id.split('.')[0];
    if (!grouped[domain]) {
      grouped[domain] = [];
    }
    grouped[domain].push(entity);
  }

  return grouped;
}

/**
 * Validate environment variables
 */
export function validateEnv() {
  const required = ['HASS_HOST', 'HASS_TOKEN'];
  const missing = required.filter(key => !process.env[key]);

  if (missing.length > 0) {
    throw new Error(`Missing required environment variables: ${missing.join(', ')}`);
  }
}
