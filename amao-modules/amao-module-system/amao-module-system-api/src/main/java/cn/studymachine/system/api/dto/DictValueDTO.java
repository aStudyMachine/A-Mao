package cn.studymachine.system.api.dto;

import lombok.Data;

import java.io.Serializable;

/**
 * 字典值跨域传输对象。
 *
 * <p>仅承载跨模块/跨进程契约字段，禁止携带 MyBatis 注解或持久化细节。</p>
 */
@Data
public class DictValueDTO implements Serializable {

    private static final long serialVersionUID = 1L;

    /** 字典值主键（t_sys_dict_value.id） */
    private Long id;

    /** 字典键（关联 t_sys_dict_key.dict_key） */
    private String dictKey;

    /** 字典值（与 dictKey 联合唯一） */
    private String value;
}
