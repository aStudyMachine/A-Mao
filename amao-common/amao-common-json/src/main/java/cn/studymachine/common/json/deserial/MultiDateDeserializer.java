package cn.studymachine.common.json.deserial;


import cn.hutool.core.date.DateTime;
import cn.hutool.core.util.StrUtil;
import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.databind.DeserializationContext;
import com.fasterxml.jackson.databind.JsonDeserializer;

import java.io.IOException;
import java.util.Date;

/**
 * 多格式日期反序列化
 *
 * @author wukun
 * @since 2024/10/22
 */
public class MultiDateDeserializer extends JsonDeserializer<Date> {

    @Override
    public Date deserialize(JsonParser p, DeserializationContext ctxt) throws IOException {
        String dateStr = p.getText().trim();
        if (StrUtil.isBlank(dateStr)) {
            return null;
        }
        // hutool date time 构造方法默认兼容了多种格式的日期字符串
        DateTime dateTime = new DateTime(dateStr);
        return dateTime.toJdkDate();
    }
}