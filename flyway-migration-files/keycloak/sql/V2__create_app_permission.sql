CREATE TABLE app_permission (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NULL,
  resource_id UUID NOT NULL REFERENCES app_resource(id) ON DELETE CASCADE,
  role_id UUID NOT NULL,
  -- role lấy từ Keycloak
  action VARCHAR(50) NOT NULL,
  -- read | view | edit | delete | access ...
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  active BOOLEAN DEFAULT TRUE,
  UNIQUE(role_id, resource_id, action)
);