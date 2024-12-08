package cn.studymachine.model;

import cn.studymachine.common.datasource.bean.BaseModel;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import lombok.experimental.Accessors;
import lombok.experimental.SuperBuilder;

/**
 * 字典key表
 */
@Data
@EqualsAndHashCode(callSuper = true)
@Accessors(chain = true)
@SuperBuilder
@NoArgsConstructor
@TableName(value = "t_sys_dict_key")
public class SysDictKeyModel extends BaseModel {
    /**
     * 字典key 唯一
     */
    @TableField(value = "dict_key")
    private String dictKey;

    /**
     * 字典名称
     */
    @TableField(value = "dict_name")
    private String dictName;

    /**
     * 状态 1:正常 0:禁用
     */
    @TableField(value = "`status`")
    private Boolean status;
}