package cn.studymachine.common.redis;

/**
 * The interface Redis key.
 * @author wukun
 * @since 2024 /3/6
 */
public interface IRedisKey {

    /**
     * key名, 相当于key的描述
     *
     * @return the name
     */
    String getName();

    /**
     * 获取格式化前的key, 包含{} 占位符
     *
     * @return the complete key
     */
    String getFormat();

    /**
     * 获取完整的key
     * @param args the args
     * @return the complete key
     */
    String getCompleteKey(Object... args);

    /**
     * 该key的过期时间, 单位:ms
     * @return the expire time
     */
    long getExpireTime();

}
