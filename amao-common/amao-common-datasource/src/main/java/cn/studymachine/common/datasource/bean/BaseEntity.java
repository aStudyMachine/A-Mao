package cn.studymachine.common.datasource.bean;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import lombok.Data;
import lombok.experimental.Accessors;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 数据库实体类父类
 *
 * @author wukun
 * @since 2024 /3/12
 */
@Data
@Accessors(chain = true)
public class BaseEntity implements Serializable {

    /**
     * The constant serialVersionUID.
     */
    private static final long serialVersionUID = 1L;

    /**
     * The Id.
     */
    @TableId(value = "id", type = IdType.ASSIGN_ID)
    private Long id;

    /**
     * The Create time.
     */
    private LocalDateTime createTime;

    /**
     * The Update time.
     */
    private LocalDateTime updateTime;

    /**
     * The Create by.
     */
    private Long createBy;

    /**
     * The Update by.
     */
    private Long updateBy;

    /**
     * The Deleted.
     */
    private Integer deleted;
}
