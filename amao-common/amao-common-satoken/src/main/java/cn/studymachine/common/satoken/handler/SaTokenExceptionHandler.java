package cn.studymachine.common.satoken.handler;

import cn.dev33.satoken.exception.NotLoginException;
import cn.dev33.satoken.exception.NotPermissionException;
import cn.dev33.satoken.exception.NotRoleException;
import cn.dev33.satoken.exception.SaTokenException;
import cn.studymachine.common.web.Result;
import cn.studymachine.common.web.ResultCode;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * Sa-Token 异常统一映射为 Result（HTTP 200 + body.code）。
 *
 * <p>精确类型优先于 GlobalExceptionHandler 的 Exception 兜底。</p>
 */
@Slf4j
@RestControllerAdvice
public class SaTokenExceptionHandler {

    @ExceptionHandler(NotLoginException.class)
    public Result<Void> handleError(NotLoginException e) {
        log.warn("未登录: type={} message={}", e.getType(), e.getMessage());
        return Result.fail(ResultCode.UN_AUTHORIZED, "请求未授权");
    }

    @ExceptionHandler(NotPermissionException.class)
    public Result<Void> handleError(NotPermissionException e) {
        log.warn("无权限: code={} message={}", e.getCode(), e.getMessage());
        return Result.fail(ResultCode.REQ_REJECT, "请求被拒绝");
    }

    @ExceptionHandler(NotRoleException.class)
    public Result<Void> handleError(NotRoleException e) {
        log.warn("无角色: code={} message={}", e.getCode(), e.getMessage());
        return Result.fail(ResultCode.REQ_REJECT, "请求被拒绝");
    }

    @ExceptionHandler(SaTokenException.class)
    public Result<Void> handleError(SaTokenException e) {
        log.error("Sa-Token异常:{}", e.getMessage());
        return Result.fail(ResultCode.FAILURE, e.getMessage());
    }
}
