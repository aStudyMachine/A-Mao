package cn.studymachine.common.datasource.bean;

import com.baomidou.mybatisplus.annotation.FieldFill;
import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import lombok.Data;
import lombok.experimental.Accessors;
import lombok.experimental.FieldNameConstants;

import java.io.Serial;
import java.io.Serializable;
import java.util.Date;

/**
 * 数据库实体类父类
 *
 * @author wukun
 * @since 2024 /3/12
 */
@Data
@Accessors(chain = true)
@FieldNameConstants
public class BaseModel implements Serializable {


    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 主键id
     */
    @TableId(value = "id", type = IdType.ASSIGN_ID)
    private Long id;

    /**
     * 创建时间
     */
    @TableField(value = "create_time", fill = FieldFill.INSERT)
    private Date createTime;

    /**
     * 更新时间
     */
    @TableField(value = "update_time", fill = FieldFill.INSERT_UPDATE)
    private Date updateTime;

    /**
     * 创建人id
     */
    @TableField(value = "create_by", fill = FieldFill.INSERT)
    private Long createBy;

    /**
     * 创建人名称
     */
    @TableField(value = "creator_name", fill = FieldFill.INSERT)
    private String creatorName;

    /**
     * 更新人id
     */
    @TableField(value = "update_by", fill = FieldFill.INSERT_UPDATE)
    private Long updateBy;

    /**
     * 更新人名称
     */
    @TableField(value = "updater_name", fill = FieldFill.INSERT_UPDATE)
    private String updaterName;

    /**
     * traceId
     * 最近一次操作的traceId , 用于链路追踪
     */
    @TableField(value = "trace_id", fill = FieldFill.INSERT_UPDATE)
    private String traceId;

    // 备注 : 不是所有表都需要逻辑删除 , 仅重要数据需要, 例如商品,订单等,  中间表,日志表等不需要
    //        所以不直接加在 BaseModel 上
    // /**
    //  * The Deleted.
    //  */
    // private Integer deleted;

}
