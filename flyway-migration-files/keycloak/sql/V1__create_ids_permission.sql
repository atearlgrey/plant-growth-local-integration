-- ==========================================================
--  V1__create_ids_schema.sql
--  Author: System Architect
--  Description:
--     Schema định nghĩa hệ thống phân quyền IDS:
--     Realm → Client → Function → Resource/Menu → Permission
-- ==========================================================

-- ==========================================================
-- Cleanup (optional for re-run)
-- ==========================================================
DROP TABLE IF EXISTS ids_permission CASCADE;
DROP TABLE IF EXISTS ids_system_menu CASCADE;
DROP TABLE IF EXISTS ids_resource CASCADE;
DROP TABLE IF EXISTS ids_function CASCADE;

-- ==========================================================
-- 1️⃣ Table: ids_function
-- ==========================================================
CREATE TABLE ids_function (
    function_code     VARCHAR(100) PRIMARY KEY,
    client_id         VARCHAR(100) NOT NULL,
    title             VARCHAR(255) NOT NULL,
    description       VARCHAR(500),
    parent_code       VARCHAR(100),
    ord               INT DEFAULT 0,
    is_enabled        BOOLEAN DEFAULT TRUE,
    created_date      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by        VARCHAR(100),
    updated_date      TIMESTAMP,
    updated_by        VARCHAR(100),

    CONSTRAINT fk_ids_function_parent
        FOREIGN KEY (parent_code)
        REFERENCES ids_function(function_code)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

CREATE INDEX idx_ids_function_client ON ids_function (client_id);
CREATE INDEX idx_ids_function_parent ON ids_function (parent_code);

COMMENT ON TABLE ids_function IS 'Định nghĩa các chức năng (function/module) thuộc từng client.';
COMMENT ON COLUMN ids_function.client_id IS 'Client (ứng dụng) mà function thuộc về.';


-- ==========================================================
-- 2️⃣ Table: ids_resource
-- ==========================================================
CREATE TABLE ids_resource (
    resource_code     VARCHAR(100) PRIMARY KEY,
    function_code     VARCHAR(100) NOT NULL,
    title             VARCHAR(255) NOT NULL,
    description       VARCHAR(500),
    path              VARCHAR(500) NOT NULL,
    http_method       VARCHAR(20) DEFAULT 'GET',
    scope             VARCHAR(100),
    ord               INT DEFAULT 0,
    is_enabled        BOOLEAN DEFAULT TRUE,
    created_date      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by        VARCHAR(100),
    updated_date      TIMESTAMP,
    updated_by        VARCHAR(100),

    CONSTRAINT fk_ids_resource_function
        FOREIGN KEY (function_code)
        REFERENCES ids_function(function_code)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE INDEX idx_ids_resource_function ON ids_resource (function_code);
CREATE INDEX idx_ids_resource_enabled ON ids_resource (is_enabled);

COMMENT ON TABLE ids_resource IS 'Định nghĩa các API Resource thuộc function.';
COMMENT ON COLUMN ids_resource.path IS 'Endpoint hoặc route pattern.';
COMMENT ON COLUMN ids_resource.http_method IS 'HTTP method (GET, POST, PUT, DELETE, v.v.).';


-- ==========================================================
-- 3️⃣ Table: ids_system_menu
-- ==========================================================
CREATE TABLE ids_system_menu (
    system_menu_code  VARCHAR(100) PRIMARY KEY,
    function_code     VARCHAR(100) NOT NULL,
    title             VARCHAR(255) NOT NULL,
    description       VARCHAR(500),
    icon              VARCHAR(100),
    path              VARCHAR(255),
    resource_code     VARCHAR(100),
    parent_code       VARCHAR(100),
    menu_level        SMALLINT DEFAULT 1,
    ord               INT DEFAULT 0,
    is_public         BOOLEAN DEFAULT FALSE,
    is_enabled        BOOLEAN DEFAULT TRUE,
    created_date      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by        VARCHAR(100),
    updated_date      TIMESTAMP,
    updated_by        VARCHAR(100),

    CONSTRAINT fk_ids_menu_function
        FOREIGN KEY (function_code)
        REFERENCES ids_function(function_code)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_ids_menu_resource
        FOREIGN KEY (resource_code)
        REFERENCES ids_resource(resource_code)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_ids_menu_parent
        FOREIGN KEY (parent_code)
        REFERENCES ids_system_menu(system_menu_code)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

CREATE INDEX idx_ids_menu_function ON ids_system_menu (function_code);
CREATE INDEX idx_ids_menu_parent ON ids_system_menu (parent_code);
CREATE INDEX idx_ids_menu_enabled ON ids_system_menu (is_enabled);

COMMENT ON TABLE ids_system_menu IS 'Định nghĩa menu hệ thống (UI) thuộc function.';
COMMENT ON COLUMN ids_system_menu.path IS 'FE route path của menu.';


-- ==========================================================
-- 4️⃣ Table: ids_permission
-- ==========================================================
CREATE TABLE ids_permission (
    permission_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    function_code      VARCHAR(100) NOT NULL,
    resource_code      VARCHAR(100),
    system_menu_code   VARCHAR(100),
    role_id            VARCHAR(36) NOT NULL,
    expired_date       TIMESTAMP,
    is_enabled         BOOLEAN DEFAULT TRUE,
    created_date       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by         VARCHAR(100),
    updated_date       TIMESTAMP,
    updated_by         VARCHAR(100),

    CONSTRAINT fk_ids_permission_function
        FOREIGN KEY (function_code)
        REFERENCES ids_function(function_code)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_ids_permission_resource
        FOREIGN KEY (resource_code)
        REFERENCES ids_resource(resource_code)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_ids_permission_menu
        FOREIGN KEY (system_menu_code)
        REFERENCES ids_system_menu(system_menu_code)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

CREATE INDEX idx_ids_permission_function ON ids_permission (function_code);
CREATE INDEX idx_ids_permission_resource ON ids_permission (resource_code);
CREATE INDEX idx_ids_permission_menu ON ids_permission (system_menu_code);
CREATE INDEX idx_ids_permission_role ON ids_permission (role_id);
CREATE INDEX idx_ids_permission_enabled ON ids_permission (is_enabled);

COMMENT ON TABLE ids_permission IS
'Mapping giữa Role và Function/Resource/Menu. Nếu là API → resource_code != NULL; nếu là UI menu → system_menu_code != NULL.';


-- ==========================================================
-- ✅ Done
-- ==========================================================

DROP VIEW IF EXISTS view_ids_user_permissions;
CREATE VIEW view_ids_user_permissions AS
SELECT DISTINCT ON (urm.user_id, r.resource_code)
  urm.user_id,
  kr.id AS role_id,
  kr.name AS role_name,
  f.client_id,
  f.function_code,
  f.title AS function_name,
  r.resource_code,
  r.title AS resource_title,
  r.path AS resource_path,
  r.http_method,
  p.permission_id::text,
  p.expired_date,
  p.is_enabled AS permission_enabled
FROM user_role_mapping urm
JOIN keycloak_role kr ON kr.id::text = urm.role_id::text
JOIN ids_permission p ON p.role_id::uuid = kr.id::uuid AND p.is_enabled = TRUE
JOIN ids_function f ON f.function_code = p.function_code AND f.is_enabled = TRUE
JOIN ids_resource r ON r.resource_code = p.resource_code AND r.is_enabled = TRUE
WHERE (p.expired_date IS NULL OR p.expired_date >= NOW())
ORDER BY 
  urm.user_id, 
  r.resource_code, 
  p.updated_date DESC NULLS LAST;

DROP VIEW IF EXISTS view_ids_user_menus;
CREATE VIEW view_ids_user_menus AS
SELECT DISTINCT ON (urm.user_id, m.system_menu_code)
  urm.user_id,
  kr.id AS role_id,
  kr.name AS role_name,
  f.client_id,
  f.function_code,
  f.title AS function_name,
  m.system_menu_code,
  m.title AS menu_title,
  m.path AS menu_path,
  m.icon AS menu_icon,
  m.parent_code AS menu_parent_code,
  m.menu_level,
  p.permission_id::text,
  p.expired_date,
  p.is_enabled AS permission_enabled
FROM user_role_mapping urm
JOIN keycloak_role kr ON kr.id::text = urm.role_id::text
JOIN ids_permission p ON p.role_id::uuid = kr.id::uuid AND p.is_enabled = TRUE
JOIN ids_function f ON f.function_code = p.function_code AND f.is_enabled = TRUE
JOIN ids_system_menu m ON m.system_menu_code = p.system_menu_code AND m.is_enabled = TRUE
WHERE (p.expired_date IS NULL OR p.expired_date >= NOW())
ORDER BY 
  urm.user_id, 
  m.system_menu_code, 
  p.updated_date DESC NULLS LAST;
