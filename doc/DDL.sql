# 系统用户表
################################################ t_sys_user ################################################
CREATE TABLE t_sys_user
(
    `id`          bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'id',
    `username`    varchar(50)         NOT NULL COMMENT '用户名',
    `password`    varchar(50)         NOT NULL COMMENT '密码',
    `real_name`   varchar(50)         NOT NULL COMMENT '真实姓名',
    `phone`       varchar(20)         NOT NULL COMMENT '手机号',
    `email`       varchar(50)         NOT NULL COMMENT '邮箱',
    `status`      tinyint(1)          NOT NULL DEFAULT 1 COMMENT '状态 1:正常 0:禁用',
    `create_time` datetime            NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` datetime            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted`     tinyint(1)          NOT NULL DEFAULT 0 COMMENT '删除状态 1:已删除 0:未删除',
    PRIMARY KEY (id),
    UNIQUE KEY `username` (`username`),
    UNIQUE KEY `phone` (`phone`),
    UNIQUE KEY `email` (`email`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci COMMENT ='系统用户表';


# 字典 key 表
################################################ t_sys_dict ################################################
CREATE TABLE t_sys_dict_key
(
    `id`          bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'id',
    `dict_key`    varchar(50)         NOT NULL COMMENT '字典key 唯一',
    `dict_name`   varchar(50)         NOT NULL COMMENT '字典名称',
    `status`      tinyint(1)          NOT NULL DEFAULT 1 COMMENT '状态 1:正常 0:禁用',
    `create_time` datetime            NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` datetime            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (id),
    UNIQUE KEY `dict_key` (`dict_key`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci COMMENT ='字典key表';


# 字典 value 表
################################################ t_sys_dict_value ################################################
CREATE TABLE t_sys_dict_value
(
    `id`          bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'id',
    `dict_key`    varchar(50)         NOT NULL COMMENT '关联的字典key',
    `value`       varchar(50)         NOT NULL COMMENT '字典value 字典key关联 value 唯一',
    `name`        varchar(50)         NOT NULL COMMENT '字典值名称',
    `status`      tinyint(1)          NOT NULL DEFAULT 1 COMMENT '状态 1:正常 0:禁用',
    `create_time` datetime            NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` datetime            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (id),
    UNIQUE KEY `dict_key_value` (`dict_key`, `value`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci COMMENT ='字典value表';



# 基于RBAC 的权限管理

# 角色表
################################################ t_sys_role ################################################
CREATE TABLE t_sys_role
(
    `id`          bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'id',
    `role_name`   varchar(50)         NOT NULL COMMENT '角色名称',
    `status`      tinyint(1)          NOT NULL DEFAULT 1 COMMENT '状态 1:正常 0:禁用',
    `create_time` datetime            NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` datetime            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (id),
    UNIQUE KEY `role_name` (`role_name`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci COMMENT ='角色表';


# 用户角色关联表
################################################ t_sys_user_role ################################################
CREATE TABLE t_sys_user_role
(
    `id`          bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'id',
    `user_id`     bigint(20) UNSIGNED NOT NULL COMMENT '用户id',
    `role_id`     bigint(20) UNSIGNED NOT NULL COMMENT '角色id',
    `status`      tinyint(1)          NOT NULL DEFAULT 1 COMMENT '状态 1:正常 0:禁用',
    `create_time` datetime            NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` datetime            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (id),
    UNIQUE KEY `user_id_role_id` (`user_id`, `role_id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci COMMENT ='用户角色关联表';


# 角色权限关联表
################################################ t_sys_role_permission ################################################
CREATE TABLE t_sys_role_permission
(
    `id`          bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'id',
    `role_id`     bigint(20) UNSIGNED NOT NULL COMMENT '角色id',
    `permission`  varchar(50)         NOT NULL COMMENT '权限标识',
    `status`      tinyint(1)          NOT NULL DEFAULT 1 COMMENT '状态 1:正常 0:禁用',
    `create_time` datetime            NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` datetime            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (id),
    UNIQUE KEY `role_id_permission` (`role_id`, `permission`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci COMMENT ='角色权限关联表';


# 权限表
################################################ t_sys_permission ################################################
CREATE TABLE t_sys_permission
(
    `id`          bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'id',
    `permission`  varchar(50)         NOT NULL COMMENT '权限标识',
    `name`        varchar(50)         NOT NULL COMMENT '权限名称',
    `type`        tinyint(1)          NOT NULL DEFAULT 1 COMMENT '权限类型 1:菜单 2:按钮 3:接口',
    `parent_id`   bigint(20) UNSIGNED NOT NULL DEFAULT 0 COMMENT '父级权限id',
    `status`      tinyint(1)          NOT NULL DEFAULT 1 COMMENT '状态 1:正常 0:禁用',
    `create_time` datetime            NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` datetime            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (id),
    UNIQUE KEY `permission` (`permission`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci COMMENT ='权限表';



