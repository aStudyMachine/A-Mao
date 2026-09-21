package cn.studymachine.common.json.deserial;


import cn.hutool.core.date.DateTime;
import cn.hutool.core.util.StrUtil;
import tools.jackson.core.JsonParser;
import tools.jackson.databind.DeserializationContext;
import tools.jackson.databind.ValueDeserializer;

import java.util.Date;

/**
 * 多格式日期反序列化
 *
 * @author wukun
 * @since 2024/10/22
 */
public class MultiDateDeserializer extends ValueDeserializer<Date> {

    @Override
    public Date deserialize(JsonParser p, DeserializationContext ctxt) {
        String dateStr = p.getString().trim();
        if (StrUtil.isBlank(dateStr)) {
            return null;
        }
        // hutool date time 构造方法默认兼容了多种格式的日期字符串
        DateTime dateTime = new DateTime(dateStr);
        return dateTime.toJdkDate();
    }
}
