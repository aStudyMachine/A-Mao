package cn.studymachine.system.service;

import cn.studymachine.system.api.DictQueryFacade;
import cn.studymachine.system.api.dto.DictValueDTO;
import cn.studymachine.system.mapper.SysDictValueMapper;
import cn.studymachine.system.model.SysDictValueModel;
import cn.studymachine.system.service.converter.DictValueConverter;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.List;

/**
 * {@link DictQueryFacade} 本地适配器。
 */
@Service
@RequiredArgsConstructor(onConstructor = @__(@Autowired))
public class DictQueryFacadeImpl implements DictQueryFacade {

    private final SysDictValueMapper sysDictValueMapper;
    private final DictValueConverter dictValueConverter;

    @Override
    public List<DictValueDTO> listDictValues(String dictKey) {
        if (dictKey == null || dictKey.isBlank()) {
            return Collections.emptyList();
        }
        List<SysDictValueModel> models = sysDictValueMapper.selectList(
                new LambdaQueryWrapper<SysDictValueModel>().eq(SysDictValueModel::getDictKey, dictKey));
        return dictValueConverter.toDTOList(models);
    }
}
