-- Sa-Token RBAC 种子数据（与 doc/DDL.sql 修订版配套）
-- 执行库：127.0.0.1:13306/a-mao
-- admin 密码明文：123456（BCrypt 哈希由 cn.hutool.crypto.digest.BCrypt.hashpw 生成）
-- 审计字段本期由种子 SQL 手工填（MetaObjectHandler 自动填充尚未覆盖 create_by 等）

SET NAMES utf8mb4;
USE `a-mao`;

-- 清理演示数据（可重复执行）
DELETE FROM t_sys_user_role WHERE user_id = 1;
DELETE FROM t_sys_role_permission WHERE role_id = 1;
DELETE FROM t_sys_permission WHERE id IN (1, 2);
DELETE FROM t_sys_role WHERE id = 1;
DELETE FROM t_sys_user WHERE id = 1;
DELETE FROM t_sys_dict_value WHERE dict_key = 'demo_status';
DELETE FROM t_sys_dict_key WHERE dict_key = 'demo_status';

-- admin 用户（显式 id=1，验证脚本可写死 /perm/1）
INSERT INTO t_sys_user (id, username, password, real_name, phone, email, status, deleted,
                        create_time, update_time, create_by, creator_name, update_by, updater_name, trace_id)
VALUES (1, 'admin', '$2a$10$XVRlw.SKKryCFwX.2r3K5OGR9VxuYyR0/oSEEKDMSVRqYZs5AIWLO',
        '超级管理员', '13800000000', 'admin@amao.local', 1, 0,
        NOW(), NOW(), 1, 'system', 1, 'system', 'seed-init-data');

-- admin 角色（role_name 即角色标识）
INSERT INTO t_sys_role (id, role_name, status,
                        create_time, update_time, create_by, creator_name, update_by, updater_name, trace_id)
VALUES (1, 'admin', 1, NOW(), NOW(), 1, 'system', 1, 'system', 'seed-init-data');

-- 权限注册（注册表只读种子；鉴权以 t_sys_role_permission.permission 为准）
INSERT INTO t_sys_permission (id, permission, name, type, parent_id, status,
                              create_time, update_time, create_by, creator_name, update_by, updater_name, trace_id)
VALUES (1, 'sys:dict:list', '字典查询', 3, 0, 1, NOW(), NOW(), 1, 'system', 1, 'system', 'seed-init-data'),
       (2, 'auth:user:info', '当前用户信息', 3, 0, 1, NOW(), NOW(), 1, 'system', 1, 'system', 'seed-init-data');

-- 用户-角色 / 角色-权限
INSERT INTO t_sys_user_role (user_id, role_id, status,
                             create_time, update_time, create_by, creator_name, update_by, updater_name, trace_id)
VALUES (1, 1, 1, NOW(), NOW(), 1, 'system', 1, 'system', 'seed-init-data');

INSERT INTO t_sys_role_permission (role_id, permission, status,
                                   create_time, update_time, create_by, creator_name, update_by, updater_name, trace_id)
VALUES (1, 'sys:dict:list', 1, NOW(), NOW(), 1, 'system', 1, 'system', 'seed-init-data'),
       (1, 'auth:user:info', 1, NOW(), NOW(), 1, 'system', 1, 'system', 'seed-init-data');

-- 字典演示数据（闭环脚本 GET /api/dict/demo_status）
INSERT INTO t_sys_dict_key (dict_key, dict_name, status,
                            create_time, update_time, create_by, creator_name, update_by, updater_name, trace_id)
VALUES ('demo_status', '演示状态', 1, NOW(), NOW(), 1, 'system', 1, 'system', 'seed-init-data');

INSERT INTO t_sys_dict_value (dict_key, `value`, `name`, status,
                              create_time, update_time, create_by, creator_name, update_by, updater_name, trace_id)
VALUES ('demo_status', '1', '启用', 1, NOW(), NOW(), 1, 'system', 1, 'system', 'seed-init-data'),
       ('demo_status', '0', '停用', 1, NOW(), NOW(), 1, 'system', 1, 'system', 'seed-init-data');
