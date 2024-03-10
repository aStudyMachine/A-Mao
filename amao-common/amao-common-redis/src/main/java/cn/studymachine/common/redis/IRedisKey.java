package cn.studymachine.common.redis;

/**
 * The interface Redis key.
 *
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
     * redis key 模板字符串 , 包含 `{}` 占位符
     *
     * @return the complete key
     */
    String getKeyPattern();

    /**
     * 获取具体的的key (格式化之后的key)
     *
     * @param args the args
     * @return the complete key
     */
    String getConcreteKey(Object... args);

    /**
     * 该key的过期时间, 单位:ms , -1:表示永不过期
     *
     * @return the expired time
     */
    long getExpiredTime();

}
