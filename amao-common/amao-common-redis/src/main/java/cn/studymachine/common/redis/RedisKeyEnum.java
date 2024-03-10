package cn.studymachine.common.redis;

import cn.hutool.core.util.StrUtil;
import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * RedisKeyEnum
 *
 * @author wukun
 * @since 2024/3/10
 */
@AllArgsConstructor
@Getter
public enum RedisKeyEnum implements IRedisKey {

    TEST_KEY("test:{}", "测试redis key", -1L),
    ;


    private final String name;
    private final String keyPattern;
    private final long expiredTime;


    @Override
    public String getConcreteKey(Object... args) {
        return StrUtil.format(getKeyPattern(), args);
    }

}
