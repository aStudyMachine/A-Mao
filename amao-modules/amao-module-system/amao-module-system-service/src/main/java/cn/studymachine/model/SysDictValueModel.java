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
 * 字典value表
 */
@Data
@EqualsAndHashCode(callSuper = true)
@Accessors(chain = true)
@SuperBuilder
@NoArgsConstructor
@TableName(value = "t_sys_dict_value")
public class SysDictValueModel extends BaseModel {
    /**
     * 关联的字典key
     */
    @TableField(value = "dict_key")
    private String dictKey;

    /**
     * 字典value 字典key关联 value 唯一
     */
    @TableField(value = "`value`")
    private String value;

    /**
     * 字典值名称
     */
    @TableField(value = "`name`")
    private String name;

    /**
     * 状态 1:正常 0:禁用
     */
    @TableField(value = "`status`")
    private Boolean status;
}