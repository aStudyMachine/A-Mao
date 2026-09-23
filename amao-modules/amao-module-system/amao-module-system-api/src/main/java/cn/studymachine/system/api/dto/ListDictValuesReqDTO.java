package cn.studymachine.system.api.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.io.Serializable;

/**
 * 字典值列表查询请求。
 *
 * <p>对应接口 {@code POST /api/dict/listDictValues}；参数走请求体，不用路径变量。</p>
 */
@Data
public class ListDictValuesReqDTO implements Serializable {

    private static final long serialVersionUID = 1L;

    /** 字典键（t_sys_dict_key.dict_key），不得为空 */
    @NotBlank(message = "字典键不能为空")
    private String dictKey;
}
