package cn.studymachine.common.bean.page;

import lombok.Data;
import lombok.experimental.Accessors;

import javax.validation.constraints.Min;
import java.io.Serializable;

/**
 * 通用分页查询对象
 *
 * @param <T> the type parameter
 * @author wukun
 * @since 2023 /12/27
 */
@Data
@Accessors(chain = true)
public class BasePageQuery<T> implements Serializable {

    /**
     * The constant serialVersionUID.
     */
    private static final long serialVersionUID = 1L;

    /**
     * 当前页 (第一页从1开始, 默认:1)
     */
    @Min(value = 1L, message = "当前页号必须大于等于1")
    private Long current = 1L;

    /**
     * 页大小  (默认:10)
     */
    @Min(value = 1L, message = "页大小必须大于等于1")
    private Long size = 10L;

    /**
     * 查询参数对象
     */
    private T params;
}
