package cn.studymachine.user.service;

import cn.hutool.v7.crypto.digest.BCrypt;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * BCrypt 口令校验正反例。
 */
class BCryptTest {

    @Test
    void checkpw_success() {
        String hash = BCrypt.hashpw("123456");
        assertTrue(BCrypt.checkpw("123456", hash));
    }

    @Test
    void checkpw_wrongPassword() {
        String hash = BCrypt.hashpw("123456");
        assertFalse(BCrypt.checkpw("654321", hash));
    }

    @Test
    void hashpw_notPlainText() {
        String hash = BCrypt.hashpw("123456");
        assertFalse("123456".equals(hash));
        assertTrue(hash.length() >= 60);
    }
}
