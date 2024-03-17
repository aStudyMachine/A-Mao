package cn.studymachine.common.datasource.config;

import cn.hutool.core.util.StrUtil;
import cn.studymachine.common.datasource.bean.BaseEntity;
import com.baomidou.mybatisplus.core.handlers.MetaObjectHandler;
import lombok.extern.slf4j.Slf4j;
import org.apache.ibatis.reflection.MetaObject;
import org.springframework.util.ClassUtils;

import java.nio.charset.Charset;
import java.util.Date;

/**
 * MybatisPlus 字段自动填充策略配置
 *
 * @author wukun
 * @since 2021/11/2
 */
@Slf4j
public class MybatisPlusMetaObjectHandler implements MetaObjectHandler {


    @Override
    public void insertFill(MetaObject metaObject) {
        log.debug("mybatis plus 新增操作 , 自动填充字段....");
        Date now = new Date();
        fillValIfNullByName(BaseEntity.Fields.createTime, now, metaObject, false);
        fillValIfNullByName(BaseEntity.Fields.updateTime, now, metaObject, false);

        // todo @wukun 2024-03-17
        // fillValIfNullByName(BaseEntity.Fields.createBy, now, metaObject, false);
        // fillValIfNullByName(BaseEntity.Fields.updateBy, now, metaObject, false);

        // fillValIfNullByName(BaseEntity.Fields.deleted, 0, metaObject, false);

    }

    @Override
    public void updateFill(MetaObject metaObject) {
        log.debug("mybatis plus 更新操作 , 自动填充字段....");
        fillValIfNullByName("updateTime", new Date(), metaObject, true);
        // todo @wukun 2024-03-17
        // fillValIfNullByName(BaseEntity.Fields.updateBy, now, metaObject, false);

    }

    /**
     * 填充值，先判断是否有手动设置，优先手动设置的值，例如：job必须手动设置
     *
     * @param fieldName  属性名
     * @param fieldVal   属性值
     * @param metaObject 当前操作的数据对象
     * @param isCover    是否覆盖原有值,避免更新操作手动入参
     */
    private static void fillValIfNullByName(String fieldName, Object fieldVal, MetaObject metaObject, boolean isCover) {
        // 1. 没有 set 方法
        if (!metaObject.hasSetter(fieldName)) {
            return;
        }
        // 2. 如果用户有手动设置的值
        Object userSetValue = metaObject.getValue(fieldName);
        String setValueStr = StrUtil.str(userSetValue, Charset.defaultCharset());
        if (StrUtil.isNotBlank(setValueStr) && !isCover) {
            return;
        }
        // 3. field 类型相同时设置
        Class<?> getterType = metaObject.getGetterType(fieldName);
        if (ClassUtils.isAssignableValue(getterType, fieldVal)) {
            metaObject.setValue(fieldName, fieldVal);
        }
    }


}
