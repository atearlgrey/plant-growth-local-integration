CREATE OR REPLACE VIEW view_user_permissions AS
SELECT
  urm.user_id                AS user_id,
  kr.id                      AS role_id,
  kr.name                    AS role_name,
  ap.client_id::text		 AS client_id,
  ar.id::text                AS resource_id,
  ar.code                    AS resource_code,
  ar.name                    AS resource_name,
  ar.type                    AS resource_type,   -- e.g. menu, api, button
  ar.path                    AS resource_path,
  ar.icon                    AS resource_icon,
  ar.parent_id::text         AS resource_parent_id,
  ar.visible                 AS resource_visible,
  ar.sort_order              AS resource_sort_order,
  ap.action                  AS permission_action,
  ap.active                  AS permission_active
FROM
    user_role_mapping urm
JOIN
    keycloak_role kr ON kr.id = urm.role_id
JOIN
    app_permission ap ON ap.role_id = kr.id::uuid
JOIN
    app_resource ar ON ar.id = ap.resource_id
WHERE
    ap.active = true
    AND ar.active = true;
