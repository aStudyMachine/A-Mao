package cn.studymachine.common.core.enums;

/**
 * <pre>
 * POJO对象枚举类通用接口 (原则上所有POJO对象中出现的枚举字段, 枚举类都要实现该接口)
 * 注意: 该接口仅适用于 POJO 枚举类, 一些开发内部定义的枚举类, 不一定需要适配该接口
 *
 * 强制所有枚举类 都有 `value` 和 `desc` 两个属性.
 * - 方便后续所有序列化与反序列化场景, 统一处理枚举
 * - 无侵入文档(yapi, apifox)可以统一配置枚举类渲染规则
 *
 * @author wukun
 * @since 2024 /2/1
 */
public interface IPOJOEnum {

    /**
     * 枚举值
     *
     * @return the value
     */
    Integer getCode();

    /**
     * 枚举名
     *
     * @return the desc
     */
    String getName();


    /**
     * code to enum  通用方法
     *
     * @param <T>       the type parameter
     * @param enumClazz the enum clazz
     * @param code      the code
     * @return the t
     */
    static <T extends IPOJOEnum> T codeToEnum(Class<T> enumClazz, Integer code) {
        if (code == null) {
            return null;
        }

        for (T element : enumClazz.getEnumConstants()) {
            if (element.getCode().equals(code)) {
                return element;
            }
        }

        throw new IllegalArgumentException(String.format("转换枚举值:[%s] 为 [%s] 枚举异常.", code,
                enumClazz.getName()));
    }
}
