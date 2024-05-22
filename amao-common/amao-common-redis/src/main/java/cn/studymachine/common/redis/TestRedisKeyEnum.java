package cn.studymachine.common.redis;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * TestRedisKeyEnum
 *
 * @author wukun
 * @since 2024/3/10
 */
@AllArgsConstructor
@Getter
public enum TestRedisKeyEnum implements IRedisKey {

    TEST_KEY("测试redis key", "test:{}", -1L),
    ;


    private final String name;
    private final String keyPattern;
    private final long expiredTime;


}
