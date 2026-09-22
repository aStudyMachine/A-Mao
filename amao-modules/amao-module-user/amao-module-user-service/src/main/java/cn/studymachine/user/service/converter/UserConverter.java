package cn.studymachine.user.service.converter;

import cn.studymachine.user.api.dto.UserDTO;
import cn.studymachine.user.model.SysUserModel;
import org.mapstruct.Mapper;

/**
 * 用户 Model ↔ DTO 对象转换（MapStruct）。
 *
 * <p>禁止手写 getter/setter 逐字段拷贝；映射缺口用 {@code @Mapping} 显式声明。</p>
 */
@Mapper(componentModel = "spring")
public interface UserConverter {

    /**
     * Model 转跨域 DTO。
     *
     * @param model 用户持久化模型
     * @return 用户 DTO；入参为 {@code null} 时返回 {@code null}
     */
    UserDTO toDTO(SysUserModel model);
}
