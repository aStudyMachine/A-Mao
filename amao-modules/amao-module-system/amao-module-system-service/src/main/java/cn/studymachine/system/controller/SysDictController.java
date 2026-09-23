package cn.studymachine.system.controller;

import cn.dev33.satoken.annotation.SaCheckPermission;
import cn.studymachine.common.web.Result;
import cn.studymachine.system.api.DictQueryFacade;
import cn.studymachine.system.api.dto.DictValueDTO;
import cn.studymachine.system.api.dto.ListDictValuesReqDTO;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 字典查询接口（权限点演示 + 闭环验证）。
 *
 * <p>统一 POST + 动词开头 camelCase 路径，参数走请求体（架构规范 §6）。</p>
 */
@RestController
@RequestMapping("/dict")
@RequiredArgsConstructor(onConstructor = @__(@Autowired))
public class SysDictController {

    private final DictQueryFacade dictQueryFacade;

    /**
     * 按字典键查询字典值列表。
     */
    @SaCheckPermission("sys:dict:list")
    @PostMapping("/listDictValues")
    public Result<List<DictValueDTO>> listDictValues(@Valid @RequestBody ListDictValuesReqDTO req) {
        return Result.ok(dictQueryFacade.listDictValues(req.getDictKey()));
    }
}
