package cn.studymachine.common.web.config;

import cn.hutool.core.exceptions.ExceptionUtil;
import cn.studymachine.common.web.Result;
import cn.studymachine.common.web.ResultCode;
import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.validation.BindException;
import org.springframework.validation.BindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.servlet.NoHandlerFoundException;

/**
 * @author wukun
 * @since 2023/12/25
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    /*---------------------------------------------- Fields ~ ----------------------------------------------*/


    /*---------------------------------------------- Methods ~ ----------------------------------------------*/

    @ExceptionHandler(MissingServletRequestParameterException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public Result<Void> handleError(MissingServletRequestParameterException e, HttpServletRequest request) {
        log.error("缺少请求参数, msg:{}  请求uri:{}", e.getMessage(), request.getRequestURI());
        String message = String.format("缺少必要的请求参数: %s", e.getParameterName());
        return Result.fail(ResultCode.PARAM_MISS, message);
    }

    @ExceptionHandler({MethodArgumentTypeMismatchException.class,})
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public Result<Void> handleError(MethodArgumentTypeMismatchException e, HttpServletRequest request) {
        log.error("请求参数格式错误, msg:{} , 请求uri:{}", e.getMessage(), request.getRequestURI());
        String message = String.format("请求参数格式错误: %s", e.getName());
        return Result.fail(ResultCode.PARAM_TYPE_ERROR, message);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public Result<Void> handleError(MethodArgumentNotValidException e, HttpServletRequest request) {
        log.error("参数验证失败, msg:{} 请求uri:{}", e.getMessage(), request.getRequestURI());
        return handleError(e.getBindingResult());
    }

    @ExceptionHandler(BindException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public Result<Void> handleError(BindException e, HttpServletRequest request) {
        log.error("参数绑定失败, msg:{} 请求uri:{}", e.getMessage(), request.getRequestURI());
        return handleError(e.getBindingResult());
    }

    private Result<Void> handleError(BindingResult result) {
        FieldError error = result.getFieldError();
        String message = String.format("%s:%s", error.getField(), error.getDefaultMessage());
        return Result.fail(ResultCode.PARAM_BIND_ERROR, message);
    }

    @ExceptionHandler(NoHandlerFoundException.class)
    @ResponseStatus(HttpStatus.NOT_FOUND)
    public Result<Void> handleError(NoHandlerFoundException e, HttpServletRequest request) {
        log.error("404没找到请求:{} 请求uri:{}", e.getMessage(), request.getRequestURI());
        return Result.fail(ResultCode.NOT_FOUND, e.getMessage());
    }

    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    @ResponseStatus(HttpStatus.METHOD_NOT_ALLOWED)
    public Result<Void> handleError(HttpRequestMethodNotSupportedException e, HttpServletRequest request) {
        log.error("不支持当前请求方法:{} 请求uri:{}", e.getMessage(), request.getRequestURI());
        return Result.fail(ResultCode.METHOD_NOT_SUPPORTED, e.getMessage());
    }


    @ExceptionHandler(Exception.class)
    @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
    public Result<Void> handleError(Exception e) {
        log.error("未定义服务器异常:{}", e.getMessage(), ExceptionUtil.getRootCause(e));
        return Result.fail(ResultCode.INTERNAL_SERVER_ERROR);
    }

}
