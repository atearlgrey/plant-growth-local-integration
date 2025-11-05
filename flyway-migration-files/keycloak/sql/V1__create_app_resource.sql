CREATE TABLE app_resource (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL,
  parent_id UUID REFERENCES app_resource(id) ON DELETE SET NULL,
  -- chính là client.id trong Keycloak
  code VARCHAR(100) NOT NULL,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(50) NOT NULL,
  description TEXT,
  path VARCHAR(255),
  icon VARCHAR(100),
  visible BOOLEAN DEFAULT TRUE,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  active BOOLEAN DEFAULT TRUE,
  UNIQUE(client_id, code)
);