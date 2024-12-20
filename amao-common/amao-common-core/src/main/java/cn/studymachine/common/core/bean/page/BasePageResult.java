package cn.studymachine.common.core.bean.page;

import lombok.Data;
import lombok.experimental.Accessors;

import java.io.Serial;
import java.io.Serializable;
import java.util.Collections;
import java.util.List;

/**
 * 通用分页查询结果集
 *
 * @param <T> the type parameter
 * @author wukun
 * @since 2023 /12/27
 */
@Data
@Accessors(chain = true)
public class BasePageResult<T> implements Serializable {

    /**
     * The constant serialVersionUID.
     */
    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 当前页 (默认1, 页号从1开始)
     */
    private Long current = 1L;

    /**
     * 页大小 (默认10)
     */
    private Long size = 10L;

    /**
     * 总数
     */
    private Long total;

    /**
     * 分页数据
     */
    private List<T> records = Collections.emptyList();


}
