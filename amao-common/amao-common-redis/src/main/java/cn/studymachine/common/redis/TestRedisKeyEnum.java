package cn.studymachine.common.redis;

import cn.studymachine.common.redis.util.RedisUtils;
import lombok.AllArgsConstructor;
import lombok.Getter;

import java.time.Duration;

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


    public static void main(String[] args) {
        String concreteKey = TestRedisKeyEnum.TEST_KEY.getConcreteKey(1);
        RedisUtils.setCacheObject(concreteKey, "test");
        RedisUtils.setCacheObject(concreteKey, "test", Duration.ofMinutes(1));
    }
}
