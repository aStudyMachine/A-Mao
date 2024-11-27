package cn.studymachine.common.json.deserial;


import cn.hutool.core.util.StrUtil;
import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.databind.DeserializationContext;
import com.fasterxml.jackson.databind.JsonDeserializer;

import java.io.IOException;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;

/**
 * 多格式日期反序列化
 *
 * @author wukun
 * @since 2024/10/22
 */
public class MultiDateDeserializer extends JsonDeserializer<Date> {

    private static final SimpleDateFormat sdf1 = new SimpleDateFormat("yyyy-MM-dd");
    private static final SimpleDateFormat sdf2 = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

    @Override
    public Date deserialize(JsonParser p, DeserializationContext ctxt) throws IOException {
        String dateStr = p.getText().trim();
        if (StrUtil.isBlank(dateStr)) {
            return null;
        }
        try {
            // 尝试使用 yyyy-MM-dd 格式解析
            if (dateStr.length() == 10) {
                return sdf1.parse(dateStr);
            }
            // 否则尝试使用 yyyy-MM-dd HH:mm:ss 格式解析
            return sdf2.parse(dateStr);
        } catch (ParseException e) {
            throw new RuntimeException("无法解析日期: " + dateStr, e);
        }
    }
}