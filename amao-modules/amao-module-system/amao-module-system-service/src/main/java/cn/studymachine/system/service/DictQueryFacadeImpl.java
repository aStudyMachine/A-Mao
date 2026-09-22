package cn.studymachine.system.service;

import cn.studymachine.system.api.DictQueryFacade;
import cn.studymachine.system.api.dto.DictValueDTO;
import cn.studymachine.system.mapper.SysDictValueMapper;
import cn.studymachine.system.model.SysDictValueModel;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Local adapter for {@link DictQueryFacade}.
 */
@Service
public class DictQueryFacadeImpl implements DictQueryFacade {

    private final SysDictValueMapper sysDictValueMapper;

    public DictQueryFacadeImpl(SysDictValueMapper sysDictValueMapper) {
        this.sysDictValueMapper = sysDictValueMapper;
    }

    @Override
    public List<DictValueDTO> listByDictKey(String dictKey) {
        List<SysDictValueModel> models = sysDictValueMapper.selectList(
                new LambdaQueryWrapper<SysDictValueModel>().eq(SysDictValueModel::getDictKey, dictKey));
        return models.stream().map(m -> {
            DictValueDTO dto = new DictValueDTO();
            dto.setId(m.getId());
            dto.setDictKey(m.getDictKey());
            dto.setValue(m.getValue());
            return dto;
        }).collect(Collectors.toList());
    }
}