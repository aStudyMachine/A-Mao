package cn.studymachine.common.datasource.bean;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import lombok.Data;
import lombok.experimental.Accessors;
import lombok.experimental.FieldNameConstants;

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
public class BaseEntity implements Serializable {


    private static final long serialVersionUID = 1L;

    /**
     * 主键id
     */
    @TableId(value = "id", type = IdType.ASSIGN_ID)
    private Long id;

    /**
     * 创建时间
     */
    private Date createTime;

    /**
     * 更新时间
     */
    private Date updateTime;

    /**
     * 创建人id
     */
    private Long createBy;

    /**
     * 创建人名称
     */
    private String creatorName;

    /**
     * 更新人id
     */
    private Long updateBy;

    /**
     * 更新人名称
     */
    private String updaterName;

    // 备注 : 不是所有表都需要逻辑删除 , 仅重要数据需要, 例如商品,订单等,  中间表,日志表等不需要
    //        所以不直接加在 BaseEntity 上
    // /**
    //  * The Deleted.
    //  */
    // private Integer deleted;
}
