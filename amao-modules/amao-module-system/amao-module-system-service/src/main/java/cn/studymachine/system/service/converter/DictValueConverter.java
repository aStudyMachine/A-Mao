package cn.studymachine.system.service.converter;

import cn.studymachine.system.api.dto.DictValueDTO;
import cn.studymachine.system.model.SysDictValueModel;
import org.mapstruct.Mapper;

import java.util.List;

/**
 * 字典值 Model ↔ DTO 对象转换（MapStruct）。
 *
 * <p>禁止手写 getter/setter 逐字段拷贝；映射缺口用 {@code @Mapping} 显式声明。</p>
 */
@Mapper(componentModel = "spring")
public interface DictValueConverter {

    /**
     * Model 转跨域 DTO。
     *
     * @param model 字典值持久化模型
     * @return 字典值 DTO；入参为 {@code null} 时返回 {@code null}
     */
    DictValueDTO toDTO(SysDictValueModel model);

    /**
     * Model 列表转 DTO 列表。
     *
     * @param models 字典值持久化模型列表
     * @return 字典值 DTO 列表；入参为 {@code null} 时返回 {@code null}
     */
    List<DictValueDTO> toDTOList(List<SysDictValueModel> models);
}
