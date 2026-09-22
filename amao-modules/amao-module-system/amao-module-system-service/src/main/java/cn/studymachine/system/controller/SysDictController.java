package cn.studymachine.system.controller;

import cn.dev33.satoken.annotation.SaCheckPermission;
import cn.studymachine.common.web.Result;
import cn.studymachine.system.api.DictQueryFacade;
import cn.studymachine.system.api.dto.DictValueDTO;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 字典查询接口（权限点演示 + 闭环验证）。
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
    @GetMapping("/{dictKey}")
    public Result<List<DictValueDTO>> listByDictKey(@PathVariable("dictKey") String dictKey) {
        return Result.ok(dictQueryFacade.listByDictKey(dictKey));
    }
}
